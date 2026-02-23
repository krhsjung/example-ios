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

}

// MARK: - Network Manager
final class NetworkManager: NetworkManagerProtocol {
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let retryConfiguration: RetryConfiguration

    /// SSL 피닝 delegate
    private let sslPinningDelegate: SSLPinningDelegate?

    /// 보안 쿠키 저장소
    private let secureCookieStorage: SecureCookieStorage

    /// Keychain 매니저 (토큰 저장/조회)
    private let keychain: KeychainManager

    /// 강제 로그아웃 핸들러 (순환 의존성 해결용)
    /// ServiceContainer에서 AuthManager 생성 후 설정
    var onForceLogout: (@MainActor @Sendable () -> Void)?

    /// 가변 상태(`refreshTask`, `inFlightGETRequests`) 동시 접근 보호용 Lock
    /// `await` 지점 전에 반드시 unlock하여 데드락 방지
    private let stateLock = NSLock()

    /// 토큰 리프레시 동시 호출 방지용 Task
    private var refreshTask: Task<AuthResponse, Error>?

    /// GET 요청 중복 방지용 in-flight 요청 저장소 (URL을 키로 사용)
    /// 동일한 URL에 대한 GET 요청이 동시에 발생하면 하나의 네트워크 호출만 수행
    private var inFlightGETRequests: [String: Task<(Data, URLResponse), Error>] = [:]

    init(
        secureCookieStorage: SecureCookieStorage,
        keychain: KeychainManager,
        retryConfiguration: RetryConfiguration = .default
    ) {
        self.secureCookieStorage = secureCookieStorage
        self.keychain = keychain
        self.retryConfiguration = retryConfiguration

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfiguration.requestTimeout
        configuration.timeoutIntervalForResource = APIConfiguration.resourceTimeout
        // 기본 쿠키 저장소 비활성화 (SecureCookieStorage 사용)
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpShouldSetCookies = false

        // SSL 피닝 설정
        let pinningDelegate = SSLPinningDelegate(
            domain: APIConfiguration.pinnedDomain,
            keyHashes: APIConfiguration.pinnedKeyHashes
        )
        self.sslPinningDelegate = pinningDelegate
        self.session = URLSession(
            configuration: configuration,
            delegate: pinningDelegate,
            delegateQueue: nil
        )

        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }

    // MARK: - Core Request Methods

