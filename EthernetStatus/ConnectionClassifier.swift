import Foundation

enum ConnectionClassifier {
    static func hasWiredConnection(in interfaces: [NetworkInterface]) -> Bool {
        interfaces.contains { interface in
            guard interface.isActive else {
                return false
            }

            let identity = [interface.type, interface.displayName, interface.name]
                .joined(separator: " ")
                .lowercased()

            if identity.contains("wi-fi") || identity.contains("wifi") || identity.contains("airport") || identity.contains("wlan") {
                return false
            }

            if identity.contains("bridge") || identity.contains("vpn") || identity.contains("awdl") {
                return false
            }

            let tokens = Set(identity.split { !$0.isLetter && !$0.isNumber }.map(String.init))
            return tokens.contains("ethernet") || tokens.contains("lan")
        }
    }
}
