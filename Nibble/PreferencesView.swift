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
                Toggle("Show Public IP Address", isOn: $settings.showPublicIP)

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
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 250)
    }
}
