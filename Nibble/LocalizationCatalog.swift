import Foundation

enum LocalizationCatalog {
    static func localized(_ key: String, localeIdentifier: String? = nil) -> String {
        if let localeIdentifier,
           let localeBundle = bundle(for: localeIdentifier) {
            let value = localeBundle.localizedString(forKey: key, value: nil, table: nil)
            if value != key {
                return value
            }
        }

        let currentLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
        if let currentBundle = bundle(for: currentLanguageCode) {
            let currentValue = currentBundle.localizedString(forKey: key, value: nil, table: nil)
            if currentValue != key {
                return currentValue
            }
        }

        if let englishBundle = bundle(for: "en") {
            let englishValue = englishBundle.localizedString(forKey: key, value: nil, table: nil)
            if englishValue != key {
                return englishValue
            }
        }

        return key
    }

    private static func bundle(for localeIdentifier: String) -> Bundle? {
        guard let path = Bundle.module.path(forResource: localeIdentifier, ofType: "lproj") else {
            return nil
        }

        return Bundle(path: path)
    }
}
