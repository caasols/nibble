import Foundation
import Testing
@testable import Nibble

struct AppSettingsTests {
    @Test func defaultsAreAppliedWhenNoValuesExist() throws {
        let defaults = try #require(UserDefaults(suiteName: "AppSettingsTests.defaults"))
        defaults.removePersistentDomain(forName: "AppSettingsTests.defaults")

        let settings = AppSettings(userDefaults: defaults)

        #expect(settings.refreshInterval == 30)
        #expect(settings.showPublicIP)
        #expect(settings.appMode == .menuBarAndDock)
        #expect(settings.telemetryEnabled == false)
        #expect(settings.pendingTelemetryEventCount == 0)
    }

    @Test func refreshIntervalIsNormalizedToAllowedRangeAndStep() throws {
        let defaults = try #require(UserDefaults(suiteName: "AppSettingsTests.normalize"))
        defaults.removePersistentDomain(forName: "AppSettingsTests.normalize")

        let settings = AppSettings(userDefaults: defaults)
        settings.refreshInterval = 7
        #expect(settings.refreshInterval == 10)

        settings.refreshInterval = 317
        #expect(settings.refreshInterval == 300)

        settings.refreshInterval = 43
        #expect(settings.refreshInterval == 40)
    }

    @Test func persistedValuesAreReloaded() throws {
        let suite = "AppSettingsTests.persisted"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        var settings = AppSettings(userDefaults: defaults)
        settings.refreshInterval = 120
        settings.showPublicIP = false
        settings.appMode = .menuBarOnly

        settings = AppSettings(userDefaults: defaults)
        #expect(settings.refreshInterval == 120)
        #expect(!settings.showPublicIP)
        #expect(settings.appMode == .menuBarOnly)

        settings.telemetryEnabled = true
        settings = AppSettings(userDefaults: defaults)
        #expect(settings.telemetryEnabled)
    }

    @Test func appModeFallsBackToLegacyStartHiddenPreference() throws {
        let suite = "AppSettingsTests.legacyStartHidden"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        defaults.set(true, forKey: "startHidden")

        let settings = AppSettings(userDefaults: defaults)

        #expect(settings.appMode == .menuBarOnly)
    }

    @Test func publicIPTransparencySummaryIncludesProviderAndRefreshCadenceWhenEnabled() throws {
        let defaults = try #require(UserDefaults(suiteName: "AppSettingsTests.publicIPTransparency.enabled"))
        defaults.removePersistentDomain(forName: "AppSettingsTests.publicIPTransparency.enabled")

        let settings = AppSettings(userDefaults: defaults)
        settings.refreshInterval = 120
        settings.showPublicIP = true

        #expect(settings.publicIPProviderHost == "api.ipify.org")
        #expect(settings.publicIPTransparencySummary == "Nibble requests your public IP from api.ipify.org at launch, when enabled, and every 120 seconds during refresh. Turn this off to stop public IP requests.")
    }

    @Test func publicIPTransparencySummaryStatesNoRequestsWhenDisabled() throws {
        let defaults = try #require(UserDefaults(suiteName: "AppSettingsTests.publicIPTransparency.disabled"))
        defaults.removePersistentDomain(forName: "AppSettingsTests.publicIPTransparency.disabled")

        let settings = AppSettings(userDefaults: defaults)
        settings.showPublicIP = false

        #expect(settings.publicIPTransparencySummary == "Public IP lookups are off. Nibble does not request your public IP unless you enable this setting.")
    }

    @Test func erasePendingTelemetryDataClearsStoredQueueCount() throws {
        let defaults = try #require(UserDefaults(suiteName: "AppSettingsTests.telemetryClear"))
        defaults.removePersistentDomain(forName: "AppSettingsTests.telemetryClear")

        let telemetryStore = UserDefaultsTelemetryQueueStore(userDefaults: defaults)
        telemetryStore.enqueue(eventName: "app_started", payload: ["source": "test"])
        telemetryStore.enqueue(eventName: "open_preferences", payload: nil)

        let settings = AppSettings(userDefaults: defaults, telemetryStore: telemetryStore)
        #expect(settings.pendingTelemetryEventCount == 2)

        settings.erasePendingTelemetryData()

        #expect(settings.pendingTelemetryEventCount == 0)
        #expect(telemetryStore.pendingEventCount == 0)
    }
}
