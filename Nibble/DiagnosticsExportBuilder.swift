import Foundation

struct DiagnosticsExportReport: Codable, Equatable {
    let generatedAt: Date
    let appVersion: String
    let macOSVersion: String
    let connectionState: String
    let publicIP: String?
    let interfaces: [DiagnosticsExportInterface]
}

struct DiagnosticsExportInterface: Codable, Equatable {
    let name: String
    let displayName: String
    let type: String
    let medium: String
    let routeRole: String
    let classificationConfidence: String
    let isActive: Bool
    let adapterDescription: String?
    let addresses: [String]?
    let hardwareAddress: String?
}

enum DiagnosticsExportBuilder {
    static func makeReport(
        appVersion: String,
        macOSVersion: String,
        connectionState: EthernetConnectionState,
        interfaces: [NetworkInterface],
        publicIP: String?,
        includeSensitiveIdentifiers: Bool,
        generatedAt: Date = Date()
    ) -> DiagnosticsExportReport {
        DiagnosticsExportReport(
            generatedAt: generatedAt,
            appVersion: appVersion,
            macOSVersion: macOSVersion,
            connectionState: connectionState.diagnosticsValue,
            publicIP: includeSensitiveIdentifiers ? publicIP : nil,
            interfaces: interfaces.map {
                DiagnosticsExportInterface(
                    name: $0.name,
                    displayName: $0.displayName,
                    type: $0.type,
                    medium: $0.medium.diagnosticsValue,
                    routeRole: $0.routeRole.diagnosticsValue,
                    classificationConfidence: $0.classificationConfidence.diagnosticsValue,
                    isActive: $0.isActive,
                    adapterDescription: $0.adapterDescription,
                    addresses: includeSensitiveIdentifiers ? $0.addresses : nil,
                    hardwareAddress: includeSensitiveIdentifiers ? $0.hardwareAddress : nil
                )
            }
        )
    }

    static func makeJSONData(
        appVersion: String,
        macOSVersion: String,
        connectionState: EthernetConnectionState,
        interfaces: [NetworkInterface],
        publicIP: String?,
        includeSensitiveIdentifiers: Bool,
        generatedAt: Date = Date()
    ) throws -> Data {
        let report = makeReport(
            appVersion: appVersion,
            macOSVersion: macOSVersion,
            connectionState: connectionState,
            interfaces: interfaces,
            publicIP: publicIP,
            includeSensitiveIdentifiers: includeSensitiveIdentifiers,
            generatedAt: generatedAt
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(report)
    }
}

private extension EthernetConnectionState {
    var diagnosticsValue: String {
        switch self {
        case .active:
            return "active"
        case .inactive:
            return "inactive"
        case .disconnected:
            return "disconnected"
        }
    }
}

private extension InterfaceMedium {
    var diagnosticsValue: String {
        switch self {
        case .wired:
            return "wired"
        case .wiFi:
            return "wifi"
        case .vpn:
            return "vpn"
        case .bridge:
            return "bridge"
        case .loopback:
            return "loopback"
        case .awdl:
            return "awdl"
        case .bluetooth:
            return "bluetooth"
        case .unknown:
            return "unknown"
        }
    }
}

private extension InterfaceRouteRole {
    var diagnosticsValue: String {
        switch self {
        case .none:
            return "none"
        case .defaultRoute:
            return "defaultRoute"
        }
    }
}

private extension InterfaceClassificationConfidence {
    var diagnosticsValue: String {
        switch self {
        case .high:
            return "high"
        case .low:
            return "low"
        }
    }
}
