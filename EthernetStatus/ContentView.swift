import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appDelegate: AppDelegate
    @State private var showingAbout = false
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
            MenuItemsView(showingAbout: $showingAbout, showingPreferences: $showingPreferences)
                .padding(.bottom, 8)
        }
        .frame(width: 280)
        .environmentObject(appDelegate.networkMonitor)
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingPreferences) {
            PreferencesView()
        }
    }
}

struct ConnectionStatusView: View {
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @AppStorage("showPublicIP") private var showPublicIP = true
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Wired Connection:")
                    .font(.system(size: 13, weight: .medium))
                Text(networkMonitor.isEthernetConnected ? "Connected" : "Not Connected")
                    .font(.system(size: 13))
                    .foregroundColor(networkMonitor.isEthernetConnected ? .green : .red)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            if showPublicIP {
                HStack {
                    Text("Public IP Address:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(networkMonitor.publicIP ?? "Loading...")
                        .font(.system(size: 13, design: .monospaced))
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
                Text("\(interface.type) (\(interface.name))")
                    .font(.system(size: 13))
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

struct MenuItemsView: View {
    @Binding var showingAbout: Bool
    @Binding var showingPreferences: Bool
    @AppStorage("openAtLogin") private var openAtLogin = false
    @EnvironmentObject var appDelegate: AppDelegate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle("Open at Login", isOn: $openAtLogin)
                .font(.system(size: 13))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .onChange(of: openAtLogin) { newValue in
                    LoginItemManager.setOpenAtLogin(enabled: newValue)
                }
            
            Button(action: {
                showingPreferences = true
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
                showingAbout = true
            }) {
                HStack {
                    Text("About Ethernet Status")
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
