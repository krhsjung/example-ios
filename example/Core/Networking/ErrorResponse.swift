//
//  ErrorResponse.swift
//  example
//
//  Path: Core/Networking/ErrorResponse.swift
//  Created by 정희석 on 1/5/26.
//

import Foundation

// MARK: - Error Response (서버 응답)
/// 서버에서 반환하는 에러 응답 구조
/// 중첩된 JSON 메시지를 파싱하여 실제 에러 정보를 추출
struct ErrorResponse: Codable {
    /// HTTP 에러 타입 (예: "Conflict", "Bad Request")
    let error: String
    /// HTTP 상태 코드
    let statusCode: Int
    /// 중첩된 JSON 문자열 또는 일반 문자열
    let messageString: String
    
    /// 실제 에러 정보 (중첩된 JSON에서 파싱됨)
    var id: String {
        parsedMessage?.id ?? "unknown_error"
    }
    
    var message: String {
        parsedMessage?.message ?? messageString
    }
    
    var params: [String: String]? {
        parsedMessage?.params
    }
    
    /// 다국어 메시지 가져오기 (파라미터 포함)
    /// - Returns: 다국어 처리된 에러 메시지
    var localizedMessage: String {
        // params에서 값 추출
        if let params = params {
            let paramValues = params.values.map { $0 as CVarArg }
            if !paramValues.isEmpty {
                // 파라미터가 있으면 포맷팅된 메시지 반환
                return String.servererror(id, paramValues)
            }
        }
        
        // 파라미터가 없으면 기본 메시지 반환
        let localizedMsg = String.servererror(id)
        return localizedMsg.isEmpty ? message : localizedMsg
    }
    
    /// 중첩된 JSON 메시지를 파싱한 결과
    private var parsedMessage: ErrorMessage? {
        guard let data = messageString.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(ErrorMessage.self, from: data)
    }
    
    enum CodingKeys: String, CodingKey {
        case error
        case statusCode
        case messageString = "message"
    }
}

// MARK: - Error Message (중첩된 JSON)
/// message 필드 안에 들어있는 실제 에러 정보
private struct ErrorMessage: Codable {
    /// 에러 ID (다국어 키로 사용)
    let id: String
    /// 에러 메시지
    let message: String
    /// 추가 파라미터 (예: 필드명)
    let params: [String: String]?
}

// MARK: - Extension
extension ErrorResponse {
    /// 디버그용 상세 정보
    var debugDescription: String {
        """
        ErrorResponse:
        - Status Code: \(statusCode)
        - Error: \(error)
        - ID: \(id)
        - Message: \(message)
        - Params: \(params?.description ?? "nil")
        - Raw Message: \(messageString)
        """
    }
}
