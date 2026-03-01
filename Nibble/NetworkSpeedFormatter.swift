import Foundation

enum NetworkSpeedFormatter {
    static func string(bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return "\(Int(bytesPerSecond.rounded())) B/s"
        }

        let kilobytesPerSecond = bytesPerSecond / 1024
        if kilobytesPerSecond < 1024 {
            return String(format: "%.1f KB/s", kilobytesPerSecond)
        }

        let megabytesPerSecond = kilobytesPerSecond / 1024
        if megabytesPerSecond < 1024 {
            return String(format: "%.1f MB/s", megabytesPerSecond)
        }

        let gigabytesPerSecond = megabytesPerSecond / 1024
        return String(format: "%.1f GB/s", gigabytesPerSecond)
    }
}
