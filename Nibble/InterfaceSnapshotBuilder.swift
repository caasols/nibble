import Foundation

struct InterfaceObservation {
    let name: String
    let displayName: String
    let hardwareAddress: String?
    let isActive: Bool
    let addresses: [String]
    let medium: InterfaceMedium
    let classificationConfidence: InterfaceClassificationConfidence
    let adapterDescription: String?

    init(
        name: String,
        displayName: String,
        hardwareAddress: String?,
        isActive: Bool,
        addresses: [String],
        medium: InterfaceMedium,
        classificationConfidence: InterfaceClassificationConfidence,
        adapterDescription: String? = nil
    ) {
        self.name = name
        self.displayName = displayName
        self.hardwareAddress = hardwareAddress
        self.isActive = isActive
        self.addresses = addresses
        self.medium = medium
        self.classificationConfidence = classificationConfidence
        self.adapterDescription = adapterDescription
    }
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
    static func build(
        observations: [InterfaceObservation],
        pathUsesWiredEthernet: Bool,
        defaultRouteInterfaceName: String? = nil
    ) -> InterfaceSnapshot {
        let mergedInterfaces = annotateRouteRole(
            merge(observations: observations),
            defaultRouteInterfaceName: defaultRouteInterfaceName
        )
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
            return LocalizationCatalog.localized("interface.type.ethernet")
        case .wiFi:
            return LocalizationCatalog.localized("interface.type.wifi")
        case .vpn:
            return LocalizationCatalog.localized("interface.type.vpn")
        case .bridge:
            return LocalizationCatalog.localized("interface.type.bridge")
        case .loopback:
            return LocalizationCatalog.localized("interface.type.loopback")
        case .awdl:
            return LocalizationCatalog.localized("interface.type.awdl")
        case .bluetooth:
            return LocalizationCatalog.localized("interface.type.bluetooth")
        case .unknown:
            return LocalizationCatalog.localized("common.unknown")
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

    private static func annotateRouteRole(
        _ interfaces: [NetworkInterface],
        defaultRouteInterfaceName: String?
    ) -> [NetworkInterface] {
        guard let defaultRouteInterfaceName else {
            return interfaces
        }

        return interfaces.map { interface in
            NetworkInterface(
                name: interface.name,
                displayName: interface.displayName,
                hardwareAddress: interface.hardwareAddress,
                isActive: interface.isActive,
                addresses: interface.addresses,
                type: interface.type,
                medium: interface.medium,
                classificationConfidence: interface.classificationConfidence,
                routeRole: interface.name == defaultRouteInterfaceName ? .defaultRoute : .none,
                adapterDescription: interface.adapterDescription
            )
        }
    }

    private struct ObservationAccumulator {
        let name: String
        var displayName: String
        var hardwareAddress: String?
        var isActive: Bool
        var addresses: Set<String>
        var medium: InterfaceMedium
        var classificationConfidence: InterfaceClassificationConfidence
        var adapterDescription: String?

        init(_ observation: InterfaceObservation) {
            name = observation.name
            displayName = observation.displayName
            hardwareAddress = observation.hardwareAddress
            isActive = observation.isActive
            addresses = Set(observation.addresses)
            medium = observation.medium
            classificationConfidence = observation.classificationConfidence
            adapterDescription = observation.adapterDescription
        }

        mutating func merge(with observation: InterfaceObservation) {
            isActive = isActive || observation.isActive
            addresses.formUnion(observation.addresses)

            if hardwareAddress == nil, let resolved = observation.hardwareAddress {
                hardwareAddress = resolved
            }

            if adapterDescription == nil, let resolved = observation.adapterDescription {
                adapterDescription = resolved
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
                classificationConfidence: classificationConfidence,
                routeRole: .none,
                adapterDescription: adapterDescription
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
