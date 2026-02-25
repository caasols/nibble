import Foundation

enum HardwarePortMapper {
    static func parse(_ output: String) -> [String: String] {
        var map: [String: String] = [:]
        var currentPort: String?

        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("Hardware Port:") {
                let value = trimmed.replacingOccurrences(of: "Hardware Port:", with: "")
                currentPort = value.trimmingCharacters(in: .whitespaces)
                continue
            }

            if trimmed.hasPrefix("Device:"), let port = currentPort {
                let value = trimmed.replacingOccurrences(of: "Device:", with: "")
                let device = value.trimmingCharacters(in: .whitespaces)
                map[device] = normalizedType(for: port)
            }
        }

        return map
    }

    private static func normalizedType(for hardwarePort: String) -> String {
        let portLower = hardwarePort.lowercased()

        if portLower.contains("wi-fi") || portLower.contains("airport") {
            return "Wi-Fi"
        }

        if portLower.contains("thunderbolt") && portLower.contains("ethernet") {
            return "Ethernet"
        }

        if portLower.contains("bridge") {
            return "Bridge"
        }

        if portLower.contains("ethernet") {
            return "Ethernet"
        }

        if portLower.contains("thunderbolt") {
            return "Thunderbolt"
        }

        if portLower.contains("bluetooth") {
            return "Bluetooth"
        }

        return hardwarePort
    }
}
