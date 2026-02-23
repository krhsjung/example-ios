//
//  AuthManager.swift
//  example
//
//  Path: Domain/Managers/AuthManager.swift
//  Created by 정희석 on 1/6/26.
//

import UIKit
import Observation
import AuthenticationServices

// MARK: - AuthManager
/// 앱 전체의 인증 상태를 관리하는 싱글톤 매니저
///
/// 주요 기능:
/// - 세션 관리: 앱 시작 시 기존 세션 확인, 로그아웃 처리
/// - 이메일 인증: 이메일/비밀번호 기반 로그인 및 회원가입
/// - 소셜 인증: Google OAuth, Apple Sign In (웹/네이티브) 지원
///
/// 사용 예시:
/// ```swift
/// let authManager = ServiceContainer.shared.authManager
///
/// // 로그인
/// try await authManager.logIn(request: LogInRequest(email: "user@example.com", password: "password"))
///
/// // 소셜 로그인
/// try await authManager.signInWith(.google)
///
/// // 로그아웃
/// await authManager.logOut()
/// ```
@MainActor
@Observable
final class AuthManager {
    // MARK: - Observable Properties

    /// 현재 로그인 상태
    /// - `true`: 사용자가 로그인된 상태
    /// - `false`: 로그아웃 상태 또는 세션 만료
    var isLoggedIn: Bool = false

    /// 세션 확인 진행 중 여부
    /// - 앱 시작 시 `true`로 시작하여 세션 확인 완료 후 `false`로 변경
    /// - 스플래시 화면 표시 여부를 결정하는 데 사용
    var isCheckingSession: Bool = true

    /// 현재 로그인한 사용자 정보
    /// - 로그인 성공 시 서버에서 받은 사용자 정보 저장
    /// - 로그아웃 시 `nil`로 초기화
    var currentUser: User?

    // MARK: - Private Properties

    /// OAuth 진행 중 여부를 추적하는 플래그
    /// - OAuth 진행 중에는 세션 체크를 건너뛰어 충돌 방지
    /// - `@ObservationIgnored`: UI 업데이트에 영향을 주지 않는 내부 상태
    @ObservationIgnored
    private var isOAuthInProgress: Bool = false

    /// Apple Sign In delegate 강한 참조
    /// - ASAuthorizationController.delegate는 weak 참조이므로 별도 보유 필요
    /// - 인증 완료/실패 시 nil로 해제
    @ObservationIgnored
    private var appleSignInDelegate: AppleSignInDelegate?

    // MARK: - Dependencies

    /// 인증 관련 API 호출을 담당하는 서비스
    private let authService: AuthServiceProtocol

    /// Keychain 매니저 (토큰 저장/조회)
    private let keychain: KeychainManager

    /// 보안 쿠키 저장소
    private let cookieStorage: SecureCookieStorage

    /// 오프라인 캐시 매니저
    private let cacheManager: CacheManager

    // MARK: - Initialization

    /// 이니셜라이저 (의존성 주입)
    /// - Parameters:
    ///   - authService: 인증 서비스
    ///   - keychain: Keychain 매니저
    ///   - cookieStorage: 보안 쿠키 저장소
    ///   - cacheManager: 오프라인 캐시 매니저
    init(
        authService: AuthServiceProtocol,
        keychain: KeychainManager,
        cookieStorage: SecureCookieStorage,
        cacheManager: CacheManager
    ) {
        self.authService = authService
        self.keychain = keychain
        self.cookieStorage = cookieStorage
        self.cacheManager = cacheManager
    }

    // MARK: - Session Management

    /// 앱 시작 시 기존 세션을 확인하여 자동 로그인 처리
    ///
    /// 서버의 `/me` 엔드포인트를 호출하여 저장된 토큰의 유효성을 검증합니다.
    /// 토큰이 유효하면 사용자 정보를 가져오고, 만료되었으면 로그아웃 상태로 설정합니다.
    ///
    /// - Note: OAuth 진행 중에는 세션 체크를 건너뜁니다 (콜백 처리 중 충돌 방지)
    func checkSession() {
        // OAuth 진행 중이면 세션 체크 건너뛰기
        guard !isOAuthInProgress else {
            Log.custom(category: "Auth", "Skipping session check - OAuth in progress")
            return
        }

        Log.custom(category: "Auth", "Checking session...")

        Task {
            defer { isCheckingSession = false }

            do {
                // 저장된 토큰으로 사용자 정보 조회 시도
                let user = try await authService.me()
                currentUser = user
                isLoggedIn = true
                cacheManager.saveUser(user)
            } catch let error as NetworkError {
                switch error {
                case .noConnection, .timeout:
                    // 오프라인: 캐싱된 데이터로 폴백
                    if let cachedUser = cacheManager.loadUser() {
                        Log.custom(category: "Auth", "Offline - using cached user: \(cachedUser.email)")
                        currentUser = cachedUser
                        isLoggedIn = true
                    } else {
                        currentUser = nil
                        isLoggedIn = false
                    }
                default:
                    // 서버 에러 (401 등): 로그아웃 처리
                    currentUser = nil
                    isLoggedIn = false
                }
            } catch {
                currentUser = nil
                isLoggedIn = false
            }
        }
    }

