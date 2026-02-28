import SwiftUI

struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Preferences")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Show Public IP Address", isOn: $settings.showPublicIP)

                    Text(settings.publicIPTransparencySummary)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Provider: \(settings.publicIPProviderHost) over HTTPS. Public IP display is optional and can be changed anytime.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("App Mode")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("App Mode", selection: $settings.appMode) {
                        Text("Menubar + Dock").tag(AppSettings.AppMode.menuBarAndDock)
                        Text("Menubar Only").tag(AppSettings.AppMode.menuBarOnly)
                    }
                    .pickerStyle(.segmented)

                    Text(settings.appMode == .menuBarOnly
                         ? "Nibble runs as a menubar app and stays hidden from the Dock."
                         : "Nibble appears in the Dock and can be activated like a standard app.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Refresh Interval: \(settings.refreshInterval) seconds")
                    Slider(value: .init(
                        get: { Double(settings.refreshInterval) },
                        set: { settings.refreshInterval = Int($0) }
                    ), in: 10...300, step: 10)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Telemetry")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Toggle("Share anonymous telemetry", isOn: $settings.telemetryEnabled)

                    Text("Telemetry is opt-in and disabled by default. You can change this anytime.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Pending unsent telemetry events: \(settings.pendingTelemetryEventCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Erase Pending Telemetry Data") {
                        settings.erasePendingTelemetryData()
                    }
                    .disabled(settings.pendingTelemetryEventCount == 0)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 440, height: 300)
    }
}
