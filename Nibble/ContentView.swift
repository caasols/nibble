import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @EnvironmentObject var updateCoordinator: UpdateCoordinator
    @State private var showingPreferences = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ConnectionStatusView()
                .padding(.top, 16)
            
            Divider()
                .padding(.vertical, 8)
            
            // Interfaces Section
            InterfacesSection()
            
            Divider()
                .padding(.vertical, 8)
            
            // Menu Items
            MenuItemsView(showingPreferences: $showingPreferences)
                .padding(.bottom, 8)
        }
        .frame(width: 280)
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
            return LocalizationCatalog.localized("status.connected_active")
        case .inactive:
            return LocalizationCatalog.localized("status.connected_inactive")
        case .disconnected:
            return LocalizationCatalog.localized("status.disconnected")
        }
    }

    private var statusColor: Color {
        switch networkMonitor.connectionState {
        case .active:
            return .green
        case .inactive:
            return .orange
        case .disconnected:
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(LocalizationCatalog.localized("wired.status.label"))
                    .font(.system(size: 13, weight: .medium))
                Text(statusText)
                    .font(.system(size: 13))
                    .foregroundColor(statusColor)
                Spacer()
            }
            .padding(.horizontal, 16)

            HStack {
                Text(LocalizationCatalog.localized("speed.label"))
                    .font(.system(size: 13, weight: .medium))
                Text(speedSummaryText)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
             
            if settings.showPublicIP {
                HStack {
                    Text(LocalizationCatalog.localized("public_ip.label"))
                        .font(.system(size: 13, weight: .medium))
                    if let publicIP = networkMonitor.publicIP {
                        Button {
                            copyToClipboard(publicIP)
                            didCopyPublicIP = true

                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                didCopyPublicIP = false
                            }
                        } label: {
                            Text(publicIP)
                                .font(.system(size: 13, design: .monospaced))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)
                        .help(LocalizationCatalog.localized("public_ip.copy_help"))

                        if didCopyPublicIP {
                            Text(LocalizationCatalog.localized("public_ip.copied"))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.green)
                        }
                    } else {
                        Text(LocalizationCatalog.localized("common.loading"))
                            .font(.system(size: 13, design: .monospaced))
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct InterfacesSection: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizationCatalog.localized("interfaces.title"))
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
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
                        .font(.system(size: 13))
                    Text(String(format: LocalizationCatalog.localized("interface.mac"), interface.hardwareAddress ?? LocalizationCatalog.localized("common.unavailable")))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
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
    @State private var quickActionsExpanded = false

    private func trayMenuButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 13))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var quickActionsMenu: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.12)) {
                quickActionsExpanded.toggle()
            }
        } label: {
            HStack {
                Image(systemName: quickActionsExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)

                Text(LocalizationCatalog.localized("menu.quick_actions"))
                    .font(.system(size: 13))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .padding(.top, 8)

            quickActionsMenu

            if quickActionsExpanded {
                trayMenuButton(LocalizationCatalog.localized("menu.refresh_wifi")) {
                    appDelegate.refreshWiFi()
                }

                trayMenuButton(LocalizationCatalog.localized("menu.flush_dns")) {
                    appDelegate.flushDNSCache()
                }
            }

            Divider()

            trayMenuButton(LocalizationCatalog.localized("menu.preferences")) {
                showingPreferences = true
            }

            trayMenuButton(LocalizationCatalog.localized("menu.quit")) {
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
