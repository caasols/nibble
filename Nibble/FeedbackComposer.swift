import Foundation

struct FeedbackDiagnosticsContext {
    let appVersion: String
    let macOSVersion: String
    let connectionState: EthernetConnectionState
    let interfaces: [NetworkInterface]
    let publicIP: String?
}

enum FeedbackCategory: String, CaseIterable, Identifiable {
    case bug
    case feature
    case general

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .bug:
            "Bug"
        case .feature:
            "Feature Request"
        case .general:
            "General Feedback"
        }
    }
}

@MainActor
final class FeedbackComposer: ObservableObject {
    @Published var category: FeedbackCategory = .bug
    @Published var subject: String = ""
    @Published var message: String = ""
    @Published var contact: String = ""

    @Published var includeDiagnostics: Bool = false {
        didSet {
            if !includeDiagnostics {
                includeSensitiveIdentifiers = false
            }
            refreshDiagnosticsPreview()
        }
    }

    @Published var includeSensitiveIdentifiers: Bool = false {
        didSet {
            if includeDiagnostics {
                refreshDiagnosticsPreview()
            }
        }
    }

    @Published private(set) var diagnosticsPreview: String?

    private let diagnosticsProvider: () -> FeedbackDiagnosticsContext
    private let nowProvider: () -> Date
    private let issueCreationURL: URL

    init(
        diagnosticsProvider: @escaping () -> FeedbackDiagnosticsContext,
        nowProvider: @escaping () -> Date = Date.init,
        issueCreationURL: URL = URL(string: "https://github.com/caasols/nibble/issues/new")!
    ) {
        self.diagnosticsProvider = diagnosticsProvider
        self.nowProvider = nowProvider
        self.issueCreationURL = issueCreationURL
    }

    var canSubmit: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func submissionPayload() -> FeedbackSubmissionPayload? {
        guard canSubmit else {
            return nil
        }

        let normalizedSubject = "[\(category.title)] \(subject.trimmingCharacters(in: .whitespacesAndNewlines))"

        return FeedbackSubmissionPayload(
            subject: normalizedSubject,
            body: makeBodyText(subject: normalizedSubject),
            destinationURL: issueCreationURL
        )
    }

    func refreshDiagnosticsPreview() {
        guard includeDiagnostics else {
            diagnosticsPreview = nil
            return
        }

        let context = diagnosticsProvider()

        do {
            let data = try DiagnosticsExportBuilder.makeJSONData(
                appVersion: context.appVersion,
                macOSVersion: context.macOSVersion,
                connectionState: context.connectionState,
                interfaces: context.interfaces,
                publicIP: context.publicIP,
                includeSensitiveIdentifiers: includeSensitiveIdentifiers,
                generatedAt: nowProvider()
            )

            diagnosticsPreview = String(decoding: data, as: UTF8.self)
        } catch {
            diagnosticsPreview = nil
        }
    }

    private func makeBodyText(subject: String) -> String {
        var sections: [String] = [
            "## Subject",
            subject,
            "",
            "## Feedback Type",
            category.title,
            "",
            "## Details",
            message.trimmingCharacters(in: .whitespacesAndNewlines),
        ]

        if !contact.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sections.append("")
            sections.append("## Contact")
            sections.append(contact.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        if let diagnosticsPreview {
            sections.append("")
            sections.append("## Diagnostics Snapshot")
            sections.append("```json")
            sections.append(diagnosticsPreview)
            sections.append("```")
        }

        return sections.joined(separator: "\n")
    }
}

struct FeedbackSubmissionPayload {
    let subject: String
    let body: String
    let destinationURL: URL
}
