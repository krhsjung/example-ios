//
//  SecureCookieStorage.swift
//  example
//
//  Path: Core/Security/SecureCookieStorage.swift
//  Created by Claude on 1/29/26.
//

import Foundation

// MARK: - Secure Cookie Storage
/// Keychain 기반의 안전한 쿠키 저장소
///
/// 기본 HTTPCookieStorage 대신 Keychain에 쿠키를 저장하여 보안을 강화합니다.
/// Android의 PersistentCookieJar와 동일한 역할을 합니다.
///
/// 주요 기능:
/// - 메모리 캐시 + Keychain 영속 저장 (이중 레이어)
/// - 쿠키 만료 자동 관리
/// - 로그아웃 시 안전한 삭제
///
/// 사용 예시:
/// ```swift
/// // 쿠키 저장 (응답 헤더에서)
/// SecureCookieStorage.shared.saveCookies(from: httpResponse, for: url)
///
/// // 쿠키 적용 (요청 헤더에)
/// let headers = SecureCookieStorage.shared.cookieHeaders(for: url)
/// ```
final class SecureCookieStorage: @unchecked Sendable {
    // MARK: - Singleton

    static let shared = SecureCookieStorage()

    // MARK: - Private Properties

    /// 메모리 캐시 (빠른 접근용)
    private var memoryCookies: [HTTPCookie] = []

    /// 스레드 안전을 위한 큐
    private let queue = DispatchQueue(label: "com.example.secureCookieStorage", attributes: .concurrent)

    /// Keychain 매니저
    private let keychain = KeychainManager.shared

    // MARK: - Initialization

    private init() {
        loadFromKeychain()
    }

    // MARK: - Public Methods

    /// HTTP 응답에서 쿠키를 추출하여 저장
    ///
    /// - Parameters:
    ///   - response: HTTP 응답 객체
    ///   - url: 요청 URL
    func saveCookies(from response: HTTPURLResponse, for url: URL) {
        guard let headerFields = response.allHeaderFields as? [String: String] else { return }

        let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: url)
        guard !cookies.isEmpty else { return }

        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }

            for newCookie in cookies {
                // 기존 동일 쿠키 제거 후 새 쿠키 추가
                self.memoryCookies.removeAll { $0.name == newCookie.name && $0.domain == newCookie.domain }
                self.memoryCookies.append(newCookie)
            }

            // 만료된 쿠키 정리
            self.removeExpiredCookies()

            // Keychain에 비동기 저장
            self.saveToKeychain()
        }
    }

    /// 요청 URL에 대한 쿠키 헤더 생성
    ///
    /// - Parameter url: 요청 URL
    /// - Returns: 쿠키 헤더 딕셔너리 (["Cookie": "name=value; ..."])
    func cookieHeaders(for url: URL) -> [String: String] {
        var headers: [String: String] = [:]

        queue.sync {
            let validCookies = memoryCookies.filter { cookie in
                // 도메인 매칭
                guard url.host?.hasSuffix(cookie.domain.hasPrefix(".") ? String(cookie.domain.dropFirst()) : cookie.domain) == true else {
                    return false
                }
                // 경로 매칭
                guard url.path.hasPrefix(cookie.path) else {
                    return false
                }
                // 만료 확인
                if let expiresDate = cookie.expiresDate, expiresDate < Date() {
                    return false
                }
                // Secure 속성 확인
                if cookie.isSecure && url.scheme != "https" {
                    return false
                }
                return true
            }

            if !validCookies.isEmpty {
                let cookieString = validCookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
                headers["Cookie"] = cookieString
            }
        }

        return headers
    }

    /// 모든 쿠키 삭제 (로그아웃 시 호출)
    func deleteAllCookies() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self else { return }
            self.memoryCookies.removeAll()
            self.keychain.delete(key: .cookies)

            // 기본 HTTPCookieStorage도 정리
            if let cookies = HTTPCookieStorage.shared.cookies {
                for cookie in cookies {
                    HTTPCookieStorage.shared.deleteCookie(cookie)
                }
            }

            Log.custom(category: "Security", "All cookies deleted")
        }
    }

    /// 저장된 쿠키 존재 여부
    var hasCookies: Bool {
        queue.sync {
            return !memoryCookies.isEmpty
        }
    }

    // MARK: - Private Methods

    /// 만료된 쿠키 제거
    private func removeExpiredCookies() {
        let now = Date()
        memoryCookies.removeAll { cookie in
            if let expiresDate = cookie.expiresDate {
                return expiresDate < now
            }
            return false
        }
    }

    /// Keychain에 쿠키 저장
    private func saveToKeychain() {
        let cookieData = memoryCookies.compactMap { cookie -> [String: Any]? in
            return cookie.properties as? [String: Any]
        }

        guard let data = try? JSONSerialization.data(withJSONObject: cookieData) else {
            Log.error("Failed to serialize cookies for Keychain")
            return
        }

        do {
            try keychain.save(key: .cookies, data: data)
        } catch {
            Log.error("Failed to save cookies to Keychain:", error.localizedDescription)
        }
    }

    /// Keychain에서 쿠키 로드
    private func loadFromKeychain() {
        guard let data = keychain.loadData(key: .cookies) else { return }

        guard let cookieArrayData = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            Log.error("Failed to deserialize cookies from Keychain")
            return
        }

        let cookies = cookieArrayData.compactMap { properties -> HTTPCookie? in
            // JSONSerialization이 String 키를 반환하므로 HTTPCookiePropertyKey로 변환
            let cookieProperties = Dictionary(uniqueKeysWithValues: properties.map {
                (HTTPCookiePropertyKey($0.key), $0.value)
            })
            return HTTPCookie(properties: cookieProperties)
        }

        memoryCookies = cookies
        removeExpiredCookies()

        Log.custom(category: "Security", "Loaded \(memoryCookies.count) cookies from Keychain")
    }
}
