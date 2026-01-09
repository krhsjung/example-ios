//
//  APIEndpoint.swift
//  example
//
//  Path: Core/Networking/APIEndpoint.swift
//  Created by 정희석 on 12/29/25.
//

import Foundation

// MARK: - API Configuration
struct APIConfiguration {
    static let baseURL = "https://hsjung.asuscomm.com/example/nestjs/development/api"
    static let timeout: TimeInterval = 30.0
}

// MARK: - API Endpoint
enum APIEndpoint {
    // Auth
    case logIn
    case exchange
    case logOut
    case signUp
    case oauth(_ snsProvider: SnsProvider)
    case appleSignIn

    // User
    case me

    // Custom endpoint
    case custom(_ path: String)

    var path: String {
        switch self {
        // Auth
        case .logIn:
            return "/auth/login"
        case .exchange:
            return "/auth/exchange"
        case .logOut:
            return "/auth/logout"
        case .signUp:
            return "/user"
        case .oauth(let snsProvider):
            return "/auth/\(snsProvider.rawValue)?flow=ios&prompt=select_account"
        case .appleSignIn:
            return "/auth/apple/native"

        // User
        case .me:
            return "/auth/me"

        // Custom
        case .custom(let path):
            return path
        }
    }
    
    var url: String {
        return APIConfiguration.baseURL + path
    }
}
