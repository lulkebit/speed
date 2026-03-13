import Foundation

public final class SpeedSettingsStore {
    private enum Key {
        static let automaticTestInterval = "automaticTestInterval"
        static let appLanguage = "appLanguage"
    }

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public var automaticTestInterval: AutoTestInterval {
        get {
            let rawValue = userDefaults.integer(forKey: Key.automaticTestInterval)
            return AutoTestInterval(rawValue: rawValue) ?? .off
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Key.automaticTestInterval)
        }
    }

    public var appLanguage: AppLanguage {
        get {
            guard let rawValue = userDefaults.string(forKey: Key.appLanguage) else {
                return .system
            }

            return AppLanguage(rawValue: rawValue) ?? .system
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: Key.appLanguage)
        }
    }
}
