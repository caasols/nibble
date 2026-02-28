import Foundation
import Testing
@testable import Nibble

struct UserDefaultsTelemetryQueueStoreTests {
    @Test func enqueuePersistsPendingEventCount() {
        let suite = "UserDefaultsTelemetryQueueStoreTests.enqueue"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let store = UserDefaultsTelemetryQueueStore(userDefaults: defaults)
        store.enqueue(eventName: "menu_opened", payload: ["screen": "menubar"])

        #expect(store.pendingEventCount == 1)

        let reloaded = UserDefaultsTelemetryQueueStore(userDefaults: defaults)
        #expect(reloaded.pendingEventCount == 1)
    }

    @Test func clearPendingEventsRemovesAllQueuedData() {
        let suite = "UserDefaultsTelemetryQueueStoreTests.clear"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let store = UserDefaultsTelemetryQueueStore(userDefaults: defaults)
        store.enqueue(eventName: "first", payload: nil)
        store.enqueue(eventName: "second", payload: ["ok": "true"])
        #expect(store.pendingEventCount == 2)

        store.clearPendingEvents()

        #expect(store.pendingEventCount == 0)
    }
}
