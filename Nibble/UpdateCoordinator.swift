import Foundation

struct AppRelease: Equatable, Sendable {
    let version: String
    let notes: String
    let downloadURL: URL
}

protocol AppUpdateChecking: Sendable {
    func latestRelease() async throws -> AppRelease
}

@MainActor
final class UpdateCoordinator: ObservableObject {
    @Published var updatePromptRelease: AppRelease?
    @Published private(set) var statusMessage: String = LocalizationCatalog.localized("updates.status.enabled")

    private let checker: AppUpdateChecking
    private let currentVersion: String
    private let userDefaults: UserDefaults
    private let now: () -> Date
    private let minimumCheckInterval: TimeInterval
    private var isChecking = false

    init(
        checker: AppUpdateChecking = GitHubReleaseUpdateChecker(),
        currentVersion: String = Bundle.main.nibbleVersion,
        userDefaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init,
        minimumCheckInterval: TimeInterval = 6 * 60 * 60
    ) {
        self.checker = checker
        self.currentVersion = currentVersion
        self.userDefaults = userDefaults
        self.now = now
        self.minimumCheckInterval = minimumCheckInterval
    }

    func checkForUpdatesManually() async {
        await performCheck()
    }

    func checkForUpdatesPeriodicallyIfNeeded() async {
        guard shouldCheckPeriodically else {
            statusMessage = LocalizationCatalog.localized("updates.status.checked_recently")
            return
        }

        await performCheck()
    }

    func dismissUpdatePrompt() {
        updatePromptRelease = nil
    }

    private var shouldCheckPeriodically: Bool {
        guard let lastCheckDate = userDefaults.object(forKey: Keys.lastUpdateCheckDate) as? Date else {
            return true
        }

        return now().timeIntervalSince(lastCheckDate) >= minimumCheckInterval
    }

    private func performCheck() async {
        guard !isChecking else {
            statusMessage = LocalizationCatalog.localized("updates.status.in_progress")
            return
        }

        isChecking = true
        defer {
            userDefaults.set(now(), forKey: Keys.lastUpdateCheckDate)
            isChecking = false
        }

        do {
            let release = try await checker.latestRelease()

            guard Self.isVersion(release.version, newerThan: currentVersion) else {
                statusMessage = LocalizationCatalog.localized("updates.status.up_to_date")
                updatePromptRelease = nil
                return
            }

            updatePromptRelease = release
            statusMessage = String(format: LocalizationCatalog.localized("updates.status.available"), release.version)
        } catch {
            statusMessage = LocalizationCatalog.localized("updates.status.unavailable")
        }
    }

    static func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        let candidateParts = normalizedVersionParts(candidate)
        let currentParts = normalizedVersionParts(current)
        let maxCount = max(candidateParts.count, currentParts.count)

        for index in 0 ..< maxCount {
            let lhs = index < candidateParts.count ? candidateParts[index] : 0
            let rhs = index < currentParts.count ? currentParts[index] : 0

            if lhs != rhs {
                return lhs > rhs
            }
        }

        return false
    }

    private static func normalizedVersionParts(_ version: String) -> [Int] {
        let cleaned = version.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "v", with: "", options: [.caseInsensitive, .anchored])

        return cleaned
            .split(separator: ".")
            .map { Int($0.filter(\.isNumber)) ?? 0 }
    }

    private enum Keys {
        static let lastUpdateCheckDate = "lastUpdateCheckDate"
    }
}

private extension Bundle {
    var nibbleVersion: String {
        if let shortVersion = infoDictionary?["CFBundleShortVersionString"] as? String,
           !shortVersion.isEmpty
        {
            return shortVersion
        }

        return "0.1.3"
    }
}
