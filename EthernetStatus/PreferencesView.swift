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
                
                Toggle("Start Hidden (No Dock Icon)", isOn: $settings.startHidden)
                
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
