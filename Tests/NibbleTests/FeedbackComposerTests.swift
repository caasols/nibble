import Foundation
import Testing
@testable import Nibble

@MainActor
struct FeedbackComposerTests {
    @Test func diagnosticsPreviewIsNilUntilConsentIsEnabled() {
        let composer = FeedbackComposer(
            diagnosticsProvider: { sampleContext }
        )

        #expect(composer.diagnosticsPreview == nil)

        composer.includeDiagnostics = true

        #expect(composer.diagnosticsPreview != nil)
    }

    @Test func diagnosticsPreviewExcludesSensitiveIdentifiersByDefault() {
        let composer = FeedbackComposer(
            diagnosticsProvider: { sampleContext }
        )

        composer.includeDiagnostics = true

        #expect(composer.diagnosticsPreview?.contains("203.0.113.10") == false)
        #expect(composer.diagnosticsPreview?.contains("AA:BB:CC:DD:EE:FF") == false)
    }

    @Test func diagnosticsPreviewIncludesSensitiveIdentifiersWhenExplicitlyEnabled() {
        let composer = FeedbackComposer(
            diagnosticsProvider: { sampleContext }
        )

        composer.includeDiagnostics = true
        composer.includeSensitiveIdentifiers = true

        #expect(composer.diagnosticsPreview?.contains("203.0.113.10") == true)
        #expect(composer.diagnosticsPreview?.contains("AA:BB:CC:DD:EE:FF") == true)
    }

    @Test func submissionURLContainsFeedbackBodyAndOptionalDiagnostics() {
        let composer = FeedbackComposer(
            diagnosticsProvider: { sampleContext },
            baseURL: URL(string: "https://example.com/issues/new")!
        )
        composer.category = .feature
        composer.subject = "Need shortcut"
        composer.message = "Please add a global shortcut toggle."
        composer.contact = "user@example.com"

        let withoutDiagnostics = composer.submissionURL()
        #expect(withoutDiagnostics?.absoluteString.contains("global%20shortcut") == true)
        #expect(withoutDiagnostics?.absoluteString.contains("appVersion") == false)

        composer.includeDiagnostics = true
        let withDiagnostics = composer.submissionURL()
        #expect(withDiagnostics?.absoluteString.contains("appVersion") == true)
    }
}

private let sampleContext = FeedbackDiagnosticsContext(
    appVersion: "1.2.3",
    macOSVersion: "macOS 14.5",
    connectionState: .active,
    interfaces: [
        NetworkInterface(
            name: "en5",
            displayName: "USB-C LAN",
            hardwareAddress: "AA:BB:CC:DD:EE:FF",
            isActive: true,
            addresses: ["192.168.1.20"],
            type: "Ethernet",
            medium: .wired,
            classificationConfidence: .high,
            routeRole: .defaultRoute,
            adapterDescription: "Dock"
        )
    ],
    publicIP: "203.0.113.10"
)
