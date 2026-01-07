//
//  User.swift
//  example
//
//  Path: Domain/Models/Auth/User.swift
//  Created by 정희석 on 12/29/25.
//

import Foundation

// MARK: - User Model
struct User: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let email: String
    let picture: String?
    let provider: LoginProvider?
    let maxSessions: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case picture
        case provider
        case maxSessions
    }
}
