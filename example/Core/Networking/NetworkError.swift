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
            if let errorResponse = errorResponse {
                // ErrorResponse의 localizedMessage 사용 (파라미터 자동 처리)
                return errorResponse.localizedMessage
            }
            return "Server Error: Status Code - (\(statusCode))"
        case .unknown(let error):
            return "\(error.localizedDescription)"
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
}
