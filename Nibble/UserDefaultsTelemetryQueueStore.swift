import Foundation

protocol TelemetryQueueStoring {
    var pendingEventCount: Int { get }
    func enqueue(eventName: String, payload: [String: String]?)
    func clearPendingEvents()
}

final class UserDefaultsTelemetryQueueStore: TelemetryQueueStoring {
    private let userDefaults: UserDefaults
    private let queueKey: String
    private static let allowedPayloadKeysByEvent: [String: Set<String>] = [
        "app_started": ["app_mode"],
        "open_preferences": ["source"],
        "toggle_telemetry": ["enabled"],
        "toggle_public_ip": ["enabled"],
    ]

    init(userDefaults: UserDefaults = .standard, queueKey: String = "telemetryPendingEvents") {
        self.userDefaults = userDefaults
        self.queueKey = queueKey
    }

    var pendingEventCount: Int {
        queuedEvents().count
    }

    func enqueue(eventName: String, payload: [String: String]?) {
        guard let allowedPayloadKeys = Self.allowedPayloadKeysByEvent[eventName] else {
            return
        }

        var events = queuedEvents()
        var event: [String: String] = [
            "name": eventName,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
        ]

        if let payload {
            for (key, value) in payload {
                guard allowedPayloadKeys.contains(key) else {
                    continue
                }

                event["payload.\(key)"] = value
            }
        }

        events.append(event)
        userDefaults.set(events, forKey: queueKey)
    }

    func clearPendingEvents() {
        userDefaults.removeObject(forKey: queueKey)
    }

    private func queuedEvents() -> [[String: String]] {
        userDefaults.array(forKey: queueKey) as? [[String: String]] ?? []
    }
}
