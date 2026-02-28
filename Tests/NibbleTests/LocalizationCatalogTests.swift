import Testing
@testable import Nibble

struct LocalizationCatalogTests {
    @Test func spanishLocaleResolvesPrimaryMenuStrings() {
        #expect(LocalizationCatalog.localized("menu.preferences", localeIdentifier: "es") == "Preferencias...")
        #expect(LocalizationCatalog.localized("menu.quit", localeIdentifier: "es") == "Salir")
    }

    @Test func fallsBackToEnglishWhenLocaleMissing() {
        #expect(LocalizationCatalog.localized("menu.quit", localeIdentifier: "fr") == "Quit")
    }
}
