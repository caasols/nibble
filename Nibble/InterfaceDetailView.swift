import SwiftUI
import AppKit

struct InterfaceDetailView: View {
    let interface: NetworkInterface
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(LocalizationCatalog.localized("interface.details.title"))
                    .font(.headline)
                Spacer()
                Button(LocalizationCatalog.localized("common.done")) {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    DetailRow(label: LocalizationCatalog.localized("interface.details.name"), value: interface.name)
                    DetailRow(label: LocalizationCatalog.localized("interface.details.display_name"), value: interface.displayName)
                    DetailRow(label: LocalizationCatalog.localized("interface.details.adapter"), value: interface.adapterDescription ?? LocalizationCatalog.localized("common.unknown"))
                    DetailRow(label: LocalizationCatalog.localized("interface.details.route_role"), value: interface.routeRole.displayName)
                    DetailRow(label: LocalizationCatalog.localized("interface.details.media"), value: interface.type)
                    CopyableDetailRow(label: LocalizationCatalog.localized("interface.details.mac"), value: interface.hardwareAddress ?? LocalizationCatalog.localized("common.unavailable"))
                    DetailRow(label: LocalizationCatalog.localized("interface.details.status"), value: interface.isActive ? LocalizationCatalog.localized("status.active") : LocalizationCatalog.localized("status.inactive"))
                    
                    if !interface.addresses.isEmpty {
                        Text(LocalizationCatalog.localized("interface.details.ip_addresses"))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        
                        ForEach(interface.addresses, id: \.self) { address in
                            CopyableValueRow(value: address)
                        }
                    } else {
                        DetailRow(label: LocalizationCatalog.localized("interface.details.ip_addresses"), value: LocalizationCatalog.localized("common.unavailable"))
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
                Button(LocalizationCatalog.localized("common.copy")) {
                    copyToClipboard(value)
                }
                .buttonStyle(.borderless)
                .help(LocalizationCatalog.localized("common.copy_value"))
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
                    Button(LocalizationCatalog.localized("common.copy")) {
                        copyToClipboard(value)
                    }
                }
            Spacer()
            Button(LocalizationCatalog.localized("common.copy")) {
                copyToClipboard(value)
            }
            .buttonStyle(.borderless)
            .help(LocalizationCatalog.localized("common.copy_address"))
        }
    }
}

private func copyToClipboard(_ value: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(value, forType: .string)
}
