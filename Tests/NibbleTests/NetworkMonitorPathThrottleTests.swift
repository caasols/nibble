import Foundation
import Testing
@testable import Nibble

struct NetworkMonitorPathThrottleTests {
    @Test func pathUpdatesAreThrottledWithinMinimumInterval() {
        let settings = AppSettings(userDefaults: UserDefaults(suiteName: "NetworkMonitorPathThrottleTests.throttle")!)
        let monitor = NetworkMonitor(
            settings: settings,
            orchestrator: NetworkMonitorOrchestrator(
                interfaceProvider: StubInterfaceProvider(),
                publicIPProvider: StubPublicIPProvider()
            ),
            minimumPathRefreshInterval: 0.5
        )

        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(monitor.shouldProcessPathUpdate(at: t0))
        #expect(!monitor.shouldProcessPathUpdate(at: t0.addingTimeInterval(0.1)))
        #expect(monitor.shouldProcessPathUpdate(at: t0.addingTimeInterval(0.6)))
    }
}

private final class StubInterfaceProvider: InterfaceSnapshotProviding {
    func snapshot(pathUsesWiredEthernet: Bool) -> InterfaceSnapshot {
        InterfaceSnapshot(allInterfaces: [], visibleInterfaces: [], connectionState: .disconnected)
    }
}

private final class StubPublicIPProvider: PublicIPProviding {
    func fetchPublicIP(completion: @escaping @Sendable (String?) -> Void) {
        completion(nil)
    }
}
