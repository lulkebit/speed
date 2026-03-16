import Darwin
import Foundation
import Network

@MainActor
public protocol NetworkChangeMonitoring: AnyObject {
    var onNetworkChange: (@MainActor @Sendable () -> Void)? { get set }
    func start()
}

@MainActor
public final class NetworkChangeMonitor: NetworkChangeMonitoring {
    public var onNetworkChange: (@MainActor @Sendable () -> Void)?

    private let monitor: NWPathMonitor
    private let queue: DispatchQueue
    private var hasReceivedInitialSnapshot = false
    private var lastSnapshot: NetworkChangeSnapshot?
    private var isStarted = false

    public init(
        monitor: NWPathMonitor = NWPathMonitor(),
        queue: DispatchQueue = DispatchQueue(label: "SpeedMenuBar.NetworkChangeMonitor")
    ) {
        self.monitor = monitor
        self.queue = queue
    }

    deinit {
        monitor.cancel()
    }

    public func start() {
        guard !isStarted else {
            return
        }

        isStarted = true
        monitor.pathUpdateHandler = { [weak self] path in
            let snapshot = NetworkChangeSnapshot.make(from: path)

            Task { @MainActor [weak self] in
                self?.handle(snapshot)
            }
        }
        monitor.start(queue: queue)
    }

    private func handle(_ snapshot: NetworkChangeSnapshot) {
        guard hasReceivedInitialSnapshot else {
            hasReceivedInitialSnapshot = true
            lastSnapshot = snapshot
            return
        }

        guard snapshot != lastSnapshot else {
            return
        }

        lastSnapshot = snapshot
        onNetworkChange?()
    }
}

private struct NetworkChangeSnapshot: Equatable, Sendable {
    let status: String
    let activeInterfaceNames: [String]
    let activeInterfaceKinds: [String]
    let activeAddresses: [String]
    let isConstrained: Bool
    let isExpensive: Bool

    static func make(from path: NWPath) -> Self {
        let activeInterfaces = path.availableInterfaces.filter { path.usesInterfaceType($0.type) }

        return NetworkChangeSnapshot(
            status: path.status.debugName,
            activeInterfaceNames: activeInterfaces.map(\.name).sorted(),
            activeInterfaceKinds: activeInterfaces.map { $0.type.debugName }.sorted(),
            activeAddresses: currentAddresses(),
            isConstrained: path.isConstrained,
            isExpensive: path.isExpensive
        )
    }

    private static func currentAddresses() -> [String] {
        var interfaceAddresses = [String]()
        var interfacesPointer: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&interfacesPointer) == 0, let firstInterface = interfacesPointer else {
            return interfaceAddresses
        }

        defer {
            freeifaddrs(interfacesPointer)
        }

        var currentInterface: UnsafeMutablePointer<ifaddrs>? = firstInterface
        while let interface = currentInterface?.pointee {
            let flags = Int32(interface.ifa_flags)
            let isUp = (flags & (IFF_UP | IFF_RUNNING)) == (IFF_UP | IFF_RUNNING)
            let isLoopback = (flags & IFF_LOOPBACK) == IFF_LOOPBACK

            if isUp,
               !isLoopback,
               let addressPointer = interface.ifa_addr {
                let family = addressPointer.pointee.sa_family
                guard family == UInt8(AF_INET) || family == UInt8(AF_INET6) else {
                    currentInterface = interface.ifa_next
                    continue
                }

                var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let result = getnameinfo(
                    addressPointer,
                    socklen_t(addressPointer.pointee.sa_len),
                    &host,
                    socklen_t(host.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                )

                if result == 0 {
                    let address = String(decoding: host.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
                    interfaceAddresses.append(
                        "\(String(cString: interface.ifa_name)):\(address)"
                    )
                }
            }

            currentInterface = interface.ifa_next
        }

        return interfaceAddresses.sorted()
    }
}

private extension NWPath.Status {
    var debugName: String {
        switch self {
        case .satisfied:
            "satisfied"
        case .requiresConnection:
            "requiresConnection"
        case .unsatisfied:
            "unsatisfied"
        @unknown default:
            "unknown"
        }
    }
}

private extension NWInterface.InterfaceType {
    var debugName: String {
        switch self {
        case .cellular:
            "cellular"
        case .loopback:
            "loopback"
        case .other:
            "other"
        case .wifi:
            "wifi"
        case .wiredEthernet:
            "ethernet"
        @unknown default:
            "unknown"
        }
    }
}
