import Foundation
import Combine

final class AppSettings: ObservableObject {
    enum AppMode: String {
        case menuBarOnly
        case menuBarAndDock
    }

    @Published var refreshInterval: Int {
        didSet {
            let normalized = Self.normalizedRefreshInterval(refreshInterval)
            guard normalized == refreshInterval else {
                refreshInterval = normalized
                return
            }
            userDefaults.set(refreshInterval, forKey: Keys.refreshInterval)
        }
    }

    @Published var showPublicIP: Bool {
        didSet {
            userDefaults.set(showPublicIP, forKey: Keys.showPublicIP)
        }
    }

    @Published var appMode: AppMode {
        didSet {
            userDefaults.set(appMode.rawValue, forKey: Keys.appMode)
        }
    }

    @Published var telemetryEnabled: Bool {
        didSet {
            userDefaults.set(telemetryEnabled, forKey: Keys.telemetryEnabled)
        }
    }

    @Published private(set) var pendingTelemetryEventCount: Int

    var publicIPProviderHost: String {
        "api.ipify.org"
    }

    var publicIPTransparencySummary: String {
        if showPublicIP {
            return "Nibble requests your public IP from \(publicIPProviderHost) at launch, when enabled, and every \(refreshInterval) seconds during refresh. Turn this off to stop public IP requests."
        }

        return "Public IP lookups are off. Nibble does not request your public IP unless you enable this setting."
    }

    private let userDefaults: UserDefaults
    private let telemetryStore: TelemetryQueueStoring

    init(
        userDefaults: UserDefaults = .standard,
        telemetryStore: TelemetryQueueStoring? = nil
    ) {
        self.userDefaults = userDefaults
        let resolvedTelemetryStore = telemetryStore ?? UserDefaultsTelemetryQueueStore(userDefaults: userDefaults)
        self.telemetryStore = resolvedTelemetryStore
        self.refreshInterval = Self.normalizedRefreshInterval(
            Self.integer(forKey: Keys.refreshInterval, defaultValue: 30, in: userDefaults)
        )
        self.showPublicIP = Self.bool(forKey: Keys.showPublicIP, defaultValue: true, in: userDefaults)
        self.appMode = Self.appMode(in: userDefaults)
        self.telemetryEnabled = Self.bool(forKey: Keys.telemetryEnabled, defaultValue: false, in: userDefaults)
        self.pendingTelemetryEventCount = resolvedTelemetryStore.pendingEventCount
    }

    func erasePendingTelemetryData() {
        telemetryStore.clearPendingEvents()
        pendingTelemetryEventCount = telemetryStore.pendingEventCount
    }

    private enum Keys {
        static let refreshInterval = "refreshInterval"
        static let showPublicIP = "showPublicIP"
        static let appMode = "appMode"
        static let telemetryEnabled = "telemetryEnabled"
        static let startHidden = "startHidden"
    }

    private static func integer(forKey key: String, defaultValue: Int, in defaults: UserDefaults) -> Int {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }
        return defaults.integer(forKey: key)
    }

    private static func bool(forKey key: String, defaultValue: Bool, in defaults: UserDefaults) -> Bool {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }
        return defaults.bool(forKey: key)
    }

    private static func appMode(in defaults: UserDefaults) -> AppMode {
        if let storedMode = defaults.string(forKey: Keys.appMode),
           let appMode = AppMode(rawValue: storedMode) {
            return appMode
        }

        let legacyStartHidden = Self.bool(forKey: Keys.startHidden, defaultValue: false, in: defaults)
        return legacyStartHidden ? .menuBarOnly : .menuBarAndDock
    }

    private static func normalizedRefreshInterval(_ value: Int) -> Int {
        let clamped = min(max(value, 10), 300)
        return ((clamped + 5) / 10) * 10
    }
}
