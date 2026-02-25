import Foundation
import Combine

final class AppSettings: ObservableObject {
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

    @Published var startHidden: Bool {
        didSet {
            userDefaults.set(startHidden, forKey: Keys.startHidden)
        }
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.refreshInterval = Self.normalizedRefreshInterval(
            Self.integer(forKey: Keys.refreshInterval, defaultValue: 30, in: userDefaults)
        )
        self.showPublicIP = Self.bool(forKey: Keys.showPublicIP, defaultValue: true, in: userDefaults)
        self.startHidden = Self.bool(forKey: Keys.startHidden, defaultValue: false, in: userDefaults)
    }

    private enum Keys {
        static let refreshInterval = "refreshInterval"
        static let showPublicIP = "showPublicIP"
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

    private static func normalizedRefreshInterval(_ value: Int) -> Int {
        let clamped = min(max(value, 10), 300)
        return ((clamped + 5) / 10) * 10
    }
}
