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
            
            if settings.showPublicIP {
                HStack {
                        Text(LocalizationCatalog.localized("public_ip.label"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    if let publicIP = networkMonitor.publicIP {
                        Text(publicIP)
                            .font(.system(size: 13, design: .monospaced))
                            .textSelection(.enabled)
                            .contextMenu {
                                Button(LocalizationCatalog.localized("common.copy")) {
                                    copyToClipboard(publicIP)
                                }
                            }
                        Button(LocalizationCatalog.localized("common.copy")) {
                            copyToClipboard(publicIP)
                        }
                        .buttonStyle(.borderless)
                        .help(LocalizationCatalog.localized("public_ip.copy_help"))
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

    private var openAtLoginBinding: Binding<Bool> {
        Binding(
            get: { appDelegate.loginItemController.isOpenAtLogin },
            set: { appDelegate.loginItemController.setOpenAtLogin($0) }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(LocalizationCatalog.localized("menu.open_at_login"), isOn: openAtLoginBinding)
                .font(.system(size: 13))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .onAppear {
                    appDelegate.loginItemController.refreshFromSystem()
                }

            if let message = appDelegate.loginItemController.lastErrorMessage {
                Text(message)
                    .font(.system(size: 11))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
            }
            
            Button(action: {
                showingPreferences = true
            }) {
                HStack {
                    Text(LocalizationCatalog.localized("menu.preferences"))
                        .font(.system(size: 13))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                appDelegate.flushDNSCache()
            }) {
                HStack {
                    Text(LocalizationCatalog.localized("menu.flush_dns"))
                        .font(.system(size: 13))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                appDelegate.refreshWiFi()
            }) {
                HStack {
                    Text(LocalizationCatalog.localized("menu.refresh_wifi"))
                        .font(.system(size: 13))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            Divider()
                .padding(.vertical, 8)
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Text(LocalizationCatalog.localized("menu.quit"))
                        .font(.system(size: 13))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