    /// 현재 세션을 종료하고 로그아웃 처리
    ///
    /// 서버에 로그아웃 요청을 보내고, 로컬의 모든 민감한 데이터를 안전하게 삭제합니다.
    /// 서버 요청 실패 시에도 로컬 상태는 항상 초기화됩니다.
    ///
    /// 삭제 대상:
    /// - 서버 세션 (로그아웃 API 호출)
    /// - Keychain에 저장된 쿠키/토큰
    /// - 메모리의 사용자 정보
    func logOut() async {
        do {
            // 서버에 로그아웃 요청 (토큰 무효화)
            try await authService.logOut()
        } catch {
            Log.error("Logout error:", error.localizedDescription)
        }

        // 로컬 민감 데이터 안전 삭제
        clearSensitiveData()
    }

    // MARK: - Force Logout

    /// 토큰 무효/세션 만료로 인한 강제 로그아웃 처리
    ///
    /// NetworkManager에서 401 응답 시 리프레시 실패 또는 세션 무효 판정 시 호출됩니다.
    /// 서버 로그아웃 API는 호출하지 않고 로컬 데이터만 삭제합니다.
    func handleForceLogout() {
        Log.custom(category: "Auth", "Force logout triggered - clearing local data")
        clearSensitiveData()
    }

    // MARK: - Private Token Methods

    /// 인증 응답에서 토큰을 Keychain에 저장하고 사용자 상태 업데이트
    ///
    /// - Throws: Keychain 저장 실패 시 에러 전파 (토큰 미저장 상태로 로그인 처리 방지)
    private func handleAuthResponse(_ response: AuthResponse) throws {
        try keychain.save(key: .accessToken, value: response.accessToken)
        try keychain.save(key: .refreshToken, value: response.refreshToken)

        currentUser = response.user
        isLoggedIn = true
        cacheManager.saveUser(response.user)
    }

    // MARK: - Private Security Methods

    /// 모든 로컬 민감 데이터를 안전하게 삭제
    private func clearSensitiveData() {
        // 메모리 상태 초기화
        currentUser = nil
        isLoggedIn = false

        // 보안 쿠키 저장소 삭제 (Keychain + 메모리)
        cookieStorage.deleteAllCookies()

        // Keychain의 모든 인증 데이터 삭제 (토큰 포함)
        keychain.deleteAll()

        // 오프라인 캐시 삭제
        cacheManager.clearAll()

        Log.custom(category: "Security", "All sensitive data cleared on logout")
    }

    // MARK: - Email Authentication

    /// 이메일과 비밀번호로 로그인
    ///
    /// - Parameter request: 이메일과 비밀번호가 포함된 로그인 요청
    /// - Throws: 인증 실패 시 `NetworkError` 발생, 취소 시 `NetworkError.cancelled` 발생
    func logIn(request: LogInRequest) async throws {
        try Task.checkCancellation()
        let response = try await authService.logIn(request)
        try Task.checkCancellation()
        try handleAuthResponse(response)
    }

    /// 이메일과 비밀번호로 회원가입
    ///
    /// - Parameter request: 이메일, 비밀번호, 이름 등이 포함된 회원가입 요청
    /// - Throws: 회원가입 실패 시 `NetworkError` 발생 (이메일 중복 등), 취소 시 `NetworkError.cancelled` 발생
    func signUp(request: SignUpRequest) async throws {
        try Task.checkCancellation()
        let response = try await authService.signUp(request)
        try Task.checkCancellation()
        try handleAuthResponse(response)
    }

    // MARK: - Social Authentication

