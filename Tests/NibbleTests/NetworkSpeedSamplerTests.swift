import Foundation
import Testing
@testable import Nibble

struct NetworkSpeedSamplerTests {
    @Test func firstSampleProducesZeroSpeeds() {
        var sampler = NetworkSpeedSampler()

        let reading = sampler.nextSpeed(
            using: NetworkTrafficSnapshot(receivedBytes: 10_000, sentBytes: 4_000),
            at: Date(timeIntervalSince1970: 100)
        )

        #expect(reading.downloadBytesPerSecond == 0)
        #expect(reading.uploadBytesPerSecond == 0)
    }

    @Test func computesInstantDownloadAndUploadRatesFromDelta() {
        var sampler = NetworkSpeedSampler()

        _ = sampler.nextSpeed(
            using: NetworkTrafficSnapshot(receivedBytes: 20_000, sentBytes: 8_000),
            at: Date(timeIntervalSince1970: 100)
        )

        let reading = sampler.nextSpeed(
            using: NetworkTrafficSnapshot(receivedBytes: 23_000, sentBytes: 9_500),
            at: Date(timeIntervalSince1970: 103)
        )

        #expect(reading.downloadBytesPerSecond == 1_000)
        #expect(reading.uploadBytesPerSecond == 500)
    }

    @Test func counterResetDoesNotProduceNegativeSpeeds() {
        var sampler = NetworkSpeedSampler()

        _ = sampler.nextSpeed(
            using: NetworkTrafficSnapshot(receivedBytes: 100_000, sentBytes: 60_000),
            at: Date(timeIntervalSince1970: 200)
        )

        let reading = sampler.nextSpeed(
            using: NetworkTrafficSnapshot(receivedBytes: 2_000, sentBytes: 1_000),
            at: Date(timeIntervalSince1970: 201)
        )

        #expect(reading.downloadBytesPerSecond == 0)
        #expect(reading.uploadBytesPerSecond == 0)
    }
}
