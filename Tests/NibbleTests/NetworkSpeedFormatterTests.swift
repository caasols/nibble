import Testing
@testable import Nibble

struct NetworkSpeedFormatterTests {
    @Test func formatsBytesPerSecond() {
        #expect(NetworkSpeedFormatter.string(bytesPerSecond: 950) == "950 B/s")
    }

    @Test func formatsKilobytesPerSecond() {
        #expect(NetworkSpeedFormatter.string(bytesPerSecond: 1536) == "1.5 KB/s")
    }

    @Test func formatsMegabytesPerSecond() {
        #expect(NetworkSpeedFormatter.string(bytesPerSecond: 5_242_880) == "5.0 MB/s")
    }
}
