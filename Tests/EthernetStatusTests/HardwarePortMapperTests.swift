import Testing
@testable import EthernetStatus

struct HardwarePortMapperTests {
    @Test func parseMapsKnownHardwarePorts() {
        let output = """
        Hardware Port: Wi-Fi
        Device: en0

        Hardware Port: Thunderbolt Ethernet Slot 1
        Device: en7

        Hardware Port: Thunderbolt Bridge
        Device: bridge0
        """

        let mapping = HardwarePortMapper.parse(output)

        #expect(mapping["en0"] == "Wi-Fi")
        #expect(mapping["en7"] == "Ethernet")
        #expect(mapping["bridge0"] == "Bridge")
    }

    @Test func parseReturnsOnlyCurrentSnapshot() {
        let output = """
        Hardware Port: Wi-Fi
        Device: en0
        """

        let mapping = HardwarePortMapper.parse(output)

        #expect(mapping.count == 1)
        #expect(mapping["en0"] == "Wi-Fi")
    }
}
