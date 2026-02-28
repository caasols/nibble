import Foundation

struct NetworkTrafficSnapshot: Equatable {
    let receivedBytes: UInt64
    let sentBytes: UInt64
}

struct NetworkSpeedReading: Equatable {
    let downloadBytesPerSecond: Double
    let uploadBytesPerSecond: Double

    static let zero = NetworkSpeedReading(downloadBytesPerSecond: 0, uploadBytesPerSecond: 0)
}

struct NetworkSpeedSampler {
    private var lastSnapshot: NetworkTrafficSnapshot?
    private var lastTimestamp: Date?

    mutating func nextSpeed(using snapshot: NetworkTrafficSnapshot, at timestamp: Date) -> NetworkSpeedReading {
        guard let lastSnapshot, let lastTimestamp else {
            self.lastSnapshot = snapshot
            self.lastTimestamp = timestamp
            return .zero
        }

        let elapsedSeconds = timestamp.timeIntervalSince(lastTimestamp)
        guard elapsedSeconds > 0 else {
            self.lastSnapshot = snapshot
            self.lastTimestamp = timestamp
            return .zero
        }

        let downloadDelta = snapshot.receivedBytes >= lastSnapshot.receivedBytes
            ? snapshot.receivedBytes - lastSnapshot.receivedBytes
            : 0

        let uploadDelta = snapshot.sentBytes >= lastSnapshot.sentBytes
            ? snapshot.sentBytes - lastSnapshot.sentBytes
            : 0

        self.lastSnapshot = snapshot
        self.lastTimestamp = timestamp

        return NetworkSpeedReading(
            downloadBytesPerSecond: Double(downloadDelta) / elapsedSeconds,
            uploadBytesPerSecond: Double(uploadDelta) / elapsedSeconds
        )
    }
}
