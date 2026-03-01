import Testing
@testable import Nibble

@MainActor
struct LoginItemControllerTests {
    @Test func initializesFromCurrentSystemState() {
        let manager = StubLoginItemManager(initiallyEnabled: true)

        let controller = LoginItemController(manager: manager)

        #expect(controller.isOpenAtLogin)
        #expect(controller.lastErrorMessage == nil)
    }

    @Test func appliesRequestedChangeWhenManagerSucceeds() {
        let manager = StubLoginItemManager(initiallyEnabled: false)
        let controller = LoginItemController(manager: manager)

        controller.setOpenAtLogin(true)

        #expect(controller.isOpenAtLogin)
        #expect(manager.isEnabled())
        #expect(controller.lastErrorMessage == nil)
    }

    @Test func rollsBackAndPublishesErrorWhenManagerFails() {
        let manager = StubLoginItemManager(initiallyEnabled: false)
        manager.shouldFail = true
        let controller = LoginItemController(manager: manager)

        controller.setOpenAtLogin(true)

        #expect(!controller.isOpenAtLogin)
        #expect(controller.lastErrorMessage != nil)
    }

    @Test func refreshFromSystemReloadsLatestState() {
        let manager = StubLoginItemManager(initiallyEnabled: false)
        let controller = LoginItemController(manager: manager)

        manager.enabled = true
        controller.refreshFromSystem()

        #expect(controller.isOpenAtLogin)
    }
}

private final class StubLoginItemManager: LoginItemManaging {
    var enabled: Bool
    var shouldFail = false

    init(initiallyEnabled: Bool) {
        enabled = initiallyEnabled
    }

    func isEnabled() -> Bool {
        enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        if shouldFail {
            throw StubError.forcedFailure
        }
        self.enabled = enabled
    }

    enum StubError: Error {
        case forcedFailure
    }
}
