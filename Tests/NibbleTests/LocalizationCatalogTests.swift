import Testing
@testable import Nibble

struct LocalizationCatalogTests {
    @Test func spanishLocaleResolvesPrimaryMenuStrings() {
        #expect(LocalizationCatalog.localized("menu.preferences", localeIdentifier: "es") == "Preferencias...")
        #expect(LocalizationCatalog.localized("menu.quit", localeIdentifier: "es") == "Salir de Nibble")
        #expect(LocalizationCatalog.localized("menu.refresh_wifi", localeIdentifier: "es") == "Refrescar Wifi")
    }

    @Test func fallsBackToEnglishWhenLocaleMissing() {
        #expect(LocalizationCatalog.localized("menu.quit", localeIdentifier: "fr") == "Quit Nibble")
    }

    @Test func englishRefreshWifiMenuLabelUsesWifiSpelling() {
        #expect(LocalizationCatalog.localized("menu.refresh_wifi", localeIdentifier: "en") == "Refresh Wifi")
    }

    @Test func preferencesMenuStringsExistForEnglishAndSpanish() {
        #expect(LocalizationCatalog.localized("menu.send_feedback", localeIdentifier: "en") == "Send Feedback...")
        #expect(LocalizationCatalog.localized("menu.send_feedback", localeIdentifier: "es") == "Enviar comentarios...")
        #expect(LocalizationCatalog.localized("menu.check_updates", localeIdentifier: "en") == "Check for updates...")
        #expect(LocalizationCatalog.localized("menu.open_at_login", localeIdentifier: "en") == "Open at Startup")
        #expect(LocalizationCatalog.localized("public_ip.copied", localeIdentifier: "en") == "IP copied")
    }
}
