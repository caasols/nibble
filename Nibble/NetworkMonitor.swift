import Foundation
import Network
import SystemConfiguration
import Combine

struct NetworkInterface: Identifiable {
    var id: String { name }
    let name: String
    let displayName: String
    let hardwareAddress: String?
    let isActive: Bool
    var addresses: [String]
    let type: String
    let medium: InterfaceMedium
    let classificationConfidence: InterfaceClassificationConfidence

    init(
        name: String,
        displayName: String,
        hardwareAddress: String?,
        isActive: Bool,
        addresses: [String],
        type: String,
        medium: InterfaceMedium = .unknown,
        classificationConfidence: InterfaceClassificationConfidence = .low
    ) {
        self.name = name
        self.displayName = displayName
        self.hardwareAddress = hardwareAddress
        self.isActive = isActive
        self.addresses = addresses
        self.type = type
        self.medium = medium
        self.classificationConfidence = classificationConfidence
    }
}

final class NetworkMonitor: ObservableObject, @unchecked Sendable {
    @Published var isEthernetConnected: Bool = false
    @Published var connectionState: EthernetConnectionState = .disconnected
    @Published var publicIP: String?
    @Published var interfaces: [NetworkInterface] = []
    
    private var monitor: NWPathMonitor?
    private var timer: Timer?
    var cancellables = Set<AnyCancellable>()
    private let workerQueue = DispatchQueue(label: "com.nibble.monitor", qos: .utility)
    private var currentRefreshInterval: TimeInterval = 30
    private let settings: AppSettings
    
    // Cache for hardware port mappings
    private var hardwarePortMap: [String: String] = [:]
    private var authoritativeMetadata: [String: InterfaceClassification] = [:]
    private var latestPathUsesWiredEthernet = false

    init(settings: AppSettings) {
        self.settings = settings
    }
    
    func startMonitoring() {
        // Monitor network path changes
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            self.latestPathUsesWiredEthernet = path.usesInterfaceType(.wiredEthernet)
            self.refreshNetworkState()
        }
        monitor?.start(queue: workerQueue)

        settings.$refreshInterval
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] refreshInterval in
                self?.scheduleRefreshTimer(with: TimeInterval(refreshInterval))
            }
            .store(in: &cancellables)

        settings.$showPublicIP
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShowPublicIP in
                guard let self = self else { return }
                if shouldShowPublicIP {
                    self.fetchPublicIP()
                } else {
                    self.publicIP = nil
                }
            }
            .store(in: &cancellables)
         
        // Fetch public IP
        fetchPublicIP()
         
        // Update interfaces initially
        refreshNetworkState()
         
        // Set up periodic refresh
        scheduleRefreshTimer(with: TimeInterval(settings.refreshInterval))
    }

    private func scheduleRefreshTimer(with interval: TimeInterval) {
        timer?.invalidate()
        currentRefreshInterval = interval

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.fetchPublicIP()
            self?.refreshNetworkState()
        }
    }
    
    func stopMonitoring() {
        monitor?.cancel()
        timer?.invalidate()
        cancellables.removeAll()
    }
    
    private func buildHardwarePortMap() {
        // Use networksetup to get accurate hardware port mappings
        let task = Process()
        task.launchPath = "/usr/sbin/networksetup"
        task.arguments = ["-listallhardwareports"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                hardwarePortMap = HardwarePortMapper.parse(output)
            }
        } catch {
            print("Failed to get hardware ports: \(error)")
        }
    }
    
    private func refreshNetworkState() {
        workerQueue.async { [weak self] in
            guard let self = self else { return }

            self.buildHardwarePortMap()
            self.authoritativeMetadata = InterfaceMetadataResolver.authoritativeMetadataByBSDName()
            let observations = self.getInterfaceObservations()
            let snapshot = InterfaceSnapshotBuilder.build(
                observations: observations,
                pathUsesWiredEthernet: self.latestPathUsesWiredEthernet
            )

            DispatchQueue.main.async {
                self.interfaces = snapshot.visibleInterfaces
                self.connectionState = snapshot.connectionState
                self.isEthernetConnected = snapshot.isEthernetConnected
            }
        }
    }

    private func fetchPublicIP() {
        guard settings.showPublicIP else {
            DispatchQueue.main.async { [weak self] in
                self?.publicIP = nil
            }
            return
        }

        guard let url = URL(string: "https://api.ipify.org?format=json") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else { return }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
               let ip = json["ip"] {
                DispatchQueue.main.async {
                    self?.publicIP = ip
                }
            }
        }.resume()
    }
    
    private func getInterfaceObservations() -> [InterfaceObservation] {
        var observations: [InterfaceObservation] = []
        
        // Get all interfaces
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
            
            // Get addresses
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
            
            // Get hardware address (MAC)
            var hardwareAddress: String?
            if let dlAddr = interface.ifa_addr {
                dlAddr.withMemoryRebound(to: sockaddr_dl.self, capacity: 1) { dlData in
                    let sdl = dlData.pointee
                    if sdl.sdl_family == UInt8(AF_LINK) && sdl.sdl_alen == 6 {
                        let bytes = dlData.withMemoryRebound(to: UInt8.self, capacity: 1) { ptr in
                            ptr.advanced(by: MemoryLayout<sockaddr_dl>.offset(of: \sockaddr_dl.sdl_data)!).advanced(by: Int(sdl.sdl_nlen))
                        }
                        hardwareAddress = String(format: "%02x:%02x:%02x:%02x:%02x:%02x",
                            bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5])
                    }
                }
            }
            
            // Determine type from hardware port mapping
            let classification = authoritativeMetadata[name] ?? InterfaceMetadataResolver.classify(
                bsdName: name,
                systemType: nil,
                displayName: nil,
                fallbackTypeName: hardwarePortMap[name] ?? getFallbackInterfaceType(name: name)
            )
            observations.append(
                InterfaceObservation(
                    name: name,
                    displayName: classification.displayName,
                    hardwareAddress: hardwareAddress,
                    isActive: isActive,
                    addresses: addresses,
                    medium: classification.medium,
                    classificationConfidence: classification.confidence
                )
            )

            pointer = interface.ifa_next
        }
        
        return observations
    }
    
    private func getFallbackInterfaceType(name: String) -> String {
        // Fallback when networksetup doesn't provide info
        if name.starts(with: "lo") {
            return "Loopback"
        } else if name.starts(with: "awdl") || name.starts(with: "llw") {
            return "AWDL"
        } else if name.starts(with: "utun") {
            return "VPN"
        } else if name.starts(with: "bridge") {
            return "Bridge"
        } else if name.starts(with: "en") {
            return "Unknown"
        }
        return "Unknown"
    }
}
