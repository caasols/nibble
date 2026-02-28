import Foundation

struct GitHubReleaseUpdateChecker: AppUpdateChecking {
    private let session: URLSession
    private let endpoint: URL

    init(
        session: URLSession = .shared,
        endpoint: URL = URL(string: "https://api.github.com/repos/caasols/nibble/releases/latest")!
    ) {
        self.session = session
        self.endpoint = endpoint
    }

    func latestRelease() async throws -> AppRelease {
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 15
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("Nibble", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoder = JSONDecoder()
        let payload = try decoder.decode(GitHubLatestReleasePayload.self, from: data)
        guard !payload.draft, !payload.prerelease else {
            throw URLError(.cannotParseResponse)
        }

        return AppRelease(
            version: payload.tagName,
            notes: payload.body.trimmingCharacters(in: .whitespacesAndNewlines),
            downloadURL: payload.htmlURL
        )
    }
}

private struct GitHubLatestReleasePayload: Decodable {
    let tagName: String
    let htmlURL: URL
    let body: String
    let draft: Bool
    let prerelease: Bool

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case body
        case draft
        case prerelease
    }
}
