import SwiftUI

struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("refreshInterval") private var refreshInterval = 30
    @AppStorage("showPublicIP") private var showPublicIP = true
    @AppStorage("startHidden") private var startHidden = false
    
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
                Toggle("Show Public IP Address", isOn: $showPublicIP)
                
                Toggle("Start Hidden (No Dock Icon)", isOn: $startHidden)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Refresh Interval: \(refreshInterval) seconds")
                    Slider(value: .init(
                        get: { Double(refreshInterval) },
                        set: { refreshInterval = Int($0) }
                    ), in: 10...300, step: 10)
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 250)
    }
}