    /// 소셜 제공자를 통한 소셜 로그인
    ///
    /// - Parameter provider: 소셜 로그인 제공자 (.google, .apple, .native)
    /// - Throws: 인증 취소 또는 실패 시 `NetworkError` 발생, Task 취소 시 `NetworkError.cancelled` 발생
    ///
    /// - Note:
    ///   - `.native`: iOS 네이티브 Apple Sign In 사용
    ///   - `.google`, `.apple`: 웹 기반 OAuth 플로우 사용
    func signInWith(_ provider: SocialProvider) async throws {
        try Task.checkCancellation()

        isOAuthInProgress = true
        defer { isOAuthInProgress = false }

        switch provider {
        case .native:
            try await signInWithAppleNative()
        case .google, .apple:
            try await signInWithWebOAuth(provider: provider)
        }
    }

    // MARK: - Web OAuth (Private)

    /// 웹 기반 OAuth 인증 플로우 실행
    ///
    /// ASWebAuthenticationSession을 사용하여 시스템 브라우저에서 OAuth 인증을 진행합니다.
    /// 인증 완료 후 콜백 URL에서 인증 코드를 추출하여 서버에서 토큰으로 교환합니다.
    ///
    /// - Parameter provider: OAuth 제공자 (.google 또는 .apple)
    /// - Throws: URL 생성 실패, 인증 취소, 토큰 교환 실패, Task 취소 시 에러 발생
    private func signInWithWebOAuth(provider: SocialProvider) async throws {
        let endpoint = APIEndpoint.oauth(provider)

        guard let authURL = URL(string: endpoint.url) else {
            throw NetworkError.invalidURL
        }

        // 1. 웹 브라우저에서 OAuth 인증 진행
        let callbackURL = try await startWebOAuthSession(url: authURL)
        try Task.checkCancellation()
        // 2. 콜백 URL에서 인증 코드 추출
        let code = try extractCode(from: callbackURL)
        // 3. 인증 코드를 서버에서 액세스 토큰으로 교환
        let response = try await authService.exchange(ExchangeRequest(code: code))
        try Task.checkCancellation()
        try handleAuthResponse(response)
    }

    /// 시스템 브라우저를 사용한 OAuth 세션 시작
    ///
    /// - Parameter url: OAuth 인증 시작 URL
    /// - Returns: 인증 완료 후 리다이렉트된 콜백 URL
    /// - Throws: 사용자 취소 또는 인증 실패 시 에러 발생
    private func startWebOAuthSession(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: APIConfiguration.callbackURLScheme
            ) { callbackURL, error in
                // 에러 처리
                if let error = error {
                    if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                        // 사용자가 로그인 취소
                        continuation.resume(throwing: NetworkError.custom(Localized.Error.errorLoginCancelled))
                    } else {
                        continuation.resume(throwing: NetworkError.unknown(error))
                    }
                    return
                }

                // 콜백 URL 검증
                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: NetworkError.custom(Localized.Error.errorOauthCallbackFailed))
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            // 프레젠테이션 설정
            session.presentationContextProvider = PresentationContextProvider.shared
            // false: 기존 로그인 세션 유지 (자동 로그인)
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    /// 콜백 URL에서 인증 코드 추출
    ///
    /// - Parameter callbackURL: OAuth 서버에서 리다이렉트된 콜백 URL
    /// - Returns: URL 쿼리 파라미터에서 추출한 인증 코드
    /// - Throws: 코드 파라미터가 없으면 에러 발생
    private func extractCode(from callbackURL: URL) throws -> String {
        Log.custom(category: "Auth", "OAuth callback received")

        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw NetworkError.custom(Localized.Error.errorOauthCallbackFailed)
        }

        return code
    }

    // MARK: - Apple Sign In (Private)

    /// 네이티브 Apple Sign In 플로우 실행
    ///
    /// iOS 네이티브 UI를 사용하여 Apple ID로 인증합니다.
    /// Face ID/Touch ID 통합으로 더 빠르고 안전한 인증을 제공합니다.
    ///
    /// - Throws: 인증 취소 또는 실패, Task 취소 시 에러 발생
    private func signInWithAppleNative() async throws {
        // 1. Apple 인증 UI 표시 및 credential 획득
        let credential = try await startAppleSignIn()
        try Task.checkCancellation()
        // 2. credential에서 서버 요청용 데이터 추출
        let request = try createAppleSignInRequest(from: credential)
        // 3. 서버에 Apple 인증 정보 전송 및 사용자 정보 수신
        let response = try await authService.appleSignIn(request)
        try Task.checkCancellation()
        try handleAuthResponse(response)
    }

    /// Apple Sign In 인증 UI 표시 및 결과 대기
    ///
    /// - Returns: Apple에서 제공한 인증 credential (사용자 정보, 토큰 포함)
    /// - Throws: 사용자 취소 또는 인증 실패 시 에러 발생
    private func startAppleSignIn() async throws -> ASAuthorizationAppleIDCredential {
        try await withCheckedThrowingContinuation { continuation in
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            // 요청할 사용자 정보 범위 (이름, 이메일)
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInDelegate { [weak self] in
                self?.appleSignInDelegate = nil
            }
            delegate.continuation = continuation

            // delegate를 인스턴스 프로퍼티로 보유하여 인증 완료까지 해제 방지
            self.appleSignInDelegate = delegate
            controller.delegate = delegate
            controller.presentationContextProvider = PresentationContextProvider.shared
            controller.performRequests()
        }
    }

    /// Apple credential에서 서버 요청용 데이터 생성
    ///
    /// - Parameter credential: Apple에서 받은 인증 credential
    /// - Returns: 서버 API 호출용 요청 객체
    /// - Throws: identity token 추출 실패 시 에러 발생
    ///
    /// - Note: email과 fullName은 최초 인증 시에만 제공됨
    ///   이후 로그인에서는 nil로 전달됨
    private func createAppleSignInRequest(from credential: ASAuthorizationAppleIDCredential) throws -> AppleSignInRequest {
        // identity token을 문자열로 변환
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw NetworkError.custom(Localized.Error.errorOauthCallbackFailed)
        }

        Log.custom(category: "Auth", "Apple Sign In - User ID:", String(credential.user.prefix(8)) + "****")
        Log.custom(category: "Auth", "Apple Sign In - Email:", credential.email != nil ? "provided" : "nil")
        Log.custom(category: "Auth", "Apple Sign In - Full Name:", credential.fullName != nil ? "provided" : "nil")

        return AppleSignInRequest(
            identityToken: tokenString,
            user: credential.user,
            email: credential.email,
            fullName: credential.fullName.map {
                .init(givenName: $0.givenName, familyName: $0.familyName)
            }
        )
    }
}

