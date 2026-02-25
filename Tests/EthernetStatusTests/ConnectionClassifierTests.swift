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

    @Test func hasWiredConnectionReturnsTrueWhenTypeContainsEthernetKeyword() {
        let interfaces = [
            NetworkInterface(name: "en8", displayName: "USB LAN", hardwareAddress: nil, isActive: true, addresses: [], type: "USB-C Ethernet Adapter")
        ]

        #expect(ConnectionClassifier.hasWiredConnection(in: interfaces))
    }

    @Test func hasWiredConnectionReturnsFalseForActiveWiFi() {
        let interfaces = [
            NetworkInterface(name: "en0", displayName: "Wi-Fi", hardwareAddress: nil, isActive: true, addresses: [], type: "Wi-Fi")
        ]

        #expect(!ConnectionClassifier.hasWiredConnection(in: interfaces))
    }

    @Test func hasWiredConnectionReturnsTrueForLanAdapterLabel() {
        let interfaces = [
            NetworkInterface(name: "en5", displayName: "USB-C LAN", hardwareAddress: nil, isActive: true, addresses: [], type: "LAN Adapter")
        ]

        #expect(ConnectionClassifier.hasWiredConnection(in: interfaces))
    }

    @Test func hasWiredConnectionHandlesCommonNegativeScenarios() {
        let scenarios: [[NetworkInterface]] = [
            [NetworkInterface(name: "utun2", displayName: "VPN", hardwareAddress: nil, isActive: true, addresses: [], type: "VPN")],
            [NetworkInterface(name: "bridge0", displayName: "Bridge", hardwareAddress: nil, isActive: true, addresses: [], type: "Bridge")],
            [NetworkInterface(name: "en9", displayName: "en9", hardwareAddress: nil, isActive: true, addresses: [], type: "Unknown")]
        ]

        for interfaces in scenarios {
            #expect(!ConnectionClassifier.hasWiredConnection(in: interfaces))
        }
    }
}
