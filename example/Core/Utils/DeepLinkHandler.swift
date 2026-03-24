//
//  DeepLinkHandler.swift
//  example
//
//  Path: Core/Utils/DeepLinkHandler.swift
//

import Foundation

/// 딥링크 목적지
enum DeepLinkTarget: Equatable {
    /// 회원가입 화면
    case signup
}

/// 딥링크 URL을 파싱하여 앱 내 네비게이션 목적지로 변환
struct DeepLinkHandler {

    /// URL을 파싱하여 딥링크 목적지를 반환
    ///
    /// 지원하는 URL 형식:
    /// - Universal Link: `https://domain.com/link/signup`
    /// - Custom Scheme: `example://signup`
    ///
    /// - Parameter url: 처리할 URL
    /// - Returns: 매칭되는 딥링크 목적지, 없으면 nil
    static func handle(_ url: URL) -> DeepLinkTarget? {
        // Universal Link: https://domain.com/link/signup
        if url.scheme == "https" || url.scheme == "http" {
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return resolve(path: path.replacingOccurrences(of: "link/", with: ""))
        }

        // Custom Scheme: example://signup
        if let host = url.host() {
            return resolve(path: host)
        }

        return nil
    }

    /// 경로 문자열을 딥링크 목적지로 변환
    private static func resolve(path: String) -> DeepLinkTarget? {
        switch path {
        case "signup":
            return .signup
        default:
            return nil
        }
    }
}
