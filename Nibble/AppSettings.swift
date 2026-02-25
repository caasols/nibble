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

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.refreshInterval = Self.normalizedRefreshInterval(
            Self.integer(forKey: Keys.refreshInterval, defaultValue: 30, in: userDefaults)
        )
        self.showPublicIP = Self.bool(forKey: Keys.showPublicIP, defaultValue: true, in: userDefaults)
        self.appMode = Self.appMode(in: userDefaults)
    }

    private enum Keys {
        static let refreshInterval = "refreshInterval"
        static let showPublicIP = "showPublicIP"
        static let appMode = "appMode"
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
