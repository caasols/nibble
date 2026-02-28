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

    @Test func submissionPayloadContainsFeedbackAndOptionalDiagnostics() {
        let composer = FeedbackComposer(
            diagnosticsProvider: { sampleContext },
            issueCreationURL: URL(string: "https://example.com/issues/new")!
        )
        composer.category = .feature
        composer.subject = "Need shortcut"
        composer.message = "Please add a global shortcut toggle."
        composer.contact = "user@example.com"

        let withoutDiagnostics = composer.submissionPayload()
        #expect(withoutDiagnostics?.destinationURL.absoluteString == "https://example.com/issues/new")
        #expect(withoutDiagnostics?.subject == "[Feature Request] Need shortcut")
        #expect(withoutDiagnostics?.body.contains("global shortcut") == true)
        #expect(withoutDiagnostics?.body.contains("appVersion") == false)

        composer.includeDiagnostics = true
        let withDiagnostics = composer.submissionPayload()
        #expect(withDiagnostics?.body.contains("appVersion") == true)
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
