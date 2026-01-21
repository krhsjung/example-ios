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
/// // 로그인
/// try await AuthManager.shared.logIn(request: LogInRequest(email: "user@example.com", password: "password"))
///
/// // SNS 로그인
/// try await AuthManager.shared.signInWith(.google)
///
/// // 로그아웃
/// await AuthManager.shared.logOut()
/// ```
@MainActor
@Observable
final class AuthManager {
    // MARK: - Singleton

    /// 공유 인스턴스
    static let shared = AuthManager()

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

    // MARK: - Dependencies

    /// 인증 관련 API 호출을 담당하는 서비스
    private let authService: AuthServiceProtocol

    // MARK: - Configuration

    /// OAuth 콜백 URL 스킴
    /// - Info.plist의 URL Schemes와 일치해야 함
    /// - 서버에서 인증 완료 후 앱으로 리다이렉트할 때 사용
    private let callbackURLScheme = "example"

    // MARK: - Initialization

    /// 프라이빗 이니셜라이저 (싱글톤 패턴)
    /// - Parameter authService: 인증 서비스 (테스트 시 mock 주입 가능)
    private init(authService: AuthServiceProtocol? = nil) {
        self.authService = authService ?? AuthService.shared
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
                currentUser = try await authService.me()
                isLoggedIn = true
            } catch {
                // 토큰 만료 또는 네트워크 오류 시 로그아웃 상태로 설정
                currentUser = nil
                isLoggedIn = false
            }
        }
    }

    /// 현재 세션을 종료하고 로그아웃 처리
    ///
    /// 서버에 로그아웃 요청을 보내고, 로컬 상태를 초기화합니다.
    /// 서버 요청 실패 시에도 로컬 상태는 항상 초기화됩니다.
    func logOut() async {
        do {
            // 서버에 로그아웃 요청 (토큰 무효화)
            try await authService.logOut()
        } catch {
            Log.error("Logout error:", error.localizedDescription)
        }
        // 서버 요청 성공/실패와 관계없이 로컬 상태 초기화
        currentUser = nil
        isLoggedIn = false
    }

    // MARK: - Email Authentication

    /// 이메일과 비밀번호로 로그인
    ///
    /// - Parameter request: 이메일과 비밀번호가 포함된 로그인 요청
    /// - Throws: 인증 실패 시 `NetworkError` 발생, 취소 시 `NetworkError.cancelled` 발생
    func logIn(request: LogInRequest) async throws {
        try Task.checkCancellation()
        let user = try await authService.logIn(request)
        try Task.checkCancellation()
        currentUser = user
        isLoggedIn = true
    }

    /// 이메일과 비밀번호로 회원가입
    ///
    /// - Parameter request: 이메일, 비밀번호, 이름 등이 포함된 회원가입 요청
    /// - Throws: 회원가입 실패 시 `NetworkError` 발생 (이메일 중복 등), 취소 시 `NetworkError.cancelled` 발생
    func signUp(request: SignUpRequest) async throws {
        try Task.checkCancellation()
        let user = try await authService.signUp(request)
        try Task.checkCancellation()
        currentUser = user
        isLoggedIn = true
    }

    // MARK: - Social Authentication

    /// SNS 제공자를 통한 소셜 로그인
    ///
    /// - Parameter provider: 소셜 로그인 제공자 (.google, .apple, .native)
    /// - Throws: 인증 취소 또는 실패 시 `NetworkError` 발생, Task 취소 시 `NetworkError.cancelled` 발생
    ///
    /// - Note:
    ///   - `.native`: iOS 네이티브 Apple Sign In 사용
    ///   - `.google`, `.apple`: 웹 기반 OAuth 플로우 사용
    func signInWith(_ provider: SnsProvider) async throws {
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
    private func signInWithWebOAuth(provider: SnsProvider) async throws {
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
        currentUser = try await authService.exchange(ExchangeRequest(code: code))
        try Task.checkCancellation()
        isLoggedIn = true
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
                callbackURLScheme: callbackURLScheme
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
        Log.custom(category: "Auth", "OAuth callback URL:", callbackURL)

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
        currentUser = try await authService.appleSignIn(request)
        try Task.checkCancellation()
        isLoggedIn = true
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
            let delegate = AppleSignInDelegate(continuation: continuation)

            // delegate를 controller에 연결하여 메모리 해제 방지
            // (controller가 해제되면 delegate도 함께 해제되도록)
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)

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

        Log.custom(category: "Auth", "Apple Sign In - User ID:", credential.user)
        Log.custom(category: "Auth", "Apple Sign In - Email:", credential.email ?? "nil")
        Log.custom(category: "Auth", "Apple Sign In - Full Name:", credential.fullName?.givenName ?? "nil", credential.fullName?.familyName ?? "nil")

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
    private let continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>

    /// - Parameter continuation: 인증 완료/실패 시 결과를 전달할 continuation
    init(continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>) {
        self.continuation = continuation
    }

    /// 인증 성공 시 호출
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            continuation.resume(returning: credential)
        } else {
            continuation.resume(throwing: NetworkError.custom(Localized.Error.errorOauthCallbackFailed))
        }
    }

    /// 인증 실패 시 호출
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            // 사용자가 인증 취소
            continuation.resume(throwing: NetworkError.custom(Localized.Error.errorLoginCancelled))
        } else {
            continuation.resume(throwing: NetworkError.unknown(error))
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
    /// - 앱의 첫 번째 UIWindowScene에서 첫 번째 윈도우를 찾음
    /// - 찾지 못하면 빈 윈도우 반환 (폴백)
    private var presentationAnchor: ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
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