    /// APIEndpoint를 사용한 요청
    ///
    /// 인증 필요 엔드포인트에서 401 응답 시 자동으로 토큰 리프레시를 시도합니다.
    /// - `server_auth_token_expired`: 리프레시 토큰으로 새 토큰 발급 후 원래 요청 재시도
    /// - `server_auth_session_invalid`, `server_auth_token_invalid`: 재로그인 필요 → 로그아웃 처리
    func request<T: Decodable>(
        endpoint: APIEndpoint,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        // 인증 필요 엔드포인트: 토큰 검증 후 Authorization 헤더 자동 주입
        var mergedHeaders = headers ?? [:]
        if endpoint.requiresAuth {
            guard let accessToken = keychain.loadString(key: .accessToken) else {
                throw NetworkError.custom(Localized.Error.errorUnauthorized)
            }
            mergedHeaders["Authorization"] = "Bearer \(accessToken)"
        }

        do {
            return try await request(
                url: endpoint.url,
                method: method,
                body: body,
                headers: mergedHeaders
            )
        } catch let error as NetworkError {
            // 401 응답이고 인증 필요 엔드포인트인 경우 토큰 리프레시 시도
            guard endpoint.requiresAuth,
                  case .serverError(401, let errorResponse) = error else {
                throw error
            }

            let errorId = errorResponse?.id ?? ""

            switch errorId {
            case "server_auth_token_expired":
                // 토큰 만료 → 리프레시 시도
                let refreshResponse = try await refreshTokens()

                // 새 토큰으로 원래 요청 재시도
                var retryHeaders = headers ?? [:]
                retryHeaders["Authorization"] = "Bearer \(refreshResponse.accessToken)"

                return try await request(
                    url: endpoint.url,
                    method: method,
                    body: body,
                    headers: retryHeaders
                )

            case "server_auth_session_invalid", "server_auth_token_invalid":
                // 세션/토큰 무효 → 재로그인 필요
                forceLogout()
                throw error

            default:
                // 알 수 없는 401 에러 → 재로그인 처리
                forceLogout()
                throw error
            }
        }
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

    // MARK: - Token Refresh

    /// 리프레시 토큰으로 새 액세스/리프레시 토큰 발급
    ///
    /// 동시에 여러 요청에서 401이 발생해도 리프레시는 1회만 실행됩니다.
    /// - Returns: 새로운 토큰이 포함된 `AuthResponse`
    /// - Throws: 리프레시 실패 시 에러 (재로그인 필요)
    private func refreshTokens() async throws -> AuthResponse {
        // withLock으로 refreshTask 읽기/쓰기를 원자적으로 수행
        // isCreator: 이 호출이 Task를 생성했는지 여부 (실패 시 forceLogout 책임 구분)
        let (taskToAwait, isCreator) = stateLock.withLock { () -> (Task<AuthResponse, Error>, Bool) in
            // 이미 리프레시 진행 중이면 해당 Task 반환
            if let existing = refreshTask {
                return (existing, false)
            }

            let task = Task<AuthResponse, Error> { [self] in
                defer {
                    stateLock.withLock { refreshTask = nil }
                }

                guard let refreshToken = keychain.loadString(key: .refreshToken) else {
                    forceLogout()
                    throw NetworkError.custom(Localized.Error.errorUnauthorized)
                }

                Log.custom(category: "Auth", "Token expired, attempting refresh...")

                let body = RefreshRequest(refreshToken: refreshToken)
                let response: AuthResponse = try await performRequest(
                    url: APIEndpoint.refresh.url,
                    method: .post,
                    body: body,
                    headers: nil
                )

                // 새 토큰 Keychain에 저장
                try keychain.save(key: .accessToken, value: response.accessToken)
                try keychain.save(key: .refreshToken, value: response.refreshToken)

                Log.custom(category: "Auth", "Token refresh successful")
                return response
            }

            refreshTask = task
            return (task, true)
        }

        do {
            return try await taskToAwait.value
        } catch {
            if isCreator {
                // 리프레시 실패 → 재로그인 필요 (Task 생성자만 처리)
                Log.error("Token refresh failed:", error.localizedDescription)
                forceLogout()
            }
            throw error
        }
    }

    /// 강제 로그아웃 처리 (onForceLogout 클로저를 통해 AuthManager에 알림)
    @MainActor
    private func forceLogout() {
        Log.custom(category: "Auth", "Force logout - re-login required")
        onForceLogout?()
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

                switch error {
                case .serverError(let statusCode, _):
                    if retryConfiguration.shouldRetry(statusCode: statusCode, method: method, attempt: attempt) {
                        Log.network("Retryable server error (status: \(statusCode))")
                        continue
                    }
                case .timeout, .noConnection:
                    if retryConfiguration.retryableMethods.contains(method) && attempt < retryConfiguration.maxRetries {
                        Log.network("Retryable network error: \(error)")
                        continue
                    }
                default:
                    break
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
        var urlRequest = try buildURLRequest(url: url, method: method, body: body, headers: headers)

        // SecureCookieStorage에서 쿠키 헤더 적용
        if let requestURL = urlRequest.url {
            let cookieHeaders = secureCookieStorage.cookieHeaders(for: requestURL)
            cookieHeaders.forEach { key, value in
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        logRequest(urlRequest)

        let data: Data
        let response: URLResponse

        // GET 요청은 Request Coalescing 적용 (동일 URL 중복 호출 방지)
        if method == .get {
            (data, response) = try await coalescedFetch(for: urlRequest, key: url)
        } else {
            do {
                (data, response) = try await session.data(for: urlRequest)
            } catch {
                throw mapURLSessionError(error)
            }
        }

        // 응답에서 쿠키 추출하여 SecureCookieStorage에 저장
        if let httpResponse = response as? HTTPURLResponse,
           let requestURL = urlRequest.url {
            secureCookieStorage.saveCookies(from: httpResponse, for: requestURL)
        }

        logResponse(data: data, response: response)

        try validateResponse(response, data: data)

        // EmptyResponse 타입인 경우 디코딩 생략
        if T.self == EmptyResponse.self, let result = EmptyResponse() as? T {
            return result
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    /// GET 요청 중복 방지 (Request Coalescing)
    ///
    /// 동일한 URL에 대한 GET 요청이 동시에 발생하면 하나의 네트워크 호출만 수행하고
    /// 모든 호출자에게 동일한 응답을 반환합니다.
    /// `refreshTask`와 동일한 패턴을 사용합니다.
    private func coalescedFetch(for urlRequest: URLRequest, key: String) async throws -> (Data, URLResponse) {
        // withLock으로 inFlightGETRequests 읽기/쓰기를 원자적으로 수행
        let (taskToAwait, isCoalesced) = stateLock.withLock { () -> (Task<(Data, URLResponse), Error>, Bool) in
            // 동일 URL에 대한 in-flight 요청이 있으면 해당 Task 반환
            if let existing = inFlightGETRequests[key] {
                return (existing, true)
            }

            let task = Task<(Data, URLResponse), Error> { [self] in
                defer {
                    stateLock.withLock { inFlightGETRequests[key] = nil }
                }
                do {
                    return try await session.data(for: urlRequest)
                } catch {
                    throw mapURLSessionError(error)
                }
            }

            inFlightGETRequests[key] = task
            return (task, false)
        }

        if isCoalesced {
            Log.network("Request coalesced: \(key)")
        }

        return try await taskToAwait.value
    }

    /// URLSession 에러를 NetworkError로 매핑
    private func mapURLSessionError(_ error: Error) -> NetworkError {
        let nsError = error as NSError

        switch nsError.code {
        case NSURLErrorTimedOut:
            return .timeout
        case NSURLErrorNotConnectedToInternet,
             NSURLErrorCannotFindHost,
             NSURLErrorCannotConnectToHost,
             NSURLErrorNetworkConnectionLost,
             NSURLErrorDNSLookupFailed:
            return .noConnection
        case NSURLErrorCancelled:
            return .cancelled
        default:
            return .unknown(error)
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
        urlRequest.timeoutInterval = APIConfiguration.connectTimeout
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

    // MARK: - Sensitive Headers
    /// 로그에서 마스킹할 민감한 헤더 키
    private static let sensitiveHeaders: Set<String> = [
        "cookie", "set-cookie", "authorization"
    ]

    /// 로그에서 마스킹할 민감한 JSON 필드
    private static let sensitiveBodyFields: Set<String> = [
        "password", "token", "identityToken", "accessToken", "refreshToken", "secret"
    ]

    private func logRequest(_ request: URLRequest) {
        var logMessage = "============ REQUEST ============\n"
        logMessage += "URL: \(request.url?.absoluteString ?? "N/A")\n"
        logMessage += "Method: \(request.httpMethod ?? "N/A")"

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logMessage += "\nHeaders:"
            headers.forEach { key, value in
                let maskedValue = Self.sensitiveHeaders.contains(key.lowercased()) ? "****" : value
                logMessage += "\n  \(key): \(maskedValue)"
            }
        }

        if let httpBody = request.httpBody {
            logMessage += "\nBody: \(maskSensitiveFields(in: httpBody))"
        }
        logMessage += "\n=================================="

        Log.network(logMessage)
    }

    private func logResponse(data: Data, response: URLResponse) {
        var logMessage = "============ RESPONSE ============\n"

        if let httpResponse = response as? HTTPURLResponse {
            logMessage += "Status Code: \(httpResponse.statusCode)"

            // Set-Cookie 헤더 마스킹
            if let setCookie = httpResponse.value(forHTTPHeaderField: "Set-Cookie") {
                logMessage += "\nSet-Cookie: \(setCookie.prefix(20))****"
            }
        }

        if let jsonString = String(data: data, encoding: .utf8) {
            logMessage += "\nBody: \(jsonString)"
        }
        logMessage += "\n=================================="

        Log.network(logMessage)
    }

    /// JSON body에서 민감한 필드를 마스킹
    private func maskSensitiveFields(in data: Data) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return String(data: data, encoding: .utf8) ?? "N/A"
        }

        var masked = json
        for key in json.keys {
            if Self.sensitiveBodyFields.contains(key) {
                masked[key] = "****"
            }
        }

        guard let maskedData = try? JSONSerialization.data(withJSONObject: masked, options: .sortedKeys),
              let maskedString = String(data: maskedData, encoding: .utf8) else {
            return "N/A"
        }

        return maskedString
    }
}

// MARK: - Convenience Extensions (Decodable 반환)
extension NetworkManagerProtocol {
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
extension NetworkManagerProtocol {
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
