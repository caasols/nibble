import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @EnvironmentObject var updateCoordinator: UpdateCoordinator
    @State private var showingAbout = false
    @State private var showingFeedbackForm = false
    
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
            MenuItemsView(showingAbout: $showingAbout, showingFeedbackForm: $showingFeedbackForm)
                .padding(.bottom, 8)
        }
        .frame(width: 280)
        .environmentObject(appDelegate.networkMonitor)
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingFeedbackForm) {
            FeedbackFormView(composer: appDelegate.makeFeedbackComposer())
        }
        .alert(
            "Update Available",
            isPresented: Binding(
                get: { updateCoordinator.updatePromptRelease != nil },
                set: { if !$0 { updateCoordinator.dismissUpdatePrompt() } }
            ),
            presenting: updateCoordinator.updatePromptRelease
        ) { release in
            Button("Later", role: .cancel) {
                updateCoordinator.dismissUpdatePrompt()
            }
            Button("Download") {
                NSWorkspace.shared.open(release.downloadURL)
                updateCoordinator.dismissUpdatePrompt()
            }
        } message: { release in
            Text("Version \(release.version) is available.\n\nRelease notes:\n\(release.notes.isEmpty ? "No notes provided." : release.notes)")
        }
    }
}

struct ConnectionStatusView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @EnvironmentObject var settings: AppSettings

    private var statusText: String {
        switch networkMonitor.connectionState {
        case .active:
            return "Connected (Active)"
        case .inactive:
            return "Connected (Inactive)"
        case .disconnected:
            return "Disconnected"
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
                Text("Wired Status:")
                    .font(.system(size: 13, weight: .medium))
                Text(statusText)
                    .font(.system(size: 13))
                    .foregroundColor(statusColor)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            if settings.showPublicIP {
                HStack {
                    Text("Public IP Address:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    if let publicIP = networkMonitor.publicIP {
                        Text(publicIP)
                            .font(.system(size: 13, design: .monospaced))
                            .textSelection(.enabled)
                            .contextMenu {
                                Button("Copy") {
                                    copyToClipboard(publicIP)
                                }
                            }
                        Button("Copy") {
                            copyToClipboard(publicIP)
                        }
                        .buttonStyle(.borderless)
                        .help("Copy public IP")
                    } else {
                        Text("Loading...")
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
            Text("Interfaces")
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
                    Text("MAC: \(interface.hardwareAddress ?? "Unavailable")")
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
    @Binding var showingAbout: Bool
    @Binding var showingFeedbackForm: Bool
    @EnvironmentObject var appDelegate: AppDelegate

    private var openAtLoginBinding: Binding<Bool> {
        Binding(
            get: { appDelegate.loginItemController.isOpenAtLogin },
            set: { appDelegate.loginItemController.setOpenAtLogin($0) }
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle("Open at Login", isOn: openAtLoginBinding)
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
                let didOpenSettings = NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                if !didOpenSettings {
                    _ = NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
                }
            }) {
                HStack {
                    Text("Preferences...")
                        .font(.system(size: 13))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                appDelegate.checkForUpdatesManually()
            }) {
                HStack {
                    Text("Check for Updates...")
                        .font(.system(size: 13))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                appDelegate.exportDiagnosticsReport()
            }) {
                HStack {
                    Text("Export Diagnostics...")
                        .font(.system(size: 13))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                showingFeedbackForm = true
            }) {
                HStack {
                    Text("Send Feedback...")
                        .font(.system(size: 13))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                showingAbout = true
            }) {
                HStack {
                    Text("About Nibble")
                        .font(.system(size: 13))
                    Spacer()
                    Text("v1.0.0")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
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
                    Text("Quit")
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
