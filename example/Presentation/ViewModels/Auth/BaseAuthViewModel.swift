//
//  BaseAuthViewModel.swift
//  example
//
//  Path: Presentation/ViewModels/Auth/BaseAuthViewModel.swift
//  Created by 정희석 on 1/7/26.
//

import SwiftUI
import Observation

/// 인증 관련 ViewModel의 기본 클래스
///
/// 공통 기능:
/// - 로딩 상태 관리
/// - 에러 처리 및 표시
/// - SNS 로그인 처리
/// - Task Cancellation 지원
@MainActor
@Observable
class BaseAuthViewModel {
    // MARK: - Observable Properties

    /// 에러 메시지
    var errorMessage: String = ""

    /// 에러 표시 여부
    var showError: Bool = false

    /// 로딩 상태
    var isLoading: Bool = false

    // MARK: - Private Properties

    /// 현재 실행 중인 Task (취소 지원용)
    @ObservationIgnored
    private var currentTask: Task<Void, Never>?

    // MARK: - Dependencies

    /// 인증 매니저
    let authManager = AuthManager.shared

    // MARK: - Public Methods

    /// SNS 로그인
    /// - Parameter sns: SNS 제공자 (.google, .apple, .native)
    func signInWith(_ sns: SnsProvider) {
        performAsyncTask(fallbackError: Localized.Error.errorLoginFailed) {
            try await self.authManager.signInWith(sns)
        }
    }

    /// 에러 메시지 초기화
    func clearError() {
        errorMessage = ""
        showError = false
    }

    /// 현재 실행 중인 비동기 작업 취소
    func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
        isLoading = false
        Log.debug("Current task cancelled")
    }

    // MARK: - Protected Methods

    /// 비동기 작업 수행 (로딩 상태, 에러 처리, Task Cancellation 포함)
    ///
    /// - Parameters:
    ///   - fallbackError: 알 수 없는 에러 발생 시 표시할 기본 메시지
    ///   - action: 실행할 비동기 작업
    ///
    /// - Note: 새로운 작업 시작 시 기존 작업이 자동으로 취소됩니다.
    func performAsyncTask(
        fallbackError: String,
        action: @escaping () async throws -> Void
    ) {
        // 기존 작업 취소
        currentTask?.cancel()

        currentTask = Task {
            isLoading = true
            defer { isLoading = false }

            do {
                try await action()
            } catch is CancellationError {
                // Task 취소는 에러로 표시하지 않음
                Log.debug("Task was cancelled")
            } catch let error as NetworkError where error.isCancelled {
                // NetworkError.cancelled도 에러로 표시하지 않음
                Log.debug("Network request was cancelled")
            } catch let error as NetworkError {
                errorMessage = error.localizedDescription
                showError = true
            } catch {
                errorMessage = fallbackError
                showError = true
            }
        }
    }
}
