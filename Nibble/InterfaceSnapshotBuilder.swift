import Foundation

struct InterfaceObservation {
    let name: String
    let displayName: String
    let hardwareAddress: String?
    let isActive: Bool
    let addresses: [String]
    let medium: InterfaceMedium
    let classificationConfidence: InterfaceClassificationConfidence
}

struct InterfaceSnapshot {
    let allInterfaces: [NetworkInterface]
    let visibleInterfaces: [NetworkInterface]
    let connectionState: EthernetConnectionState

    var isEthernetConnected: Bool {
        connectionState.isConnected
    }
}

enum InterfaceSnapshotBuilder {
    static func build(observations: [InterfaceObservation], pathUsesWiredEthernet: Bool) -> InterfaceSnapshot {
        let mergedInterfaces = merge(observations: observations)
        let visibleInterfaces = mergedInterfaces.filter { isVisible($0.name) }
        let connectionState = ConnectionStateEvaluator.evaluate(
            interfaces: mergedInterfaces,
            pathUsesWiredEthernet: pathUsesWiredEthernet
        )

        return InterfaceSnapshot(
            allInterfaces: mergedInterfaces,
            visibleInterfaces: visibleInterfaces,
            connectionState: connectionState
        )
    }

    static func typeName(for medium: InterfaceMedium) -> String {
        switch medium {
        case .wired:
            return "Ethernet"
        case .wiFi:
            return "Wi-Fi"
        case .vpn:
            return "VPN"
        case .bridge:
            return "Bridge"
        case .loopback:
            return "Loopback"
        case .awdl:
            return "AWDL"
        case .bluetooth:
            return "Bluetooth"
        case .unknown:
            return "Unknown"
        }
    }

    private static func merge(observations: [InterfaceObservation]) -> [NetworkInterface] {
        var merged: [String: ObservationAccumulator] = [:]

        for observation in observations {
            if var existing = merged[observation.name] {
                existing.merge(with: observation)
                merged[observation.name] = existing
            } else {
                merged[observation.name] = ObservationAccumulator(observation)
            }
        }

        return merged.values
            .map { $0.asNetworkInterface() }
            .sorted { $0.name < $1.name }
    }

    private static func isVisible(_ interfaceName: String) -> Bool {
        !interfaceName.starts(with: "lo") &&
        !interfaceName.starts(with: "awdl") &&
        !interfaceName.starts(with: "llw") &&
        !interfaceName.starts(with: "utun")
    }

    private struct ObservationAccumulator {
        let name: String
        var displayName: String
        var hardwareAddress: String?
        var isActive: Bool
        var addresses: Set<String>
        var medium: InterfaceMedium
        var classificationConfidence: InterfaceClassificationConfidence

        init(_ observation: InterfaceObservation) {
            name = observation.name
            displayName = observation.displayName
            hardwareAddress = observation.hardwareAddress
            isActive = observation.isActive
            addresses = Set(observation.addresses)
            medium = observation.medium
            classificationConfidence = observation.classificationConfidence
        }

        mutating func merge(with observation: InterfaceObservation) {
            isActive = isActive || observation.isActive
            addresses.formUnion(observation.addresses)

            if hardwareAddress == nil, let resolved = observation.hardwareAddress {
                hardwareAddress = resolved
            }

            if shouldReplaceClassification(with: observation) {
                medium = observation.medium
                classificationConfidence = observation.classificationConfidence
                displayName = observation.displayName
            }
        }

        func asNetworkInterface() -> NetworkInterface {
            NetworkInterface(
                name: name,
                displayName: displayName,
                hardwareAddress: hardwareAddress,
                isActive: isActive,
                addresses: addresses.sorted(),
                type: InterfaceSnapshotBuilder.typeName(for: medium),
                medium: medium,
                classificationConfidence: classificationConfidence
            )
        }

        private func shouldReplaceClassification(with observation: InterfaceObservation) -> Bool {
            let currentRank = confidenceRank(classificationConfidence)
            let incomingRank = confidenceRank(observation.classificationConfidence)

            if incomingRank > currentRank {
                return true
            }

            if incomingRank == currentRank && medium == .unknown && observation.medium != .unknown {
                return true
            }

            return false
        }

        private func confidenceRank(_ confidence: InterfaceClassificationConfidence) -> Int {
            switch confidence {
            case .high:
                return 2
            case .low:
                return 1
            }
        }
    }
}
