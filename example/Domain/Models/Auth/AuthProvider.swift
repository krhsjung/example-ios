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
enum SnsProvider: String, Codable {
    case google = "google"
    case apple = "apple"
    case native = "native"
}

// MARK: - Login Provider
/// 로그인 제공자 (이메일 + SNS)
enum LoginProvider: String, Codable {
    case email = "email"
    case google = "google"
    case apple = "apple"
}
