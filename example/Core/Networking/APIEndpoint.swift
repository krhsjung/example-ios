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

    /// 연결 타임아웃 (초) - TCP 연결 수립까지의 제한 시간
    static let connectTimeout: TimeInterval = 10.0
    /// 요청 타임아웃 (초) - 개별 요청의 제한 시간
    static let requestTimeout: TimeInterval = 30.0
    /// 리소스 타임아웃 (초) - 전체 리소스 전송의 제한 시간
    static let resourceTimeout: TimeInterval = 60.0

    /// SSL 피닝 대상 도메인
    static let pinnedDomain = "hsjung.asuscomm.com"

    /// SSL 피닝 공개 키 해시 (SHA-256, Base64)
    ///
    /// 서버 인증서의 공개 키 해시를 설정합니다.
    /// 빈 배열일 경우 피닝이 비활성화됩니다 (개발 환경).
    ///
    /// 해시 생성 방법:
    /// ```bash
    /// openssl s_client -connect hsjung.asuscomm.com:443 2>/dev/null | \
    ///   openssl x509 -pubkey -noout | \
    ///   openssl pkey -pubin -outform DER | \
    ///   openssl dgst -sha256 -binary | base64
    /// ```
    ///
    /// - Important: 프로덕션 배포 전 반드시 실제 해시를 설정하세요.
    static let pinnedKeyHashes: [String] = [
        // TODO: 프로덕션 서버 공개 키 해시 추가
        // "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=" // 백업 키
    ]
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
            return "/auth/register"
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
