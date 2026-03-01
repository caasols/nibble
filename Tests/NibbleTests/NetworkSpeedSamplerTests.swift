import Foundation
import Testing
@testable import Nibble

struct NetworkSpeedSamplerTests {
    @Test func firstSampleProducesZeroSpeeds() {
        var sampler = NetworkSpeedSampler()

        let reading = sampler.nextSpeed(
            using: NetworkTrafficSnapshot(receivedBytes: 10000, sentBytes: 4000),
            at: Date(timeIntervalSince1970: 100)
        )

        #expect(reading.downloadBytesPerSecond == 0)
        #expect(reading.uploadBytesPerSecond == 0)
    }

    @Test func computesInstantDownloadAndUploadRatesFromDelta() {
        var sampler = NetworkSpeedSampler()

        _ = sampler.nextSpeed(
            using: NetworkTrafficSnapshot(receivedBytes: 20000, sentBytes: 8000),
            at: Date(timeIntervalSince1970: 100)
        )

        let reading = sampler.nextSpeed(
            using: NetworkTrafficSnapshot(receivedBytes: 23000, sentBytes: 9500),
            at: Date(timeIntervalSince1970: 103)
        )

        #expect(reading.downloadBytesPerSecond == 1000)
        #expect(reading.uploadBytesPerSecond == 500)
    }

    @Test func counterResetDoesNotProduceNegativeSpeeds() {
        var sampler = NetworkSpeedSampler()

        _ = sampler.nextSpeed(
            using: NetworkTrafficSnapshot(receivedBytes: 100_000, sentBytes: 60000),
            at: Date(timeIntervalSince1970: 200)
        )

        let reading = sampler.nextSpeed(
            using: NetworkTrafficSnapshot(receivedBytes: 2000, sentBytes: 1000),
            at: Date(timeIntervalSince1970: 201)
        )

        #expect(reading.downloadBytesPerSecond == 0)
        #expect(reading.uploadBytesPerSecond == 0)
    }
}
