import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(LocalizationCatalog.localized("common.done")) {
                    dismiss()
                }
            }

            Image(systemName: "network")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("Nibble")
                .font(.title)
                .fontWeight(.bold)

            Text(LocalizationCatalog.localized("about.version"))
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(LocalizationCatalog.localized("about.description"))
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Divider()

            VStack(spacing: 8) {
                Link(LocalizationCatalog.localized("about.github"), destination: URL(string: "https://github.com/caasols/nibble")!)
                Link(LocalizationCatalog.localized("about.report_issue"), destination: URL(string: "https://github.com/caasols/nibble/issues")!)
            }

            Spacer()
        }
        .padding()
        .frame(width: 400, height: 350)
    }
}