// MARK: - Apple Sign In Delegate
/// Apple Sign In 인증 결과를 처리하는 델리게이트
///
/// ASAuthorizationController의 비동기 결과를 Swift Concurrency의
/// CheckedContinuation으로 브릿징하여 async/await 패턴으로 사용 가능하게 합니다.
private final class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate {
    /// 인증 결과를 전달할 continuation
    var continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>?

    /// 인증 완료 시 AuthManager의 강한 참조를 해제하는 클로저
    private let onComplete: () -> Void

    /// - Parameter onComplete: 인증 완료/실패 시 호출되어 delegate 참조를 해제
    init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }

    /// 인증 성공 시 호출
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        defer { onComplete() }
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation?.resume(returning: credential)
        } else {
            continuation?.resume(throwing: NetworkError.custom(Localized.Error.errorOauthCallbackFailed))
        }
    }

    /// 인증 실패 시 호출
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        defer { onComplete() }
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            // 사용자가 인증 취소
            continuation?.resume(throwing: NetworkError.custom(Localized.Error.errorLoginCancelled))
        } else {
            continuation?.resume(throwing: NetworkError.unknown(error))
        }
    }
}

// MARK: - Presentation Context Provider
/// OAuth 및 Apple Sign In에서 인증 UI를 표시할 윈도우를 제공하는 클래스
///
/// ASWebAuthenticationSession과 ASAuthorizationController 모두에서
/// 공통으로 사용하여 인증 팝업이 표시될 앵커 윈도우를 지정합니다.
private final class PresentationContextProvider: NSObject,
    ASWebAuthenticationPresentationContextProviding,
    ASAuthorizationControllerPresentationContextProviding {

    /// 공유 인스턴스
    static let shared = PresentationContextProvider()

    private override init() {
        super.init()
    }

    /// 현재 활성화된 윈도우를 반환
    /// 모든 UIWindowScene을 탐색하여 key window → 첫 번째 visible window 순으로 찾음
    private var presentationAnchor: ASPresentationAnchor {
        let windowScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        // key window 우선 탐색
        for scene in windowScenes {
            if let keyWindow = scene.windows.first(where: { $0.isKeyWindow }) {
                return keyWindow
            }
        }

        // key window가 없으면 첫 번째 윈도우 반환
        if let firstWindow = windowScenes.first?.windows.first {
            return firstWindow
        }

        Log.error("No valid window found for presentation anchor")
        return ASPresentationAnchor()
    }

    /// ASWebAuthenticationSession용 프레젠테이션 앵커 제공
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        presentationAnchor
    }

    /// ASAuthorizationController용 프레젠테이션 앵커 제공
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        presentationAnchor
    }
}
