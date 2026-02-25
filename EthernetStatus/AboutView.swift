import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            
            Image(systemName: "network")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("Ethernet Status")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Version 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("An open source menu bar app for monitoring Ethernet connections and network interfaces on macOS.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Divider()
            
            VStack(spacing: 8) {
                Link("GitHub Repository", destination: URL(string: "https://github.com/yourusername/EthernetStatus")!)
                Link("Report an Issue", destination: URL(string: "https://github.com/yourusername/EthernetStatus/issues")!)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 350)
    }
}