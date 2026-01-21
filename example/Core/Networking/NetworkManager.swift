//
//  NetworkManager.swift
//  example
//
//  Path: Core/Networking/NetworkManager.swift
//  Created by 정희석 on 12/29/25.
//

import Foundation

// MARK: - HTTP Method
/// HTTP 메서드를 정의하는 열거형
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Retry Configuration
/// 네트워크 요청 재시도 설정
struct RetryConfiguration {
    /// 최대 재시도 횟수
    let maxRetries: Int
    /// 기본 지연 시간 (초)
    let baseDelay: TimeInterval
    /// 최대 지연 시간 (초)
    let maxDelay: TimeInterval
    /// 재시도 가능한 HTTP 상태 코드
    let retryableStatusCodes: Set<Int>
    /// 재시도 가능한 HTTP 메서드 (기본: GET만 재시도)
    let retryableMethods: Set<HTTPMethod>

    /// 기본 설정
    static let `default` = RetryConfiguration(
        maxRetries: 3,
        baseDelay: 1.0,
        maxDelay: 10.0,
        retryableStatusCodes: [408, 429, 500, 502, 503, 504],
        retryableMethods: [.get]
    )

    /// 재시도 비활성화
    static let disabled = RetryConfiguration(
        maxRetries: 0,
        baseDelay: 0,
        maxDelay: 0,
        retryableStatusCodes: [],
        retryableMethods: []
    )

    /// Exponential backoff 지연 시간 계산
    func delay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.5) // 지터 추가로 thundering herd 방지
        return min(exponentialDelay + jitter, maxDelay)
    }

    /// 재시도 가능 여부 확인
    func shouldRetry(statusCode: Int, method: HTTPMethod, attempt: Int) -> Bool {
        return attempt < maxRetries &&
               retryableStatusCodes.contains(statusCode) &&
               retryableMethods.contains(method)
    }

    /// 네트워크 에러에 대한 재시도 가능 여부 확인
    func shouldRetry(error: Error, method: HTTPMethod, attempt: Int) -> Bool {
        guard attempt < maxRetries && retryableMethods.contains(method) else {
            return false
        }

        let nsError = error as NSError
        let retryableErrorCodes: Set<Int> = [
            NSURLErrorTimedOut,
            NSURLErrorCannotFindHost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorNotConnectedToInternet
        ]

        return retryableErrorCodes.contains(nsError.code)
    }
}

// MARK: - Empty Response
/// 응답 body가 없는 경우를 위한 빈 타입
struct EmptyResponse: Decodable {}

// MARK: - Network Manager Protocol
protocol NetworkManagerProtocol {
    func request<T: Decodable>(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: Encodable?,
        headers: [String: String]?
    ) async throws -> T

    func request<T: Decodable>(
        url: String,
        method: HTTPMethod,
        body: Encodable?,
        headers: [String: String]?
    ) async throws -> T

    // Convenience methods (Decodable 반환)
    func get<T: Decodable>(endpoint: APIEndpoint, headers: [String: String]?) async throws -> T
    func post<T: Decodable>(endpoint: APIEndpoint, body: Encodable?, headers: [String: String]?) async throws -> T
    func put<T: Decodable>(endpoint: APIEndpoint, body: Encodable?, headers: [String: String]?) async throws -> T
    func patch<T: Decodable>(endpoint: APIEndpoint, body: Encodable?, headers: [String: String]?) async throws -> T
    func delete<T: Decodable>(endpoint: APIEndpoint, body: Encodable?, headers: [String: String]?) async throws -> T

    // Convenience methods (Void 반환)
    func get(endpoint: APIEndpoint, headers: [String: String]?) async throws
    func post(endpoint: APIEndpoint, body: Encodable?, headers: [String: String]?) async throws
    func put(endpoint: APIEndpoint, body: Encodable?, headers: [String: String]?) async throws
    func patch(endpoint: APIEndpoint, body: Encodable?, headers: [String: String]?) async throws
    func delete(endpoint: APIEndpoint, body: Encodable?, headers: [String: String]?) async throws
}

// MARK: - Network Manager
final class NetworkManager: NetworkManagerProtocol {
    static let shared = NetworkManager()

    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let retryConfiguration: RetryConfiguration

