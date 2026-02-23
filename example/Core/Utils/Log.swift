//
//  Log.swift
//  example
//
//  Path: Core/Utils/Log.swift
//  Created by Claude on 1/21/26.
//

import Foundation
import os.log

// MARK: - OSLog Extension

extension OSLog {
    /// 앱의 Bundle Identifier를 subsystem으로 사용 (테스트 환경 대비 기본값 제공)
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.example.app"

    /// 네트워크 관련 로그
    static let network = OSLog(subsystem: subsystem, category: "Network")

    /// 디버그 로그
    static let debug = OSLog(subsystem: subsystem, category: "Debug")

    /// 정보성 로그
    static let info = OSLog(subsystem: subsystem, category: "Info")

    /// 에러 로그
    static let error = OSLog(subsystem: subsystem, category: "Error")
}

// MARK: - Log

/// 통합 로깅 유틸리티
///
/// Apple의 os.log 시스템을 활용하여 구조화된 로깅을 제공합니다.
/// DEBUG 빌드에서만 로그가 출력되며, Release 빌드에서는 자동으로 비활성화됩니다.
///
/// 사용 예시:
/// ```swift
/// Log.debug("디버그 메시지")
/// Log.info("정보 메시지", someValue)
/// Log.network("API 요청", url, method)
/// Log.error("에러 발생", error)
/// Log.custom(category: "Auth", "인증 처리", userId)
/// ```
struct Log {

    // MARK: - Level

    /// 로그 레벨 정의
    ///
    /// 각 레벨은 고유한 카테고리, OSLog 인스턴스, 로그 타입을 가집니다.
    enum Level {
        /// 디버깅 로그 - 개발 중 코드 디버깅에 유용한 정보
        case debug
        /// 정보성 로그 - 문제 해결 시 활용할 수 있는 정보
        case info
        /// 네트워크 로그 - 네트워크 요청/응답 관련 정보
        case network
        /// 에러 로그 - 코드 실행 중 발생한 에러
        case error
        /// 커스텀 로그 - 사용자 정의 카테고리
        case custom(category: String)

        /// 로그 카테고리 문자열 (이모지 포함)
        fileprivate var category: String {
            switch self {
            case .debug:
                return "🟡 DEBUG"
            case .info:
                return "🟠 INFO"
            case .network:
                return "🔵 NETWORK"
            case .error:
                return "🔴 ERROR"
            case .custom(let category):
                return "🟢 \(category)"
            }
        }

        /// OSLog 인스턴스
        fileprivate var osLog: OSLog {
            switch self {
            case .debug:
                return OSLog.debug
            case .info:
                return OSLog.info
            case .network:
                return OSLog.network
            case .error:
                return OSLog.error
            case .custom:
                return OSLog.debug
            }
        }

        /// OSLog 타입
        fileprivate var osLogType: OSLogType {
            switch self {
            case .debug:
                return .debug
            case .info:
                return .info
            case .network:
                return .default
            case .error:
                return .error
            case .custom:
                return .debug
            }
        }
    }

    // MARK: - Private Methods

    /// 로그 출력 (내부 구현)
    /// - Parameters:
    ///   - message: 로그 메시지
    ///   - arguments: 추가 인자들
    ///   - level: 로그 레벨
    private static func log(_ message: Any, _ arguments: [Any], level: Level) {
        #if DEBUG
        let extraMessage: String = arguments.map { String(describing: $0) }.joined(separator: " ")
        let logger = Logger(subsystem: OSLog.subsystem, category: level.category)
        let logMessage = "\(message) \(extraMessage)"

        // .public: Sysdiagnose에 평문 노출 (디버깅 편의)
        // .private: Sysdiagnose에서 <redacted> 처리 (민감 데이터 보호)
        switch level {
        case .debug, .custom:
            logger.debug("\(logMessage, privacy: .public)")
        case .info:
            logger.info("\(logMessage, privacy: .private)")
        case .network:
            logger.log("\(logMessage, privacy: .private)")
        case .error:
            logger.error("\(logMessage, privacy: .private)")
        }
        #endif
    }
}

// MARK: - Public Methods

extension Log {

    /// 디버그 로그 출력
    ///
    /// 개발 중 코드 디버깅 시 사용할 수 있는 유용한 정보를 출력합니다.
    /// - Parameters:
    ///   - message: 로그 메시지
    ///   - arguments: 추가 인자들 (가변 인자)
    static func debug(_ message: Any, _ arguments: Any...) {
        log(message, arguments, level: .debug)
    }

    /// 정보성 로그 출력
    ///
    /// 문제 해결 시 활용할 수 있는, 도움이 되지만 필수적이지 않은 정보를 출력합니다.
    /// - Parameters:
    ///   - message: 로그 메시지
    ///   - arguments: 추가 인자들 (가변 인자)
    static func info(_ message: Any, _ arguments: Any...) {
        log(message, arguments, level: .info)
    }

    /// 네트워크 로그 출력
    ///
    /// 네트워크 요청/응답 관련 정보를 출력합니다.
    /// - Parameters:
    ///   - message: 로그 메시지
    ///   - arguments: 추가 인자들 (가변 인자)
    static func network(_ message: Any, _ arguments: Any...) {
        log(message, arguments, level: .network)
    }

    /// 에러 로그 출력
    ///
    /// 코드 실행 중 발생한 에러를 출력합니다.
    /// - Parameters:
    ///   - message: 로그 메시지
    ///   - arguments: 추가 인자들 (가변 인자)
    static func error(_ message: Any, _ arguments: Any...) {
        log(message, arguments, level: .error)
    }

    /// 커스텀 카테고리 로그 출력
    ///
    /// 사용자 정의 카테고리로 로그를 출력합니다.
    /// - Parameters:
    ///   - category: 커스텀 카테고리 이름
    ///   - message: 로그 메시지
    ///   - arguments: 추가 인자들 (가변 인자)
    static func custom(category: String, _ message: Any, _ arguments: Any...) {
        log(message, arguments, level: .custom(category: category))
    }
}
