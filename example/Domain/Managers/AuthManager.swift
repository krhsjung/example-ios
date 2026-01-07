//
//  AuthManager.swift
//  example
//
//  Path: Domain/Managers/AuthManager.swift
//  Created by 정희석 on 1/6/26.
//

import SwiftUI
import Combine
import AuthenticationServices

@MainActor
final class AuthManager: ObservableObject {
    // MARK: - Singleton
    static let shared = AuthManager()

    // MARK: - Published Properties
    @Published var isLoggedIn: Bool = false
    @Published var isCheckingSession: Bool = true
    @Published var currentUser: User?

    // MARK: - Private Properties
    private var isOAuthInProgress: Bool = false

    // MARK: - Dependencies
    private let authService: AuthServiceProtocol

    // MARK: - OAuth Configuration
    private let callbackURLScheme = "example"

    // MARK: - Initialization
    private init(authService: AuthServiceProtocol? = nil) {
        self.authService = authService ?? AuthService.shared
    }

    // MARK: - Public Methods

    /// 세션 확인 (앱 시작 시 호출)
    func checkSession() {
        // OAuth 진행 중에는 세션 확인 스킵
        guard !isOAuthInProgress else {
            #if DEBUG
            print("🔐 Skipping session check - OAuth in progress")
            #endif
            return
        }

        #if DEBUG
        print("🔐 Checking session...")
        #endif

        Task {
            defer { isCheckingSession = false }

            do {
                currentUser = try await authService.me()
                isLoggedIn = true
            } catch {
                currentUser = nil
                isLoggedIn = false
            }
        }
    }

    /// 로그인
    func logIn(request: LogInRequest) async throws {
        let user = try await authService.logIn(request: request)
        currentUser = user
        isLoggedIn = true
    }

    /// 회원가입
    func signUp(request: SignUpRequest) async throws {
        let user = try await authService.signUp(request: request)
        currentUser = user
        isLoggedIn = true
    }

    /// 로그아웃
    func logOut() async {
        do {
            try await authService.logOut()
        } catch {
            #if DEBUG
            print("Logout error: \(error.localizedDescription)")
            #endif
        }
        currentUser = nil
        isLoggedIn = false
    }
    
    /// SNS 로그인 (OAuth)
    func signInWith(_ provider: SnsProvider) async throws {
        isOAuthInProgress = true
        defer { isOAuthInProgress = false }

        let endpoint = APIEndpoint.oauth(provider)

        guard let authURL = URL(string: endpoint.url) else {
            throw NetworkError.invalidURL
        }

        let callbackURL = try await startOAuthSession(url: authURL)

        try await handleOAuthCallback(url: callbackURL)
    }

    // MARK: - Private Methods

    /// ASWebAuthenticationSession을 사용한 OAuth 인증
    private func startOAuthSession(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackURLScheme
            ) { callbackURL, error in
                if let error = error {
                    if (error as? ASWebAuthenticationSessionError)?.code == .canceledLogin {
                        continuation.resume(throwing: NetworkError.custom(Localized.Error.errorLoginCancelled))
                    } else {
                        continuation.resume(throwing: NetworkError.unknown(error))
                    }
                    return
                }

                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: NetworkError.custom(Localized.Error.errorOauthCallbackFailed))
                    return
                }

                continuation.resume(returning: callbackURL)
            }

            session.presentationContextProvider = OAuthPresentationContextProvider.shared
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }

    /// OAuth 콜백 URL 처리 (토큰 추출 및 로그인 완료)
    private func handleOAuthCallback(url: URL) async throws {
        // 콜백 URL에서 code 파싱
        // 예: example://oauth/callback?success=true&code=a86140fe-edd9-413d-bd80-02335a5736f0
        #if DEBUG
        print("🔐 OAuth callback URL: \(url)")
        #endif

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw NetworkError.custom(Localized.Error.errorOauthCallbackFailed)
        }
        
        // code를 서버에 전달하여 사용자 정보 가져오기
        currentUser = try await authService.exchange(code)
        isLoggedIn = true
    }
}

// MARK: - OAuth Presentation Context Provider
final class OAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuthPresentationContextProvider()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