    private init(retryConfiguration: RetryConfiguration = .default) {
        self.retryConfiguration = retryConfiguration
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfiguration.timeout
        configuration.timeoutIntervalForResource = APIConfiguration.timeout
        self.session = URLSession(configuration: configuration)

        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    // MARK: - Core Request Methods

    /// APIEndpoint를 사용한 요청
    func request<T: Decodable>(
        endpoint: APIEndpoint,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        return try await request(
            url: endpoint.url,
            method: method,
            body: body,
            headers: headers
        )
    }

    /// URL String을 사용한 요청 (retry 로직 포함)
    func request<T: Decodable>(
        url: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        try await executeWithRetry(method: method) {
            try await self.performRequest(url: url, method: method, body: body, headers: headers)
        }
    }

    // MARK: - Private Methods

    /// 재시도 로직을 포함한 요청 실행
    private func executeWithRetry<T>(
        method: HTTPMethod,
        operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0...retryConfiguration.maxRetries {
            // Task 취소 확인
            try Task.checkCancellation()

            do {
                if attempt > 0 {
                    let delay = retryConfiguration.delay(for: attempt - 1)
                    Log.network("Retry attempt \(attempt)/\(retryConfiguration.maxRetries) after \(String(format: "%.2f", delay))s delay")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }

                return try await operation()

            } catch is CancellationError {
                Log.network("Request cancelled")
                throw NetworkError.cancelled

            } catch let error as NetworkError {
                lastError = error

                if case .serverError(let statusCode, _) = error,
                   retryConfiguration.shouldRetry(statusCode: statusCode, method: method, attempt: attempt) {
                    Log.network("Retryable server error (status: \(statusCode))")
                    continue
                }

                throw error

            } catch {
                lastError = error

                if retryConfiguration.shouldRetry(error: error, method: method, attempt: attempt) {
                    Log.network("Retryable network error:", error.localizedDescription)
                    continue
                }

                throw error
            }
        }

        throw lastError ?? NetworkError.unknown(NSError(domain: "NetworkManager", code: -1))
    }

    /// 실제 네트워크 요청 수행
    private func performRequest<T: Decodable>(
        url: String,
        method: HTTPMethod,
        body: Encodable?,
        headers: [String: String]?
    ) async throws -> T {
        let urlRequest = try buildURLRequest(url: url, method: method, body: body, headers: headers)

        logRequest(urlRequest)

        let (data, response) = try await session.data(for: urlRequest)

        logResponse(data: data, response: response)

        try validateResponse(response, data: data)

        // EmptyResponse 타입인 경우 빈 JSON 객체로 디코딩
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    /// URLRequest 생성
    private func buildURLRequest(
        url: String,
        method: HTTPMethod,
        body: Encodable?,
        headers: [String: String]?
    ) throws -> URLRequest {
        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        headers?.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        if let body = body {
            do {
                urlRequest.httpBody = try encoder.encode(body)
            } catch {
                throw NetworkError.encodingError(error)
            }
        }

        return urlRequest
    }

    /// 응답 유효성 검증
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? decoder.decode(ErrorResponse.self, from: data)

            if let errorResponse = errorResponse {
                Log.error("============ ERROR ============")
                Log.error(errorResponse.debugDescription)
                Log.error("================================")
            }

            throw NetworkError.serverError(
                statusCode: httpResponse.statusCode,
                errorResponse: errorResponse
            )
        }
    }

    // MARK: - Logging

    private func logRequest(_ request: URLRequest) {
        var logMessage = "============ REQUEST ============\n"
        logMessage += "URL: \(request.url?.absoluteString ?? "N/A")\n"
        logMessage += "Method: \(request.httpMethod ?? "N/A")"

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logMessage += "\nHeaders:"
            headers.forEach { key, value in
                logMessage += "\n  \(key): \(value)"
            }
        }

        if let httpBody = request.httpBody,
           let jsonString = String(data: httpBody, encoding: .utf8) {
            logMessage += "\nBody: \(jsonString)"
        }
        logMessage += "\n=================================="

        Log.network(logMessage)
    }

    private func logResponse(data: Data, response: URLResponse) {
        var logMessage = "============ RESPONSE ============\n"

        if let httpResponse = response as? HTTPURLResponse {
            logMessage += "Status Code: \(httpResponse.statusCode)"
        }

        if let jsonString = String(data: data, encoding: .utf8) {
            logMessage += "\nBody: \(jsonString)"
        }
        logMessage += "\n=================================="

        Log.network(logMessage)
    }
}

// MARK: - Convenience Extensions (Decodable 반환)
extension NetworkManager {
    func get<T: Decodable>(
        endpoint: APIEndpoint,
        headers: [String: String]? = nil
    ) async throws -> T {
        try await request(endpoint: endpoint, method: .get, body: nil as String?, headers: headers)
    }

    func post<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        try await request(endpoint: endpoint, method: .post, body: body, headers: headers)
    }

    func put<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        try await request(endpoint: endpoint, method: .put, body: body, headers: headers)
    }

    func patch<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        try await request(endpoint: endpoint, method: .patch, body: body, headers: headers)
    }

    func delete<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        try await request(endpoint: endpoint, method: .delete, body: body, headers: headers)
    }
}

// MARK: - Convenience Extensions (Void 반환)
extension NetworkManager {
    func get(
        endpoint: APIEndpoint,
        headers: [String: String]? = nil
    ) async throws {
        let _: EmptyResponse = try await request(endpoint: endpoint, method: .get, body: nil as String?, headers: headers)
    }

    func post(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws {
        let _: EmptyResponse = try await request(endpoint: endpoint, method: .post, body: body, headers: headers)
    }

    func put(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws {
        let _: EmptyResponse = try await request(endpoint: endpoint, method: .put, body: body, headers: headers)
    }

    func patch(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws {
        let _: EmptyResponse = try await request(endpoint: endpoint, method: .patch, body: body, headers: headers)
    }

    func delete(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws {
        let _: EmptyResponse = try await request(endpoint: endpoint, method: .delete, body: body, headers: headers)
    }
}
