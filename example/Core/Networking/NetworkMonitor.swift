//
//  NetworkMonitor.swift
//  example
//
//  Path: Core/Networking/NetworkMonitor.swift
//

import Foundation
import Network

/// 네트워크 상태 모니터링
///
/// `NWPathMonitor`를 사용하여 실시간으로 네트워크 연결 상태를 감지합니다.
/// `@Observable`을 사용하여 SwiftUI View에서 상태 변화를 자동으로 반영합니다.
@Observable
final class NetworkMonitor {
    /// 네트워크 사용 가능 여부
    private(set) var isNetworkAvailable: Bool = true

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isAvailable = path.status == .satisfied
            Log.debug("Network status changed: \(isAvailable ? "available" : "unavailable")")
            DispatchQueue.main.async {
                self?.isNetworkAvailable = isAvailable
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
