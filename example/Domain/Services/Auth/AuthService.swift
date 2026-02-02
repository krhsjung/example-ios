//
//  AuthService.swift
//  example
//
//  Path: Domain/Services/Auth/AuthService.swift
//  Created by 정희석 on 12/29/25.
//

import Foundation
import CryptoKit
import AuthenticationServices

// MARK: - Auth Service Protocol
protocol AuthServiceProtocol {
    func logIn(_ request: LogInRequest) async throws -> AuthResponse
    func exchange(_ request: ExchangeRequest) async throws -> AuthResponse
    func appleSignIn(_ request: AppleSignInRequest) async throws -> AuthResponse
    func signUp(_ request: SignUpRequest) async throws -> AuthResponse
    func me() async throws -> User
    func logOut() async throws
}

// MARK: - Auth Service
final class AuthService: AuthServiceProtocol {
    static let shared = AuthService()
    
    private let networkManager: NetworkManagerProtocol

    private init(networkManager: NetworkManagerProtocol = NetworkManager.shared) {
        self.networkManager = networkManager
    }

    func logIn(_ request: LogInRequest) async throws -> AuthResponse {

        // 해싱된 비밀번호로 새로운 요청 생성
        let hashedRequest = LogInRequest(
            email: request.email,
            password: hashPassword(request.password),
            provider: request.provider
        )

        return try await networkManager.post(endpoint: .logIn, body: hashedRequest)
    }

    func exchange(_ request: ExchangeRequest) async throws -> AuthResponse {
        return try await networkManager.post(endpoint: .exchange, body: request)
    }

    func appleSignIn(_ request: AppleSignInRequest) async throws -> AuthResponse {
        return try await networkManager.post(endpoint: .appleSignIn, body: request)
    }

    func signUp(_ request: SignUpRequest) async throws -> AuthResponse {

        // 해싱된 비밀번호로 새로운 요청 생성
        let hashedRequest = SignUpRequest(
            email: request.email,
            password: hashPassword(request.password),
            name: request.name,
            provider: request.provider
        )

        return try await networkManager.post(endpoint: .signUp, body: hashedRequest)
    }

    func me() async throws -> User {
        return try await networkManager.get(endpoint: .me)
    }

    func logOut() async throws {
        try await networkManager.post(endpoint: .logOut)
    }

    // MARK: - Private Methods
    
    /// 비밀번호를 SHA-512로 해싱하여 전송
    /// - Note: 서버에서 Argon2로 2차 해싱 후 저장함. 클라이언트 SHA-512는 평문 전송 방지 목적.
    private func hashPassword(_ password: String) -> String {
        guard let data = password.data(using: .utf8) else {
            return password
        }
        
        let hashed = SHA512.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
