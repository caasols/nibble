import Testing
@testable import Nibble

struct MenuBarIconDescriptorTests {
    @Test func activeStateUsesConnectedIconAndDescription() {
        let descriptor = MenuBarIconDescriptor.forConnectionState(.active)

        #expect(descriptor.systemSymbolName == "network")
        #expect(descriptor.accessibilityDescription == "Ethernet Active")
    }

    @Test func inactiveStateUsesDistinctInactiveIconAndDescription() {
        let descriptor = MenuBarIconDescriptor.forConnectionState(.inactive)

        #expect(descriptor.systemSymbolName == "exclamationmark.network")
        #expect(descriptor.accessibilityDescription == "Ethernet Inactive")
    }

    @Test func disconnectedStateUsesSlashIconAndDescription() {
        let descriptor = MenuBarIconDescriptor.forConnectionState(.disconnected)

        #expect(descriptor.systemSymbolName == "network.slash")
        #expect(descriptor.accessibilityDescription == "Ethernet Disconnected")
    }

    @Test func fallbackTitleUsesSingleLetterN() {
        let descriptor = MenuBarIconDescriptor.forConnectionState(.active)

        #expect(descriptor.fallbackTitle == "N")
    }
}
