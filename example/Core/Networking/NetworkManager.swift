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
    
    // Convenience methods
    func get<T: Decodable>(
        endpoint: APIEndpoint,
        headers: [String: String]?
    ) async throws -> T
    
    func post<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable?,
        headers: [String: String]?
    ) async throws -> T
    
    func put<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable?,
        headers: [String: String]?
    ) async throws -> T

    func patch<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable?,
        headers: [String: String]?
    ) async throws -> T
    
    func delete<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable?,
        headers: [String: String]?
    ) async throws -> T

    // Void 반환 메서드 (응답 body가 없는 경우)
    func requestVoid(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        body: Encodable?,
        headers: [String: String]?
    ) async throws

    func get(
        endpoint: APIEndpoint,
        headers: [String: String]?
    ) async throws

    func post(
        endpoint: APIEndpoint,
        body: Encodable?,
        headers: [String: String]?
    ) async throws

    func put(
        endpoint: APIEndpoint,
        body: Encodable?,
        headers: [String: String]?
    ) async throws

    func patch(
        endpoint: APIEndpoint,
        body: Encodable?,
        headers: [String: String]?
    ) async throws

    func delete(
        endpoint: APIEndpoint,
        body: Encodable?,
        headers: [String: String]?
    ) async throws
}

// MARK: - Network Manager
final class NetworkManager: NetworkManagerProtocol {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = APIConfiguration.timeout
        configuration.timeoutIntervalForResource = APIConfiguration.timeout
        self.session = URLSession(configuration: configuration)
        
        // Encoder 설정
        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        
        // Decoder 설정
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: - Public Methods
    
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
    
    /// URL String을 사용한 요청
    func request<T: Decodable>(
        url: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        guard let url = URL(string: url) else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        
        // 기본 헤더 설정
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // 커스텀 헤더 추가
        headers?.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Body 인코딩
        if let body = body {
            do {
                urlRequest.httpBody = try encoder.encode(body)
            } catch {
                throw NetworkError.encodingError(error)
            }
        }
        
        // 디버그 로그
        #if DEBUG
        logRequest(urlRequest, body: body)
        #endif
        
        // 요청 실행
        let (data, response) = try await session.data(for: urlRequest)
        
        // 디버그 로그
        #if DEBUG
        logResponse(data: data, response: response)
        #endif
        
        // HTTP 응답 확인
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        // 상태 코드 확인
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? decoder.decode(ErrorResponse.self, from: data)
            
            #if DEBUG
            if let errorResponse = errorResponse {
                print("🚨 ============ ERROR ============")
                print(errorResponse.debugDescription)
                print("==================================\n")
            }
            #endif
            
            throw NetworkError.serverError(
                statusCode: httpResponse.statusCode,
                errorResponse: errorResponse
            )
        }
        
        // 응답 디코딩
        do {
            let decodedData = try decoder.decode(T.self, from: data)
            return decodedData
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
    
    /// Void 반환 요청 (응답 body가 없는 경우)
    func requestVoid(
        endpoint: APIEndpoint,
        method: HTTPMethod = .post,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws {
        guard let url = URL(string: endpoint.url) else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        // 기본 헤더 설정
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        // 커스텀 헤더 추가
        headers?.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Body 인코딩
        if let body = body {
            do {
                urlRequest.httpBody = try encoder.encode(body)
            } catch {
                throw NetworkError.encodingError(error)
            }
        }

        // 디버그 로그
        #if DEBUG
        logRequest(urlRequest, body: body)
        #endif

        // 요청 실행
        let (data, response) = try await session.data(for: urlRequest)

        // 디버그 로그
        #if DEBUG
        logResponse(data: data, response: response)
        #endif

        // HTTP 응답 확인
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }

        // 상태 코드 확인
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorResponse = try? decoder.decode(ErrorResponse.self, from: data)

            #if DEBUG
            if let errorResponse = errorResponse {
                print("🚨 ============ ERROR ============")
                print(errorResponse.debugDescription)
                print("==================================\n")
            }
            #endif

            throw NetworkError.serverError(
                statusCode: httpResponse.statusCode,
                errorResponse: errorResponse
            )
        }
    }

    // MARK: - Private Methods

    private func logRequest(_ request: URLRequest, body: Encodable?) {
        print("\n📤 ============ REQUEST ============")
        print("URL: \(request.url?.absoluteString ?? "N/A")")
        print("Method: \(request.httpMethod ?? "N/A")")
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("Headers:")
            headers.forEach { key, value in
                print("  \(key): \(value)")
            }
        }
        
        if let httpBody = request.httpBody,
           let jsonString = String(data: httpBody, encoding: .utf8) {
            print("Body: \(jsonString)")
        }
        print("====================================\n")
    }
    
    private func logResponse(data: Data, response: URLResponse) {
        print("\n📥 ============ RESPONSE ============")
        if let httpResponse = response as? HTTPURLResponse {
            print("Status Code: \(httpResponse.statusCode)")
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Body: \(jsonString)")
        }
        print("====================================\n")
    }
}

// MARK: - Convenience Extensions
extension NetworkManager {
    /// GET 요청
    func get<T: Decodable>(
        endpoint: APIEndpoint,
        headers: [String: String]? = nil
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .get,
            body: nil as String?,
            headers: headers
        )
    }
    
    /// POST 요청
    func post<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .post,
            body: body,
            headers: headers
        )
    }
    
    /// PUT 요청
    func put<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .put,
            body: body,
            headers: headers
        )
    }

    /// POST 요청 (Void 반환 - 응답 body가 없는 경우)
    func post(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws {
        try await requestVoid(
            endpoint: endpoint,
            method: .post,
            body: body,
            headers: headers
        )
    }
    
    /// PATCH 요청
    func patch<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .patch,
            body: body,
            headers: headers
        )
    }
    
    /// DELETE 요청
    func delete<T: Decodable>(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .delete,
            body: body,
            headers: headers
        )
    }

    /// GET 요청 (Void 반환 - 응답 body가 없는 경우)
    func get(
        endpoint: APIEndpoint,
        headers: [String: String]? = nil
    ) async throws {
        try await requestVoid(
            endpoint: endpoint,
            method: .get,
            body: nil,
            headers: headers
        )
    }

    /// PUT 요청 (Void 반환 - 응답 body가 없는 경우)
    func put(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws {
        try await requestVoid(
            endpoint: endpoint,
            method: .put,
            body: body,
            headers: headers
        )
    }

    /// PATCH 요청 (Void 반환 - 응답 body가 없는 경우)
    func patch(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws {
        try await requestVoid(
            endpoint: endpoint,
            method: .patch,
            body: body,
            headers: headers
        )
    }

    /// DELETE 요청 (Void 반환 - 응답 body가 없는 경우)
    func delete(
        endpoint: APIEndpoint,
        body: Encodable? = nil,
        headers: [String: String]? = nil
    ) async throws {
        try await requestVoid(
            endpoint: endpoint,
            method: .delete,
            body: body,
            headers: headers
        )
    }
}
