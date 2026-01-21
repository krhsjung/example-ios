//
//  AuthProvider.swift
//  example
//
//  Path: Domain/Models/Auth/AuthProvider.swift
//  Created by 정희석 on 12/29/25.
//

import Foundation

// MARK: - SNS Provider
/// SNS 로그인 제공자
enum SnsProvider: String, Codable, CaseIterable {
    case google = "google"
    case apple = "apple"
    case native = "native"

    /// 버튼에 표시될 제목
    var title: String {
        switch self {
        case .google:
            return Localized.Auth.oauthGoogle
        case .apple:
            return Localized.Auth.oauthApple
        case .native:
            return Localized.Auth.oauthApple + "(native)"
        }
    }

    /// 버튼 아이콘 이름
    var icon: String {
        switch self {
        case .google:
            return "google"
        case .apple, .native:
            return "apple"
        }
    }
}

// MARK: - Login Provider
/// 로그인 제공자 (이메일 + SNS)
enum LoginProvider: String, Codable {
    case email = "email"
    case google = "google"
    case apple = "apple"
}
