import Testing
@testable import Nibble

struct InterfaceSnapshotBuilderTests {
    @Test func buildMergesDuplicateInterfaceObservationsDeterministically() throws {
        let observations = [
            InterfaceObservation(
                name: "en5",
                displayName: "USB-C LAN",
                hardwareAddress: nil,
                isActive: false,
                addresses: ["fe80::1"],
                medium: .wired,
                classificationConfidence: .low,
                adapterDescription: nil
            ),
            InterfaceObservation(
                name: "en5",
                displayName: "USB-C LAN",
                hardwareAddress: "aa:bb:cc:dd:ee:ff",
                isActive: true,
                addresses: ["192.168.1.10", "fe80::1"],
                medium: .wired,
                classificationConfidence: .high,
                adapterDescription: "USB-C 2.5G Ethernet"
            ),
        ]

        let snapshot = InterfaceSnapshotBuilder.build(
            observations: observations,
            pathUsesWiredEthernet: true
        )

        #expect(snapshot.allInterfaces.count == 1)

        let interface = try #require(snapshot.allInterfaces.first)
        #expect(interface.name == "en5")
        #expect(interface.isActive)
        #expect(interface.hardwareAddress == "aa:bb:cc:dd:ee:ff")
        #expect(interface.addresses == ["192.168.1.10", "fe80::1"])
        #expect(interface.classificationConfidence == .high)
        #expect(interface.adapterDescription == "USB-C 2.5G Ethernet")
        #expect(snapshot.connectionState == .active)
    }

    @Test func buildDerivesVisibleInterfacesFromSingleSnapshot() {
        let observations = [
            InterfaceObservation(name: "lo0", displayName: "Loopback", hardwareAddress: nil, isActive: true, addresses: ["127.0.0.1"], medium: .loopback, classificationConfidence: .high),
            InterfaceObservation(name: "awdl0", displayName: "AWDL", hardwareAddress: nil, isActive: true, addresses: [], medium: .awdl, classificationConfidence: .high),
            InterfaceObservation(name: "utun1", displayName: "VPN", hardwareAddress: nil, isActive: true, addresses: [], medium: .vpn, classificationConfidence: .high),
            InterfaceObservation(name: "en5", displayName: "Dock LAN", hardwareAddress: nil, isActive: true, addresses: ["10.0.0.20"], medium: .wired, classificationConfidence: .high),
        ]

        let snapshot = InterfaceSnapshotBuilder.build(
            observations: observations,
            pathUsesWiredEthernet: false
        )

        #expect(snapshot.allInterfaces.count == 4)
        #expect(snapshot.visibleInterfaces.map(\.name) == ["en5"])
        #expect(snapshot.connectionState == .inactive)
    }

    @Test func buildMarksDefaultRouteInterfaceRole() {
        let observations = [
            InterfaceObservation(name: "en0", displayName: "Wi-Fi", hardwareAddress: nil, isActive: true, addresses: ["192.168.1.2"], medium: .wiFi, classificationConfidence: .high),
            InterfaceObservation(name: "en5", displayName: "Ethernet", hardwareAddress: nil, isActive: true, addresses: ["10.0.0.20"], medium: .wired, classificationConfidence: .high),
        ]

        let snapshot = InterfaceSnapshotBuilder.build(
            observations: observations,
            pathUsesWiredEthernet: false,
            defaultRouteInterfaceName: "en0"
        )

        let all = Dictionary(uniqueKeysWithValues: snapshot.allInterfaces.map { ($0.name, $0) })
        #expect(all["en0"]?.routeRole == .defaultRoute)
        #expect(all["en5"]?.routeRole == InterfaceRouteRole.none)
    }
}
