import Foundation
import Testing
@testable import Nibble

struct DefaultHardwarePortMappingProviderTests {
    @Test func refreshLoadsHardwarePortMap() {
        let now = MutableNow(date: Date(timeIntervalSince1970: 1_700_000_000))
        let loader = MutableLoader(outputs: [
            """
            Hardware Port: Wi-Fi
            Device: en0
            """
        ])

        let provider = DefaultHardwarePortMappingProvider(
            refreshInterval: 300,
            now: { now.date },
            loadOutput: { loader.next() },
            executeAsync: { work in work() }
        )

        provider.refreshAsyncIfNeeded()

        #expect(loader.callCount == 1)
        #expect(provider.currentMap()["en0"] == "Wi-Fi")
    }

    @Test func refreshIsThrottledUntilIntervalExpires() {
        let now = MutableNow(date: Date(timeIntervalSince1970: 1_700_000_000))
        let loader = MutableLoader(outputs: [
            """
            Hardware Port: Wi-Fi
            Device: en0
            """,
            """
            Hardware Port: Ethernet
            Device: en1
            """
        ])

        let provider = DefaultHardwarePortMappingProvider(
            refreshInterval: 300,
            now: { now.date },
            loadOutput: { loader.next() },
            executeAsync: { work in work() }
        )

        provider.refreshAsyncIfNeeded()
        now.date = now.date.addingTimeInterval(10)
        provider.refreshAsyncIfNeeded()

        #expect(loader.callCount == 1)
        #expect(provider.currentMap()["en0"] == "Wi-Fi")

        now.date = now.date.addingTimeInterval(400)
        provider.refreshAsyncIfNeeded()

        #expect(loader.callCount == 2)
        #expect(provider.currentMap()["en1"] == "Ethernet")
    }

    @Test func failedRefreshKeepsPreviousMap() {
        let now = MutableNow(date: Date(timeIntervalSince1970: 1_700_000_000))
        let loader = MutableLoader(outputs: [
            """
            Hardware Port: Wi-Fi
            Device: en0
            """,
            nil
        ])

        let provider = DefaultHardwarePortMappingProvider(
            refreshInterval: 300,
            now: { now.date },
            loadOutput: { loader.next() },
            executeAsync: { work in work() }
        )

        provider.refreshAsyncIfNeeded()
        now.date = now.date.addingTimeInterval(400)
        provider.refreshAsyncIfNeeded()

        #expect(loader.callCount == 2)
        #expect(provider.currentMap()["en0"] == "Wi-Fi")
    }
}

private final class MutableNow: @unchecked Sendable {
    var date: Date

    init(date: Date) {
        self.date = date
    }
}

private final class MutableLoader: @unchecked Sendable {
    private var outputs: [String?]
    private(set) var callCount = 0

    init(outputs: [String?]) {
        self.outputs = outputs
    }

    func next() -> String? {
        callCount += 1
        guard !outputs.isEmpty else {
            return nil
        }
        return outputs.removeFirst()
    }
}
