import Testing
@testable import Nibble

struct NetworkMonitorOrchestratorTests {
    @Test func returnsSnapshotFromInterfaceProvider() {
        let expected = InterfaceSnapshot(
            allInterfaces: [
                NetworkInterface(name: "en5", displayName: "Ethernet", hardwareAddress: nil, isActive: true, addresses: ["192.168.1.20"], type: "Ethernet", medium: .wired, classificationConfidence: .high),
            ],
            visibleInterfaces: [
                NetworkInterface(name: "en5", displayName: "Ethernet", hardwareAddress: nil, isActive: true, addresses: ["192.168.1.20"], type: "Ethernet", medium: .wired, classificationConfidence: .high),
            ],
            connectionState: .active
        )

        let interfaceProvider = FakeInterfaceSnapshotProvider(snapshot: expected)
        let publicIPProvider = FakePublicIPProvider(result: "203.0.113.10")
        let orchestrator = NetworkMonitorOrchestrator(interfaceProvider: interfaceProvider, publicIPProvider: publicIPProvider)

        let snapshot = orchestrator.snapshot(pathUsesWiredEthernet: true)

        #expect(snapshot.connectionState == .active)
        #expect(snapshot.visibleInterfaces.count == 1)
        #expect(interfaceProvider.requestedPathFlags == [true])
    }

    @Test func returnsNilPublicIPWhenDisabledWithoutCallingProvider() {
        let interfaceProvider = FakeInterfaceSnapshotProvider(snapshot: InterfaceSnapshot(allInterfaces: [], visibleInterfaces: [], connectionState: .disconnected))
        let publicIPProvider = FakePublicIPProvider(result: "198.51.100.2")
        let orchestrator = NetworkMonitorOrchestrator(interfaceProvider: interfaceProvider, publicIPProvider: publicIPProvider)

        let box = ResultBox()
        orchestrator.fetchPublicIP(showPublicIP: false) { value in
            box.value = value
        }

        #expect(box.value == nil)
        #expect(publicIPProvider.callCount == 0)
    }
}

private final class ResultBox: @unchecked Sendable {
    var value: String?
}

private final class FakeInterfaceSnapshotProvider: InterfaceSnapshotProviding {
    var requestedPathFlags: [Bool] = []
    let stubbedSnapshot: InterfaceSnapshot

    init(snapshot: InterfaceSnapshot) {
        stubbedSnapshot = snapshot
    }

    func snapshot(pathUsesWiredEthernet: Bool) -> InterfaceSnapshot {
        requestedPathFlags.append(pathUsesWiredEthernet)
        return stubbedSnapshot
    }
}

private final class FakePublicIPProvider: PublicIPProviding {
    var callCount = 0
    let result: String?

    init(result: String?) {
        self.result = result
    }

    func fetchPublicIP(completion: @escaping @Sendable (String?) -> Void) {
        callCount += 1
        completion(result)
    }
}
