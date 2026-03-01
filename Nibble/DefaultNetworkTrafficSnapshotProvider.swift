import Foundation

protocol NetworkTrafficSnapshotProviding: AnyObject {
    func currentSnapshot() -> NetworkTrafficSnapshot
}

final class DefaultNetworkTrafficSnapshotProvider: NetworkTrafficSnapshotProviding {
    func currentSnapshot() -> NetworkTrafficSnapshot {
        var totalReceived: UInt64 = 0
        var totalSent: UInt64 = 0

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return NetworkTrafficSnapshot(receivedBytes: 0, sentBytes: 0)
        }

        defer { freeifaddrs(ifaddr) }

        var pointer: UnsafeMutablePointer<ifaddrs>? = firstAddr
        while let current = pointer {
            let interface = current.pointee
            let name = String(cString: interface.ifa_name)
            let flags = Int32(interface.ifa_flags)
            let isActive = (flags & IFF_UP) == IFF_UP && (flags & IFF_RUNNING) == IFF_RUNNING

            guard isActive,
                  !name.hasPrefix("lo"),
                  let address = interface.ifa_addr,
                  address.pointee.sa_family == UInt8(AF_LINK),
                  let data = interface.ifa_data
            else {
                pointer = interface.ifa_next
                continue
            }

            let stats = data.assumingMemoryBound(to: if_data.self).pointee
            totalReceived += UInt64(stats.ifi_ibytes)
            totalSent += UInt64(stats.ifi_obytes)

            pointer = interface.ifa_next
        }

        return NetworkTrafficSnapshot(receivedBytes: totalReceived, sentBytes: totalSent)
    }
}
