import AppKit
import SwiftUI

private enum PopoverStyle {
    static let panelWidth: CGFloat = 280
    static let horizontalPadding: CGFloat = 16
    static let rowVerticalPadding: CGFloat = 6
    static let sectionGap: CGFloat = 8
    static let titleFont = Font.system(size: 13, weight: .medium)
    static let bodyFont = Font.system(size: 13)
    static let monoBodyFont = Font.system(size: 13, design: .monospaced)
    static let monoCaptionFont = Font.system(size: 11, design: .monospaced)
    static let captionFont = Font.system(size: 12, weight: .medium)
    static let feedbackFont = Font.system(size: 11, weight: .medium)
}

struct ContentView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @EnvironmentObject var updateCoordinator: UpdateCoordinator
    @State private var showingPreferences = false

    var body: some View {
        VStack(spacing: 0) {
            ConnectionStatusView()
                .padding(.top, 16)

            Divider()
                .padding(.vertical, PopoverStyle.sectionGap)

            InterfacesSection()

            Divider()
                .padding(.vertical, PopoverStyle.sectionGap)

            MenuItemsView(showingPreferences: $showingPreferences)
                .padding(.bottom, 8)
        }
        .frame(width: PopoverStyle.panelWidth)
        .environmentObject(appDelegate.networkMonitor)
        .sheet(isPresented: $showingPreferences) {
            PreferencesView()
                .environmentObject(appDelegate)
                .environmentObject(appDelegate.settings)
                .environmentObject(updateCoordinator)
        }
        .alert(
            LocalizationCatalog.localized("update.available.title"),
            isPresented: Binding(
                get: { updateCoordinator.updatePromptRelease != nil },
                set: { if !$0 { updateCoordinator.dismissUpdatePrompt() } }
            ),
            presenting: updateCoordinator.updatePromptRelease
        ) { release in
            Button(LocalizationCatalog.localized("common.later"), role: .cancel) {
                updateCoordinator.dismissUpdatePrompt()
            }
            Button(LocalizationCatalog.localized("update.available.download")) {
                NSWorkspace.shared.open(release.downloadURL)
                updateCoordinator.dismissUpdatePrompt()
            }
        } message: { release in
            Text(String(
                format: LocalizationCatalog.localized("update.available.message"),
                release.version,
                release.notes.isEmpty ? LocalizationCatalog.localized("update.available.no_notes") : release.notes
            ))
        }
    }
}

struct ConnectionStatusView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @EnvironmentObject var settings: AppSettings
    @State private var didCopyPublicIP = false

    private var speedSummaryText: String {
        let download = NetworkSpeedFormatter.string(bytesPerSecond: networkMonitor.downloadSpeedBytesPerSecond)
        let upload = NetworkSpeedFormatter.string(bytesPerSecond: networkMonitor.uploadSpeedBytesPerSecond)
        return String(format: LocalizationCatalog.localized("speed.summary"), download, upload)
    }

    private var statusText: String {
        switch networkMonitor.connectionState {
        case .active:
            LocalizationCatalog.localized("status.connected_active")
        case .inactive:
            LocalizationCatalog.localized("status.connected_inactive")
        case .disconnected:
            LocalizationCatalog.localized("status.disconnected")
        }
    }

    private var statusColor: Color {
        switch networkMonitor.connectionState {
        case .active:
            .green
        case .inactive:
            .orange
        case .disconnected:
            .red
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(LocalizationCatalog.localized("wired.status.label"))
                    .font(PopoverStyle.titleFont)
                Text(statusText)
                    .font(PopoverStyle.bodyFont)
                    .foregroundColor(statusColor)
                Spacer()
            }
            .padding(.horizontal, PopoverStyle.horizontalPadding)

            HStack {
                Text(LocalizationCatalog.localized("speed.label"))
                    .font(PopoverStyle.titleFont)
                Text(speedSummaryText)
                    .font(PopoverStyle.monoBodyFont)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, PopoverStyle.horizontalPadding)

            if settings.showPublicIP {
                HStack {
                    Text(LocalizationCatalog.localized("public_ip.label"))
                        .font(PopoverStyle.titleFont)
                    if let publicIP = networkMonitor.publicIP {
                        Button {
                            copyToClipboard(publicIP)
                            didCopyPublicIP = true

                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                didCopyPublicIP = false
                            }
                        } label: {
                            Text(publicIP)
                                .font(PopoverStyle.monoBodyFont)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                        .help(LocalizationCatalog.localized("public_ip.copy_help"))

                        if didCopyPublicIP {
                            Text(LocalizationCatalog.localized("public_ip.copied"))
                                .font(PopoverStyle.feedbackFont)
                                .foregroundColor(.green)
                        }
                    } else {
                        Text(LocalizationCatalog.localized("common.loading"))
                            .font(PopoverStyle.monoBodyFont)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, PopoverStyle.horizontalPadding)
            }
        }
    }
}

struct InterfacesSection: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizationCatalog.localized("interfaces.title"))
                .font(PopoverStyle.captionFont)
                .foregroundColor(.secondary)
                .padding(.horizontal, PopoverStyle.horizontalPadding)
                .padding(.bottom, 4)

            ForEach(networkMonitor.interfaces) { interface in
                InterfaceRow(interface: interface)
            }
        }
    }
}

struct InterfaceRow: View {
    let interface: NetworkInterface
    @State private var showingDetails = false

    var body: some View {
        Button(action: {
            showingDetails = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(interface.type) (\(interface.name))")
                        .font(PopoverStyle.bodyFont)
                    Text(String(format: LocalizationCatalog.localized("interface.mac"), interface.hardwareAddress ?? LocalizationCatalog.localized("common.unavailable")))
                        .font(PopoverStyle.monoCaptionFont)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, PopoverStyle.horizontalPadding)
            .padding(.vertical, PopoverStyle.rowVerticalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetails) {
            InterfaceDetailView(interface: interface)
        }
    }
}

private func copyToClipboard(_ value: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(value, forType: .string)
}

struct MenuItemsView: View {
    @Binding var showingPreferences: Bool
    @EnvironmentObject var appDelegate: AppDelegate

    private func trayMenuButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(PopoverStyle.bodyFont)
                Spacer()
            }
            .padding(.horizontal, PopoverStyle.horizontalPadding)
            .padding(.vertical, PopoverStyle.rowVerticalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var quickActionsMenu: some View {
        Menu {
            Button(LocalizationCatalog.localized("menu.refresh_wifi")) {
                appDelegate.refreshWiFi()
            }

            Button(LocalizationCatalog.localized("menu.flush_dns")) {
                appDelegate.flushDNSCache()
            }
        } label: {
            HStack {
                Text(LocalizationCatalog.localized("menu.quick_actions"))
                    .font(PopoverStyle.bodyFont)
                Spacer()
            }
            .padding(.horizontal, PopoverStyle.horizontalPadding)
            .padding(.vertical, PopoverStyle.rowVerticalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            quickActionsMenu

            trayMenuButton(LocalizationCatalog.localized("menu.preferences")) {
                showingPreferences = true
            }

            trayMenuButton(LocalizationCatalog.localized("menu.quit")) {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
