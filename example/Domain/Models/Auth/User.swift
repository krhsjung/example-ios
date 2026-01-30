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
    let idx: Int
    let name: String
    let email: String
    let picture: String?
    let provider: LoginProvider?
    let maxSessions: Int?

    var id: Int { idx }

    enum CodingKeys: String, CodingKey {
        case idx
        case email
        case name
        case picture
        case provider
        case maxSessions
    }
}
