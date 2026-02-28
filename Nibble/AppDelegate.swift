import SwiftUI
import Network
import SystemConfiguration
import Combine
import UniformTypeIdentifiers

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusBarItem: NSStatusItem!
    var popover: NSPopover!
    let settings: AppSettings
    let loginItemController: LoginItemController
    let updateCoordinator: UpdateCoordinator
    @Published var networkMonitor: NetworkMonitor
    private let dnsFlushService: DNSFlushService
    private let wiFiRefreshService: WiFiRefreshService
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        self.settings = AppSettings()
        self.loginItemController = LoginItemController()
        self.updateCoordinator = UpdateCoordinator()
        self.networkMonitor = NetworkMonitor(settings: settings)
        self.dnsFlushService = DNSFlushService()
        self.wiFiRefreshService = WiFiRefreshService()
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status bar item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem.button {
            updateMenuBarButton(button, for: networkMonitor.connectionState)
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ContentView()
                .environmentObject(self)
                .environmentObject(settings)
                .environmentObject(updateCoordinator)
        )
        
        // Setup network monitoring
        networkMonitor.startMonitoring()

        // Apply initial app visibility mode
        applyActivationPolicy(appMode: settings.appMode)

        settings.$appMode
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] appMode in
                self?.applyActivationPolicy(appMode: appMode)
            }
            .store(in: &cancellables)
         
        // Update menu bar icon based on connection status
        updateMenuBarIcon()

        Timer.publish(every: 6 * 60 * 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                Task { await self.updateCoordinator.checkForUpdatesPeriodicallyIfNeeded() }
            }
            .store(in: &cancellables)

        Task {
            await updateCoordinator.checkForUpdatesPeriodicallyIfNeeded()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        networkMonitor.stopMonitoring()
        cancellables.removeAll()
    }
    
    @objc func togglePopover() {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
    func updateMenuBarIcon() {
        networkMonitor.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connectionState in
                if let button = self?.statusBarItem.button {
                    self?.updateMenuBarButton(button, for: connectionState)
                }
            }
            .store(in: &cancellables)
    }

    private func updateMenuBarButton(_ button: NSStatusBarButton, for state: EthernetConnectionState) {
        let descriptor = MenuBarIconDescriptor.forConnectionState(state)
        if let image = NSImage(
            systemSymbolName: descriptor.systemSymbolName,
            accessibilityDescription: descriptor.accessibilityDescription
        ) {
            image.isTemplate = true
            button.image = image
            button.title = ""
            button.imagePosition = .imageOnly
        } else {
            button.image = nil
            button.title = "Nibble"
            button.imagePosition = .noImage
            button.toolTip = descriptor.accessibilityDescription
        }
    }

    private func applyActivationPolicy(appMode: AppSettings.AppMode) {
        let policy: NSApplication.ActivationPolicy = appMode == .menuBarOnly ? .accessory : .regular
        NSApplication.shared.setActivationPolicy(policy)

        if appMode == .menuBarAndDock {
            NSApplication.shared.activate(ignoringOtherApps: false)
        }
    }

    func checkForUpdatesManually() {
        Task {
            await updateCoordinator.checkForUpdatesManually()
        }
    }

    func exportDiagnosticsReport() {
        let includeSensitive = diagnosticsExportSensitivitySelection()
        guard let includeSensitive else {
            return
        }

        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "nibble-diagnostics-\(Self.timestampForFilename()).json"

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let data = try DiagnosticsExportBuilder.makeJSONData(
                appVersion: Self.appVersionString(),
                macOSVersion: ProcessInfo.processInfo.operatingSystemVersionString,
                connectionState: networkMonitor.connectionState,
                interfaces: networkMonitor.interfaces,
                publicIP: networkMonitor.publicIP,
                includeSensitiveIdentifiers: includeSensitive
            )
            try data.write(to: url, options: .atomic)
            showDiagnosticsExportResultAlert(message: String(format: LocalizationCatalog.localized("diagnostics.export.success"), url.lastPathComponent))
        } catch {
            showDiagnosticsExportResultAlert(message: String(format: LocalizationCatalog.localized("diagnostics.export.failure"), error.localizedDescription))
        }
    }

    func flushDNSCache() {
        let result = dnsFlushService.flushDNSCache()
        showUtilityResultAlert(
            title: LocalizationCatalog.localized("utility.dns.flush.title"),
            message: result.message
        )
    }

    func refreshWiFiWithConfirmation() {
        let confirmationAlert = NSAlert()
        confirmationAlert.messageText = LocalizationCatalog.localized("utility.wifi.refresh.confirm.title")
        confirmationAlert.informativeText = LocalizationCatalog.localized("utility.wifi.refresh.confirm.message")
        confirmationAlert.addButton(withTitle: LocalizationCatalog.localized("utility.wifi.refresh.confirm.action"))
        confirmationAlert.addButton(withTitle: LocalizationCatalog.localized("common.cancel"))

        guard confirmationAlert.runModal() == .alertFirstButtonReturn else {
            return
        }

        switch wiFiRefreshService.refreshWiFi() {
        case .success:
            showUtilityResultAlert(
                title: LocalizationCatalog.localized("utility.wifi.refresh.title"),
                message: LocalizationCatalog.localized("utility.wifi.refresh.success")
            )
        case .cooldown(let remainingSeconds):
            showUtilityResultAlert(
                title: LocalizationCatalog.localized("utility.wifi.refresh.title"),
                message: String(format: LocalizationCatalog.localized("utility.wifi.refresh.cooldown"), remainingSeconds)
            )
        case .failure:
            showUtilityResultAlert(
                title: LocalizationCatalog.localized("utility.wifi.refresh.title"),
                message: LocalizationCatalog.localized("utility.wifi.refresh.failure")
            )
        }
    }

    func makeFeedbackComposer() -> FeedbackComposer {
        FeedbackComposer(
            diagnosticsProvider: { [self] in
                FeedbackDiagnosticsContext(
                    appVersion: Self.appVersionString(),
                    macOSVersion: ProcessInfo.processInfo.operatingSystemVersionString,
                    connectionState: networkMonitor.connectionState,
                    interfaces: networkMonitor.interfaces,
                    publicIP: networkMonitor.publicIP
                )
            }
        )
    }

    private func diagnosticsExportSensitivitySelection() -> Bool? {
        let alert = NSAlert()
        alert.messageText = LocalizationCatalog.localized("diagnostics.export.title")
        alert.informativeText = LocalizationCatalog.localized("diagnostics.export.prompt")
        alert.addButton(withTitle: LocalizationCatalog.localized("diagnostics.export.sanitized"))
        alert.addButton(withTitle: LocalizationCatalog.localized("diagnostics.export.include_sensitive"))
        alert.addButton(withTitle: LocalizationCatalog.localized("common.cancel"))

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            return false
        }

        if response == .alertSecondButtonReturn {
            return true
        }

        return nil
    }

    private func showDiagnosticsExportResultAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = LocalizationCatalog.localized("diagnostics.export.title")
        alert.informativeText = message
        alert.addButton(withTitle: LocalizationCatalog.localized("common.ok"))
        alert.runModal()
    }

    private func showUtilityResultAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: LocalizationCatalog.localized("common.ok"))
        alert.runModal()
    }

    private static func appVersionString() -> String {
        if let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           !shortVersion.isEmpty {
            return shortVersion
        }

        return "1.0.0"
    }

    private static func timestampForFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}
