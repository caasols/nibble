import Testing
@testable import EthernetStatus

struct ConnectionClassifierTests {
    @Test func hasWiredConnectionReturnsTrueForActiveEthernet() {
        let interfaces = [
            NetworkInterface(name: "en7", displayName: "USB-C LAN", hardwareAddress: nil, isActive: true, addresses: [], type: "Ethernet")
        ]

        #expect(ConnectionClassifier.hasWiredConnection(in: interfaces))
    }

    @Test func hasWiredConnectionReturnsFalseForThunderboltBridge() {
        let interfaces = [
            NetworkInterface(name: "bridge0", displayName: "Thunderbolt Bridge", hardwareAddress: nil, isActive: true, addresses: [], type: "Bridge")
        ]

        #expect(!ConnectionClassifier.hasWiredConnection(in: interfaces))
    }

    @Test func hasWiredConnectionReturnsFalseForInactiveEthernet() {
        let interfaces = [
            NetworkInterface(name: "en4", displayName: "Ethernet", hardwareAddress: nil, isActive: false, addresses: [], type: "Ethernet")
        ]

        #expect(!ConnectionClassifier.hasWiredConnection(in: interfaces))
    }
}
