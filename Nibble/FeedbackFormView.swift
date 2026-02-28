import SwiftUI
import AppKit

struct FeedbackFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var composer: FeedbackComposer
    @State private var submissionErrorMessage: String?

    init(composer: FeedbackComposer) {
        _composer = StateObject(wrappedValue: composer)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Send Feedback")
                .font(.headline)

            Picker("Type", selection: $composer.category) {
                ForEach(FeedbackCategory.allCases) { category in
                    Text(category.title).tag(category)
                }
            }
            .pickerStyle(.segmented)

            TextField("Subject", text: $composer.subject)

            TextField("Contact Email (optional)", text: $composer.contact)

            Text("Details")
                .font(.caption)
                .foregroundColor(.secondary)

            TextEditor(text: $composer.message)
                .frame(minHeight: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            Toggle("Attach diagnostics snapshot", isOn: $composer.includeDiagnostics)

            Toggle("Include sensitive identifiers (public IP, local addresses, hardware IDs)", isOn: $composer.includeSensitiveIdentifiers)
                .disabled(!composer.includeDiagnostics)

            if let preview = composer.diagnosticsPreview {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Diagnostics Preview")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ScrollView {
                        Text(preview)
                            .font(.system(size: 11, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                }
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button("Submit") {
                    guard let payload = composer.submissionPayload() else {
                        return
                    }

                    submissionErrorMessage = nil

                    NSPasteboard.general.clearContents()
                    let didCopy = NSPasteboard.general.setString(payload.body, forType: .string)
                    guard didCopy else {
                        submissionErrorMessage = "Could not copy feedback to clipboard. Nothing was sent."
                        return
                    }

                    let didOpenIssuePage = NSWorkspace.shared.open(payload.destinationURL)
                    guard didOpenIssuePage else {
                        submissionErrorMessage = "Feedback was copied, but the issue page could not be opened."
                        return
                    }

                    dismiss()
                }
                .disabled(!composer.canSubmit)
                .keyboardShortcut(.defaultAction)
            }

            if let submissionErrorMessage {
                Text(submissionErrorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Text("Submit copies the prepared feedback markdown to your clipboard and opens the issue page without embedding your data in the URL.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 560, height: 640)
    }
}
