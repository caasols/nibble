import Foundation
import Testing
@testable import Nibble

struct DiagnosticsExportBuilderTests {
    @Test func sanitizedExportExcludesSensitiveIdentifiersByDefault() throws {
        let report = DiagnosticsExportBuilder.makeReport(
            appVersion: "1.2.3",
            macOSVersion: "macOS 14.5",
            connectionState: .inactive,
            interfaces: [
                NetworkInterface(
                    name: "en5",
                    displayName: "USB-C LAN",
                    hardwareAddress: "AA:BB:CC:DD:EE:FF",
                    isActive: true,
                    addresses: ["192.168.1.10", "fe80::1"],
                    type: "Ethernet",
                    medium: .wired,
                    classificationConfidence: .high,
                    routeRole: .defaultRoute,
                    adapterDescription: "Dock Ethernet"
                )
            ],
            publicIP: "198.51.100.10",
            includeSensitiveIdentifiers: false,
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        #expect(report.publicIP == nil)
        #expect(report.interfaces.first?.hardwareAddress == nil)
        #expect(report.interfaces.first?.addresses == nil)
        #expect(report.connectionState == "inactive")
        #expect(report.appVersion == "1.2.3")
        #expect(report.macOSVersion == "macOS 14.5")
    }

    @Test func sensitiveExportIncludesPublicIPAndHardwareIdentifiers() throws {
        let report = DiagnosticsExportBuilder.makeReport(
            appVersion: "1.2.3",
            macOSVersion: "macOS 14.5",
            connectionState: .active,
            interfaces: [
                NetworkInterface(
                    name: "en0",
                    displayName: "Ethernet",
                    hardwareAddress: "11:22:33:44:55:66",
                    isActive: true,
                    addresses: ["10.0.0.4"],
                    type: "Ethernet",
                    medium: .wired,
                    classificationConfidence: .high,
                    routeRole: .defaultRoute,
                    adapterDescription: nil
                )
            ],
            publicIP: "203.0.113.99",
            includeSensitiveIdentifiers: true,
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        #expect(report.publicIP == "203.0.113.99")
        #expect(report.interfaces.first?.hardwareAddress == "11:22:33:44:55:66")
        #expect(report.interfaces.first?.addresses == ["10.0.0.4"])
    }
}
