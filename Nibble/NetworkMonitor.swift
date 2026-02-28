import Foundation
import Network
import Combine

enum InterfaceRouteRole: Equatable {
    case none
    case defaultRoute

    var displayName: String {
        switch self {
        case .none:
            return LocalizationCatalog.localized("route_role.none")
        case .defaultRoute:
            return LocalizationCatalog.localized("route_role.default")
        }
    }
}

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
    let routeRole: InterfaceRouteRole
    let adapterDescription: String?

    init(
        name: String,
        displayName: String,
        hardwareAddress: String?,
        isActive: Bool,
        addresses: [String],
        type: String,
        medium: InterfaceMedium = .unknown,
        classificationConfidence: InterfaceClassificationConfidence = .low,
        routeRole: InterfaceRouteRole = .none,
        adapterDescription: String? = nil
    ) {
        self.name = name
        self.displayName = displayName
        self.hardwareAddress = hardwareAddress
        self.isActive = isActive
        self.addresses = addresses
        self.type = type
        self.medium = medium
        self.classificationConfidence = classificationConfidence
        self.routeRole = routeRole
        self.adapterDescription = adapterDescription
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
    private let orchestrator: NetworkMonitorOrchestrator
    private var latestPathUsesWiredEthernet = false
    private var lastPathRefreshAt: Date?
    private let minimumPathRefreshInterval: TimeInterval
    private let nowProvider: () -> Date

    init(
        settings: AppSettings,
        orchestrator: NetworkMonitorOrchestrator = NetworkMonitorOrchestrator(
            interfaceProvider: DefaultInterfaceSnapshotProvider(),
            publicIPProvider: DefaultPublicIPProvider()
        ),
        minimumPathRefreshInterval: TimeInterval = 0.5,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.settings = settings
        self.orchestrator = orchestrator
        self.minimumPathRefreshInterval = minimumPathRefreshInterval
        self.nowProvider = nowProvider
    }
    
    func startMonitoring() {
        // Monitor network path changes
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            self.latestPathUsesWiredEthernet = path.usesInterfaceType(.wiredEthernet)
            if self.shouldProcessPathUpdate(at: self.nowProvider()) {
                self.refreshNetworkState()
            }
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
            self?.refreshCycle()
        }
    }
    
    func stopMonitoring() {
        monitor?.cancel()
        timer?.invalidate()
        cancellables.removeAll()
    }
    
    private func refreshCycle() {
        refreshNetworkState()
        fetchPublicIP()
    }

    func shouldProcessPathUpdate(at now: Date) -> Bool {
        if let lastPathRefreshAt,
           now.timeIntervalSince(lastPathRefreshAt) < minimumPathRefreshInterval {
            return false
        }

        lastPathRefreshAt = now
        return true
    }

    private func refreshNetworkState() {
        workerQueue.async { [weak self] in
            guard let self = self else { return }

            let snapshot = self.orchestrator.snapshot(pathUsesWiredEthernet: self.latestPathUsesWiredEthernet)

            DispatchQueue.main.async {
                self.interfaces = snapshot.visibleInterfaces
                self.connectionState = snapshot.connectionState
                self.isEthernetConnected = snapshot.isEthernetConnected
            }
        }
    }

    private func fetchPublicIP() {
        orchestrator.fetchPublicIP(showPublicIP: settings.showPublicIP) { [weak self] ip in
            DispatchQueue.main.async {
                self?.publicIP = ip
            }
        }
    }
}
