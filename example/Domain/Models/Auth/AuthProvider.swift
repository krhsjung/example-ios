//
//  AuthProvider.swift
//  example
//
//  Path: Domain/Models/Auth/AuthProvider.swift
//  Created by 정희석 on 12/29/25.
//

import Foundation

// MARK: - Social Provider
/// 소셜 로그인 제공자
enum SocialProvider: String, Codable, CaseIterable, Sendable {
    /// Google OAuth (ASWebAuthenticationSession 기반 웹 인증)
    case google = "google"
    /// Apple Sign In (ASWebAuthenticationSession 기반 웹 인증)
    case apple = "apple"
    /// Apple Sign In (ASAuthorizationAppleIDProvider 기반 네이티브 인증, Face ID/Touch ID 연동)
    case native = "native"
}

// MARK: - Login Provider
/// 로그인 제공자 (이메일 + 소셜)
enum LoginProvider: String, Codable, Sendable {
    case email = "email"
    case google = "google"
    case apple = "apple"
}
