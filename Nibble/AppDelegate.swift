import SwiftUI
import Network
import SystemConfiguration
import Combine

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    var statusBarItem: NSStatusItem!
    var popover: NSPopover!
    let settings: AppSettings
    let loginItemController: LoginItemController
    let updateCoordinator: UpdateCoordinator
    @Published var networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        self.settings = AppSettings()
        self.loginItemController = LoginItemController()
        self.updateCoordinator = UpdateCoordinator()
        self.networkMonitor = NetworkMonitor(settings: settings)
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
}
