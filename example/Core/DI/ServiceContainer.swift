//
//  ServiceContainer.swift
//  example
//
//  Path: Core/DI/ServiceContainer.swift
//  Created by Claude on 2/23/26.
//

import Foundation

// MARK: - Service Container
/// 앱 전체의 의존성을 생성하고 관리하는 DI 컨테이너
///
/// 모든 서비스 인스턴스를 초기화 순서에 맞게 생성하고,
/// 순환 의존성(NetworkManager ↔ AuthManager)을 클로저로 해결합니다.
///
/// `nonisolated(unsafe)` 사용 근거:
/// - 모든 프로퍼티가 `let` 상수 → 초기화 후 불변
/// - `init()`은 `@MainActor`에서 실행 → 안전한 초기화
/// - 읽기 전용 접근은 data race 없음
///
/// 의존성 그래프:
/// ```
/// KeychainManager (ROOT)
/// AuthValidator (ROOT)
///   └→ SecureCookieStorage → KeychainManager
///       └→ NetworkManager → SecureCookieStorage, KeychainManager
///           └→ AuthService → NetworkManager
///               └→ AuthManager → AuthService, KeychainManager, SecureCookieStorage
///                   └→ NetworkManager.onForceLogout → AuthManager (순환 해결)
/// ```
@MainActor
final class ServiceContainer {
    // MARK: - Shared Instance

    private static let _shared = ServiceContainer()

    /// 싱글턴 인스턴스
    ///
    /// `nonisolated` — View 프로퍼티 초기화, ViewModel 기본 매개변수 등
    /// non-isolated 컨텍스트에서 안전하게 접근 가능
    nonisolated static var shared: ServiceContainer {
        MainActor.assumeIsolated { _shared }
    }

    // MARK: - Core Layer

    /// Keychain 저장소
    nonisolated let keychain: KeychainManager

    /// 보안 쿠키 저장소
    nonisolated let cookieStorage: SecureCookieStorage

    /// 네트워크 매니저
    nonisolated let networkManager: NetworkManager

    /// 오프라인 캐시 매니저
    nonisolated let cacheManager: CacheManager

    // MARK: - Domain Layer

    /// 인증 API 서비스
    nonisolated let authService: AuthService

    /// 입력값 검증기
    nonisolated let authValidator: AuthValidator

    /// 인증 상태 매니저
    nonisolated let authManager: AuthManager

    // MARK: - Presentation Layer

    /// 네비게이션 라우터
    nonisolated let router: Router

    // MARK: - Initialization

    private init() {
        // 1. Root (의존성 없음)
        keychain = KeychainManager()
        authValidator = AuthValidator()
        cacheManager = CacheManager()

        // 2. Core 계층
        cookieStorage = SecureCookieStorage(keychain: keychain)
        networkManager = NetworkManager(
            secureCookieStorage: cookieStorage,
            keychain: keychain
        )

        // 3. Domain 계층
        authService = AuthService(networkManager: networkManager)
        authManager = AuthManager(
            authService: authService,
            keychain: keychain,
            cookieStorage: cookieStorage,
            cacheManager: cacheManager
        )

        // 4. Presentation 계층
        router = Router()

        // 5. 순환 의존성 해결
        // NetworkManager에서 401 응답 시 AuthManager에 강제 로그아웃 알림
        networkManager.onForceLogout = { [weak authManager] in
            authManager?.handleForceLogout()
        }
    }
}
