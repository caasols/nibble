import Foundation
import Testing
@testable import Nibble

struct AppSettingsTests {
    @Test func defaultsAreAppliedWhenNoValuesExist() {
        let defaults = UserDefaults(suiteName: "AppSettingsTests.defaults")!
        defaults.removePersistentDomain(forName: "AppSettingsTests.defaults")

        let settings = AppSettings(userDefaults: defaults)

        #expect(settings.refreshInterval == 30)
        #expect(settings.showPublicIP)
        #expect(settings.appMode == .menuBarAndDock)
    }

    @Test func refreshIntervalIsNormalizedToAllowedRangeAndStep() {
        let defaults = UserDefaults(suiteName: "AppSettingsTests.normalize")!
        defaults.removePersistentDomain(forName: "AppSettingsTests.normalize")

        let settings = AppSettings(userDefaults: defaults)
        settings.refreshInterval = 7
        #expect(settings.refreshInterval == 10)

        settings.refreshInterval = 317
        #expect(settings.refreshInterval == 300)

        settings.refreshInterval = 43
        #expect(settings.refreshInterval == 40)
    }

    @Test func persistedValuesAreReloaded() {
        let suite = "AppSettingsTests.persisted"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        var settings = AppSettings(userDefaults: defaults)
        settings.refreshInterval = 120
        settings.showPublicIP = false
        settings.appMode = .menuBarOnly

        settings = AppSettings(userDefaults: defaults)
        #expect(settings.refreshInterval == 120)
        #expect(!settings.showPublicIP)
        #expect(settings.appMode == .menuBarOnly)
    }

    @Test func appModeFallsBackToLegacyStartHiddenPreference() {
        let suite = "AppSettingsTests.legacyStartHidden"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defaults.set(true, forKey: "startHidden")

        let settings = AppSettings(userDefaults: defaults)

        #expect(settings.appMode == .menuBarOnly)
    }
}
