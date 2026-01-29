//
//  NetworkError.swift
//  example
//
//  Path: Core/Networking/NetworkError.swift
//  Created by 정희석 on 12/29/25.
//

import Foundation

// MARK: - Network Error
enum NetworkError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case encodingError(Error)
    case serverError(statusCode: Int, errorResponse: ErrorResponse?)
    case timeout
    case noConnection
    case unknown(Error)
    case custom(String)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return Localized.Error.errorInvalidUrl
        case .noData:
            return Localized.Error.errorNoData
        case .decodingError(let error):
            return Localized.Error.errorDecoding + ": \(error.localizedDescription)"
        case .encodingError(let error):
            return Localized.Error.errorEncoding + ": \(error.localizedDescription)"
        case .serverError(let statusCode, let errorResponse):
            // 1순위: ErrorResponse의 localizedMessage (서버 에러 코드 기반 다국어)
            if let errorResponse = errorResponse {
                return errorResponse.localizedMessage
            }
            // 2순위: HTTP 상태 코드별 다국어 메시지
            return Self.localizedMessageForStatusCode(statusCode)
        case .timeout:
            return Localized.Error.errorTimeout
        case .noConnection:
            return Localized.Error.errorNoConnection
        case .unknown:
            return Localized.Error.errorUnknown
        case .custom(let message):
            return message
        case .cancelled:
            return Localized.Error.errorCancelled
        }
    }

    /// 취소된 요청인지 확인
    var isCancelled: Bool {
        if case .cancelled = self { return true }
        return false
    }

    /// 서버에서 제공한 원본 메시지 (디버깅용)
    var serverMessage: String? {
        switch self {
        case .serverError(_, let errorResponse):
            return errorResponse?.message
        default:
            return nil
        }
    }

    // MARK: - Private

    /// HTTP 상태 코드별 다국어 메시지 매핑
    private static func localizedMessageForStatusCode(_ statusCode: Int) -> String {
        switch statusCode {
        case 400:
            return Localized.Error.errorBadRequest
        case 401:
            return Localized.Error.errorUnauthorized
        case 403:
            return Localized.Error.errorForbidden
        case 404:
            return Localized.Error.errorNotFound
        case 429:
            return Localized.Error.errorRateLimited
        case 500, 502, 503:
            return Localized.Error.errorServer
        default:
            return Localized.Error.errorUnknown
        }
    }
}
