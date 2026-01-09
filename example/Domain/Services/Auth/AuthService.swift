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
    func logIn(_ request: LogInRequest) async throws -> User
    func exchange(_ request: ExchangeRequest) async throws -> User
    func appleSignIn(_ request: AppleSignInRequest) async throws -> User
    func signUp(_ request: SignUpRequest) async throws -> User
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

    func logIn(_ request: LogInRequest) async throws -> User {
        
        // 해싱된 비밀번호로 새로운 요청 생성
        let hashedRequest = LogInRequest(
            email: request.email,
            password: hashPassword(request.password),
            provider: request.provider
        )
        
        return try await networkManager.post(
            endpoint: .logIn,
            body: hashedRequest,
            headers: nil
        )
    }
    
    func exchange(_ request: ExchangeRequest) async throws -> User {
        return try await networkManager.post(
            endpoint: .exchange,
            body: request,
            headers: nil
        )
    }
    
    func appleSignIn(_ request: AppleSignInRequest) async throws -> User {
        return try await networkManager.post(
            endpoint: .appleSignIn,
            body: request,
            headers: nil
        )
    }

    func signUp(_ request: SignUpRequest) async throws -> User {
        
        // 해싱된 비밀번호로 새로운 요청 생성
        let hashedRequest = SignUpRequest(
            email: request.email,
            password: hashPassword(request.password),
            name: request.name,
            provider: request.provider
        )
        
        return try await networkManager.post(
            endpoint: .signUp,
            body: hashedRequest,
            headers: nil
        )
    }
    
    func me() async throws -> User {
        return try await networkManager.get(
            endpoint: .me,
            headers: nil
        )
    }

    func logOut() async throws {
        return try await networkManager.post(
            endpoint: .logOut,
            body: nil,
            headers: nil
        )
    }

    // MARK: - Private Methods
    
    /// 비밀번호를 SHA-512로 해싱
    private func hashPassword(_ password: String) -> String {
        guard let data = password.data(using: .utf8) else {
            return password
        }
        
        let hashed = SHA512.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
