import Foundation
import ServiceManagement

protocol LoginItemManaging {
    func isEnabled() -> Bool
    func setEnabled(_ enabled: Bool) throws
}

struct LoginItemManager: LoginItemManaging {
    private let service: SMAppService

    init(service: SMAppService = .mainApp) {
        self.service = service
    }

    func isEnabled() -> Bool {
        service.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try service.register()
        } else {
            try service.unregister()
        }
    }
}

@MainActor
final class LoginItemController: ObservableObject {
    @Published private(set) var isOpenAtLogin: Bool
    @Published private(set) var lastErrorMessage: String?

    private let manager: LoginItemManaging

    init(manager: LoginItemManaging = LoginItemManager()) {
        self.manager = manager
        self.isOpenAtLogin = manager.isEnabled()
        self.lastErrorMessage = nil
    }

    func refreshFromSystem() {
        isOpenAtLogin = manager.isEnabled()
    }

    func setOpenAtLogin(_ enabled: Bool) {
        let previous = isOpenAtLogin
        lastErrorMessage = nil

        do {
            try manager.setEnabled(enabled)
            isOpenAtLogin = manager.isEnabled()
        } catch {
            isOpenAtLogin = previous
            lastErrorMessage = LocalizationCatalog.localized("open_at_login.error")
        }
    }
}
