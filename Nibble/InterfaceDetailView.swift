import SwiftUI
import AppKit

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
                    DetailRow(label: "Adapter", value: interface.adapterDescription ?? "Unknown")
                    DetailRow(label: "Route Role", value: interface.routeRole.displayName)
                    DetailRow(label: "Interface Media", value: interface.type)
                    CopyableDetailRow(label: "MAC Address", value: interface.hardwareAddress ?? "Unavailable")
                    DetailRow(label: "Status", value: interface.isActive ? "Active" : "Inactive")
                    
                    if !interface.addresses.isEmpty {
                        Text("IP Addresses")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        
                        ForEach(interface.addresses, id: \.self) { address in
                            CopyableValueRow(value: address)
                        }
                    } else {
                        DetailRow(label: "IP Addresses", value: "Unavailable")
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

struct CopyableDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text(value)
                    .font(.body)
                    .lineLimit(1)
                Spacer()
                Button("Copy") {
                    copyToClipboard(value)
                }
                .buttonStyle(.borderless)
                .help("Copy value")
            }
        }
    }
}

struct CopyableValueRow: View {
    let value: String

    var body: some View {
        HStack {
            Text(value)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
                .textSelection(.enabled)
                .contextMenu {
                    Button("Copy") {
                        copyToClipboard(value)
                    }
                }
            Spacer()
            Button("Copy") {
                copyToClipboard(value)
            }
            .buttonStyle(.borderless)
            .help("Copy address")
        }
    }
}

private func copyToClipboard(_ value: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(value, forType: .string)
}
