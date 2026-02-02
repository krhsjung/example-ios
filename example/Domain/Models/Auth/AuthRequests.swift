//
//  AuthRequests.swift
//  example
//
//  Path: Domain/Models/Auth/AuthRequests.swift
//  Created by 정희석 on 1/7/26.
//

import Foundation

// MARK: - Login Request
struct LogInRequest: Codable {
    let email: String
    let password: String
    let provider: LoginProvider

    enum CodingKeys: String, CodingKey {
        case email
        case password
        case provider
    }

    init(email: String, password: String, provider: LoginProvider = .email) {
        self.email = email
        self.password = password
        self.provider = provider
    }
}

// MARK: - Sign Up Request
struct SignUpRequest: Codable {
    let email: String
    let password: String
    let name: String
    let provider: LoginProvider

    enum CodingKeys: String, CodingKey {
        case email
        case password
        case name
        case provider
    }

    init(email: String, password: String, name: String, provider: LoginProvider = .email) {
        self.email = email
        self.password = password
        self.name = name
        self.provider = provider
    }
}

// MARK: - Exchange Request
struct ExchangeRequest: Codable {
    let code: String
}

// MARK: - Refresh Request
struct RefreshRequest: Codable {
    let refreshToken: String
}

// MARK: - Auth Response
/// 인증 API 공통 응답 (로그인, 회원가입, OAuth, Apple Sign In)
struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let user: User
}

// MARK: - Apple Sign In Request
struct AppleSignInRequest: Codable {
    let identityToken: String
    let user: String
    let email: String?
    let fullName: FullName?

    struct FullName: Codable {
        let givenName: String?
        let familyName: String?
    }
}
