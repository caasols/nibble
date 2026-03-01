import Testing
@testable import Nibble

struct ConnectionStateEvaluatorTests {
    @Test func returnsDisconnectedWhenNoActiveWiredInterfaceExists() {
        let interfaces = [
            NetworkInterface(name: "en0", displayName: "Wi-Fi", hardwareAddress: nil, isActive: true, addresses: [], type: "Wi-Fi"),
            NetworkInterface(name: "en4", displayName: "Ethernet", hardwareAddress: nil, isActive: false, addresses: [], type: "Ethernet"),
        ]

        let state = ConnectionStateEvaluator.evaluate(interfaces: interfaces, pathUsesWiredEthernet: false)

        #expect(state == .disconnected)
    }

    @Test func returnsInactiveWhenWiredInterfaceExistsButDefaultRouteIsNotWired() {
        let interfaces = [
            NetworkInterface(name: "en5", displayName: "USB-C LAN", hardwareAddress: nil, isActive: true, addresses: [], type: "Ethernet"),
        ]

        let state = ConnectionStateEvaluator.evaluate(interfaces: interfaces, pathUsesWiredEthernet: false)

        #expect(state == .inactive)
    }

    @Test func returnsActiveWhenWiredInterfaceExistsAndDefaultRouteUsesWired() {
        let interfaces = [
            NetworkInterface(name: "en5", displayName: "USB-C LAN", hardwareAddress: nil, isActive: true, addresses: [], type: "Ethernet"),
        ]

        let state = ConnectionStateEvaluator.evaluate(interfaces: interfaces, pathUsesWiredEthernet: true)

        #expect(state == .active)
    }
}
