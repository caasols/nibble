import Foundation
import Testing
@testable import Nibble

struct UserDefaultsTelemetryQueueStoreTests {
    @Test func enqueuePersistsPendingEventCount() throws {
        let suite = "UserDefaultsTelemetryQueueStoreTests.enqueue"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        let store = UserDefaultsTelemetryQueueStore(userDefaults: defaults)
        store.enqueue(eventName: "open_preferences", payload: ["source": "menubar"])

        #expect(store.pendingEventCount == 1)

        let reloaded = UserDefaultsTelemetryQueueStore(userDefaults: defaults)
        #expect(reloaded.pendingEventCount == 1)
    }

    @Test func clearPendingEventsRemovesAllQueuedData() throws {
        let suite = "UserDefaultsTelemetryQueueStoreTests.clear"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        let store = UserDefaultsTelemetryQueueStore(userDefaults: defaults)
        store.enqueue(eventName: "app_started", payload: ["app_mode": "menuBarOnly"])
        store.enqueue(eventName: "toggle_telemetry", payload: ["enabled": "true"])
        #expect(store.pendingEventCount == 2)

        store.clearPendingEvents()

        #expect(store.pendingEventCount == 0)
    }

    @Test func enqueueDropsSensitiveAndUnknownPayloadFields() throws {
        let suite = "UserDefaultsTelemetryQueueStoreTests.sensitiveFilter"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        let store = UserDefaultsTelemetryQueueStore(userDefaults: defaults)
        store.enqueue(eventName: "toggle_public_ip", payload: [
            "enabled": "false",
            "public_ip": "198.51.100.5",
            "mac_address": "AA:BB:CC:DD:EE:FF",
            "debug_note": "ignore",
        ])

        let events = defaults.array(forKey: "telemetryPendingEvents") as? [[String: String]]
        #expect(events?.count == 1)
        #expect(events?.first?["payload.enabled"] == "false")
        #expect(events?.first?["payload.public_ip"] == nil)
        #expect(events?.first?["payload.mac_address"] == nil)
        #expect(events?.first?["payload.debug_note"] == nil)
    }

    @Test func enqueueRejectsUnknownEventName() throws {
        let suite = "UserDefaultsTelemetryQueueStoreTests.eventAllowList"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)

        let store = UserDefaultsTelemetryQueueStore(userDefaults: defaults)
        store.enqueue(eventName: "custom_event", payload: ["enabled": "true"])

        #expect(store.pendingEventCount == 0)
    }
}
