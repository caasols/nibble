import Foundation

enum ConnectionClassifier {
    static func hasWiredConnection(in interfaces: [NetworkInterface]) -> Bool {
        interfaces.contains { interface in
            interface.isActive && interface.type == "Ethernet"
        }
    }
}
