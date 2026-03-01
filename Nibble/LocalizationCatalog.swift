import Foundation

enum LocalizationCatalog {
    static func localized(_ key: String, localeIdentifier: String? = nil) -> String {
        if let localeIdentifier,
           let localeBundle = bundle(for: localeIdentifier)
        {
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
        for bundle in candidateBundles() {
            if let path = bundle.path(forResource: localeIdentifier, ofType: "lproj"),
               let localizedBundle = Bundle(path: path)
            {
                return localizedBundle
            }
        }

        return nil
    }

    private static func candidateBundles() -> [Bundle] {
        var bundles: [Bundle] = [Bundle.module, Bundle.main, Bundle(for: BundleMarker.self)]

        if let resourceURL = Bundle.main.resourceURL {
            let bundledURL = resourceURL.appendingPathComponent("Nibble_Nibble.bundle")
            if let bundle = Bundle(url: bundledURL) {
                bundles.append(bundle)
            }
        }

        return bundles
    }
}

private final class BundleMarker {}
