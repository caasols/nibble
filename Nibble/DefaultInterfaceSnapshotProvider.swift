import Foundation
import SystemConfiguration

final class DefaultInterfaceSnapshotProvider: InterfaceSnapshotProviding {
    private let hardwarePortProvider: HardwarePortMappingProviding
    private let defaultRouteProvider: DefaultRouteInterfaceProviding
    private var authoritativeMetadata: [String: InterfaceClassification] = [:]

    init(
        hardwarePortProvider: HardwarePortMappingProviding = DefaultHardwarePortMappingProvider(),
        defaultRouteProvider: DefaultRouteInterfaceProviding = DefaultRouteInterfaceProvider()
    ) {
        self.hardwarePortProvider = hardwarePortProvider
        self.defaultRouteProvider = defaultRouteProvider
    }

    func snapshot(pathUsesWiredEthernet: Bool) -> InterfaceSnapshot {
        hardwarePortProvider.refreshAsyncIfNeeded()
        let hardwarePortMap = hardwarePortProvider.currentMap()
        let defaultRouteInterfaceName = defaultRouteProvider.currentDefaultRouteInterfaceName()
        authoritativeMetadata = InterfaceMetadataResolver.authoritativeMetadataByBSDName()
        let observations = getInterfaceObservations(hardwarePortMap: hardwarePortMap)
        return InterfaceSnapshotBuilder.build(
            observations: observations,
            pathUsesWiredEthernet: pathUsesWiredEthernet,
            defaultRouteInterfaceName: defaultRouteInterfaceName
        )
    }

    private func getInterfaceObservations(hardwarePortMap: [String: String]) -> [InterfaceObservation] {
        var observations: [InterfaceObservation] = []

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return observations
        }

        defer { freeifaddrs(ifaddr) }

        var pointer: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = pointer {
            let interface = current.pointee

            let name = String(cString: interface.ifa_name)
            let flags = Int32(interface.ifa_flags)
            let isActive = (flags & IFF_UP) == IFF_UP && (flags & IFF_RUNNING) == IFF_RUNNING

            var addresses: [String] = []
            if let addr = interface.ifa_addr {
                var addrCopy = addr.pointee
                if addrCopy.sa_family == UInt8(AF_INET) || addrCopy.sa_family == UInt8(AF_INET6) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(&addrCopy, socklen_t(addrCopy.sa_len), &hostname, socklen_t(NI_MAXHOST), nil, 0, NI_NUMERICHOST) == 0 {
                        let utf8Bytes = hostname.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
                        let address = String(decoding: utf8Bytes, as: UTF8.self)
                        addresses.append(address)
                    }
                }
            }

            var hardwareAddress: String?
            if let dlAddr = interface.ifa_addr {
                dlAddr.withMemoryRebound(to: sockaddr_dl.self, capacity: 1) { dlData in
                    let sdl = dlData.pointee
                    if sdl.sdl_family == UInt8(AF_LINK), sdl.sdl_alen == 6 {
                        let bytes = dlData.withMemoryRebound(to: UInt8.self, capacity: 1) { ptr in
                            ptr.advanced(by: MemoryLayout<sockaddr_dl>.offset(of: \sockaddr_dl.sdl_data)!).advanced(by: Int(sdl.sdl_nlen))
                        }
                        hardwareAddress = String(
                            format: "%02x:%02x:%02x:%02x:%02x:%02x",
                            bytes[0],
                            bytes[1],
                            bytes[2],
                            bytes[3],
                            bytes[4],
                            bytes[5]
                        )
                    }
                }
            }

            let classification = authoritativeMetadata[name] ?? InterfaceMetadataResolver.classify(
                bsdName: name,
                systemType: nil,
                displayName: nil,
                fallbackTypeName: hardwarePortMap[name] ?? fallbackInterfaceType(name: name)
            )

            observations.append(
                InterfaceObservation(
                    name: name,
                    displayName: classification.displayName,
                    hardwareAddress: hardwareAddress,
                    isActive: isActive,
                    addresses: addresses,
                    medium: classification.medium,
                    classificationConfidence: classification.confidence,
                    adapterDescription: classification.confidence == .high ? classification.displayName : nil
                )
            )

            pointer = interface.ifa_next
        }

        return observations
    }

    private func fallbackInterfaceType(name: String) -> String {
        if name.starts(with: "lo") {
            return "Loopback"
        }
        if name.starts(with: "awdl") || name.starts(with: "llw") {
            return "AWDL"
        }
        if name.starts(with: "utun") {
            return "VPN"
        }
        if name.starts(with: "bridge") {
            return "Bridge"
        }
        return "Unknown"
    }
}
