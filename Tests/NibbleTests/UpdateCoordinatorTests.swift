import Foundation
import Testing
@testable import Nibble

@MainActor
struct UpdateCoordinatorTests {
    @Test func manualCheckPublishesUpdateWhenReleaseIsNewer() async throws {
        let suite = "UpdateCoordinatorTests.manual.newer"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        let checker = try StubUpdateChecker(
            result: .success(
                AppRelease(
                    version: "1.1.0",
                    notes: "Bug fixes.",
                    downloadURL: #require(URL(string: "https://github.com/caasols/nibble/releases/tag/v1.1.0"))
                )
            )
        )
        let coordinator = UpdateCoordinator(
            checker: checker,
            currentVersion: "1.0.0",
            userDefaults: defaults,
            now: { Date(timeIntervalSince1970: 1_700_000_000) }
        )

        await coordinator.checkForUpdatesManually()

        #expect(coordinator.updatePromptRelease?.version == "1.1.0")
        #expect(coordinator.statusMessage == "Version 1.1.0 is available.")
        #expect(await checker.callCount == 1)
    }

    @Test func periodicCheckSkipsNetworkWhenIntervalHasNotElapsed() async throws {
        let suite = "UpdateCoordinatorTests.periodic.skip"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defaults.set(Date(timeIntervalSince1970: 1_700_000_000), forKey: "lastUpdateCheckDate")

        let checker = StubUpdateChecker(result: .failure(StubError()))
        let coordinator = UpdateCoordinator(
            checker: checker,
            currentVersion: "1.0.0",
            userDefaults: defaults,
            now: { Date(timeIntervalSince1970: 1_700_000_000 + 60) }
        )

        await coordinator.checkForUpdatesPeriodicallyIfNeeded()

        #expect(await checker.callCount == 0)
        #expect(coordinator.statusMessage == "Last checked recently.")
    }

    @Test func dismissingPromptClearsPendingRelease() async throws {
        let suite = "UpdateCoordinatorTests.dismiss"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        let checker = try StubUpdateChecker(
            result: .success(
                AppRelease(
                    version: "1.1.0",
                    notes: "Bug fixes.",
                    downloadURL: #require(URL(string: "https://github.com/caasols/nibble/releases/tag/v1.1.0"))
                )
            )
        )
        let coordinator = UpdateCoordinator(
            checker: checker,
            currentVersion: "1.0.0",
            userDefaults: defaults,
            now: { Date(timeIntervalSince1970: 1_700_000_000) }
        )

        await coordinator.checkForUpdatesManually()

        coordinator.dismissUpdatePrompt()

        #expect(coordinator.updatePromptRelease == nil)
    }

    @Test func manualCheckDoesNotPromptWhenVersionIsCurrent() async throws {
        let suite = "UpdateCoordinatorTests.manual.current"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        let checker = try StubUpdateChecker(
            result: .success(
                AppRelease(
                    version: "1.0.0",
                    notes: "No changes.",
                    downloadURL: #require(URL(string: "https://github.com/caasols/nibble/releases/tag/v1.0.0"))
                )
            )
        )
        let coordinator = UpdateCoordinator(
            checker: checker,
            currentVersion: "1.0.0",
            userDefaults: defaults,
            now: { Date(timeIntervalSince1970: 1_700_000_000) }
        )

        await coordinator.checkForUpdatesManually()

        #expect(coordinator.updatePromptRelease == nil)
        #expect(coordinator.statusMessage == "You're up to date.")
    }

    @Test func failedCheckPersistsLastAttemptDate() async throws {
        let suite = "UpdateCoordinatorTests.failureTimestamp"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        let checker = StubUpdateChecker(result: .failure(StubError()))
        let attemptDate = Date(timeIntervalSince1970: 1_700_000_500)
        let coordinator = UpdateCoordinator(
            checker: checker,
            currentVersion: "1.0.0",
            userDefaults: defaults,
            now: { attemptDate }
        )

        await coordinator.checkForUpdatesManually()

        #expect(coordinator.statusMessage == "Unable to check for updates right now.")
        #expect(defaults.object(forKey: "lastUpdateCheckDate") as? Date == attemptDate)
    }
}

private actor StubUpdateChecker: AppUpdateChecking {
    var result: Result<AppRelease, Error>
    var callCount = 0

    init(result: Result<AppRelease, Error>) {
        self.result = result
    }

    func latestRelease() async throws -> AppRelease {
        callCount += 1
        return try result.get()
    }
}

private struct StubError: Error {}
