import SwiftUI

struct InterfaceDetailView: View {
    let interface: NetworkInterface
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Interface Details")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: "Name", value: interface.name)
                    DetailRow(label: "Display Name", value: interface.displayName)
                    DetailRow(label: "Hardware Address", value: interface.hardwareAddress ?? "N/A")
                    DetailRow(label: "Status", value: interface.isActive ? "Active" : "Inactive")
                    
                    if !interface.addresses.isEmpty {
                        Text("IP Addresses")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        
                        ForEach(interface.addresses, id: \.self) { address in
                            Text(address)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 350, height: 300)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
        }
    }
}