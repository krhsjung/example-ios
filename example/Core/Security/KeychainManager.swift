//
//  KeychainManager.swift
//  example
//
//  Path: Core/Security/KeychainManager.swift
//  Created by Claude on 1/29/26.
//

import Foundation
import Security

// MARK: - Keychain Manager
/// iOS Keychain을 사용한 안전한 데이터 저장 매니저
///
/// 민감한 데이터(토큰, 세션 정보 등)를 iOS Keychain에 안전하게 저장합니다.
/// Keychain은 앱 삭제 후에도 데이터가 유지되며, 하드웨어 수준의 암호화를 제공합니다.
///
/// 사용 예시:
/// ```swift
/// // 저장
/// try KeychainManager.shared.save(key: .accessToken, data: tokenData)
///
/// // 조회
/// let token: String? = KeychainManager.shared.load(key: .accessToken)
///
/// // 삭제
/// KeychainManager.shared.delete(key: .accessToken)
/// ```
final class KeychainManager: Sendable {
    // MARK: - Singleton

    static let shared = KeychainManager()

    // MARK: - Key
    /// Keychain 저장 키 정의
    enum Key: String {
        /// 쿠키 데이터 (서버 세션 쿠키)
        case cookies = "com.example.cookies"
        /// 마지막 인증 시간
        case lastAuthDate = "com.example.lastAuthDate"
    }

    // MARK: - Configuration

    /// Keychain 접근 서비스 식별자
    private let service: String

    // MARK: - Initialization

    private init(service: String = Bundle.main.bundleIdentifier ?? "com.example") {
        self.service = service
    }

    // MARK: - Public Methods

    /// Data를 Keychain에 저장
    ///
    /// - Parameters:
    ///   - key: 저장 키
    ///   - data: 저장할 데이터
    /// - Throws: Keychain 저장 실패 시 `KeychainError`
    @discardableResult
    func save(key: Key, data: Data) throws -> Bool {
        // 기존 항목 삭제 후 새로 저장
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            Log.error("Keychain save failed for key: \(key.rawValue), status: \(status)")
            throw KeychainError.saveFailed(status)
        }

        return true
    }

    /// String을 Keychain에 저장
    ///
    /// - Parameters:
    ///   - key: 저장 키
    ///   - value: 저장할 문자열
    /// - Throws: 인코딩 또는 Keychain 저장 실패 시 에러
    @discardableResult
    func save(key: Key, value: String) throws -> Bool {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        return try save(key: key, data: data)
    }

    /// Keychain에서 Data 조회
    ///
    /// - Parameter key: 조회 키
    /// - Returns: 저장된 데이터 (없으면 nil)
    func loadData(key: Key) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            return nil
        }

        return result as? Data
    }

    /// Keychain에서 String 조회
    ///
    /// - Parameter key: 조회 키
    /// - Returns: 저장된 문자열 (없으면 nil)
    func loadString(key: Key) -> String? {
        guard let data = loadData(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Keychain에서 항목 삭제
    ///
    /// - Parameter key: 삭제할 키
    @discardableResult
    func delete(key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// 모든 Keychain 항목 삭제
    ///
    /// 로그아웃 시 모든 민감한 데이터를 안전하게 제거합니다.
    func deleteAll() {
        Key.allCases.forEach { delete(key: $0) }
        Log.custom(category: "Security", "All keychain items deleted")
    }
}

// MARK: - Key CaseIterable
extension KeychainManager.Key: CaseIterable {}

// MARK: - Keychain Error
/// Keychain 작업 에러
enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Keychain save failed with status: \(status)"
        case .encodingFailed:
            return "Failed to encode data for Keychain"
        case .decodingFailed:
            return "Failed to decode data from Keychain"
        }
    }
}
