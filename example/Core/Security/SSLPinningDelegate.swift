//
//  SSLPinningDelegate.swift
//  example
//
//  Path: Core/Security/SSLPinningDelegate.swift
//  Created by Claude on 1/29/26.
//

import Foundation
import CryptoKit

// MARK: - SSL Pinning Delegate
/// SSL 인증서 피닝을 수행하는 URLSession Delegate
///
/// 서버의 공개 키(SPKI) 해시를 검증하여 MITM(중간자 공격)을 방지합니다.
/// 인증서 전체가 아닌 공개 키 해시를 고정하여 인증서 갱신에도 안정적으로 동작합니다.
///
/// - Note: 피닝 실패 시 연결이 거부되며, 디버그 빌드에서는 경고 로그가 출력됩니다.
final class SSLPinningDelegate: NSObject, URLSessionDelegate, Sendable {

    // MARK: - Configuration

    /// 고정할 공개 키의 SHA-256 해시 목록 (Base64 인코딩)
    ///
    /// openssl 명령어로 생성:
    /// ```bash
    /// openssl s_client -connect HOST:443 2>/dev/null | \
    ///   openssl x509 -pubkey -noout | \
    ///   openssl pkey -pubin -outform DER | \
    ///   openssl dgst -sha256 -binary | base64
    /// ```
    ///
    /// - Important: 최소 2개의 핀을 설정해야 합니다 (현재 인증서 + 백업)
    private let pinnedKeyHashes: [String]

    /// 피닝을 적용할 도메인
    private let pinnedDomain: String

    // MARK: - Initialization

    /// - Parameters:
    ///   - domain: SSL 피닝을 적용할 도메인 (예: "hsjung.asuscomm.com")
    ///   - keyHashes: 공개 키의 SHA-256 해시 (Base64 인코딩) 배열
    init(domain: String, keyHashes: [String]) {
        self.pinnedDomain = domain
        self.pinnedKeyHashes = keyHashes
        super.init()
    }

    // MARK: - URLSessionDelegate

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              challenge.protectionSpace.host == pinnedDomain,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            // 다른 인증 방식이거나 피닝 대상이 아닌 도메인 → 기본 처리
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // 피닝이 설정되지 않은 경우 기본 처리 (개발 환경 등)
        guard !pinnedKeyHashes.isEmpty else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // 서버 인증서 체인에서 공개 키 추출 및 검증
        if validateServerTrust(serverTrust) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            Log.error("SSL Pinning failed for domain: \(pinnedDomain)")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    // MARK: - Private Methods

    /// 서버 인증서의 공개 키 해시를 검증
    ///
    /// - Parameter serverTrust: 서버의 SecTrust 객체
    /// - Returns: 검증 성공 여부
    private func validateServerTrust(_ serverTrust: SecTrust) -> Bool {
        // 인증서 체인의 각 인증서에서 공개 키 해시 확인
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
            return false
        }

        for certificate in certificateChain {
            if let publicKeyHash = extractPublicKeyHash(from: certificate) {
                if pinnedKeyHashes.contains(publicKeyHash) {
                    return true
                }
            }
        }

        return false
    }

    /// 인증서에서 공개 키의 SHA-256 해시 추출 (Base64)
    ///
    /// - Parameter certificate: SecCertificate 객체
    /// - Returns: 공개 키 SHA-256 해시의 Base64 인코딩 문자열
    private func extractPublicKeyHash(from certificate: SecCertificate) -> String? {
        guard let publicKey = SecCertificateCopyKey(certificate) else {
            return nil
        }

        var error: Unmanaged<CFError>?
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
            return nil
        }

        let hash = SHA256.hash(data: publicKeyData)
        return Data(hash).base64EncodedString()
    }
}
