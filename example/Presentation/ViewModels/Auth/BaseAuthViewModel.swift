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
/// - 소셜 로그인 처리
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

    /// 마지막 실행 작업 (재시도용)
    @ObservationIgnored
    private var lastAction: (() async throws -> Void)?

    /// 마지막 fallback 에러 메시지 (재시도용)
    @ObservationIgnored
    private var lastFallbackError: String?

    // MARK: - Common Form Properties

    /// 이메일 입력값
    var email: String = ""

    /// 비밀번호 입력값
    var password: String = ""

    /// 이메일 필드 인라인 에러 메시지 (nil이면 에러 없음)
    var emailError: String? = nil

    /// 비밀번호 필드 인라인 에러 메시지 (nil이면 에러 없음)
    var passwordError: String? = nil

    // MARK: - Dependencies

    /// 인증 매니저
    let authManager: AuthManager

    /// 검증기
    let validator: AuthValidating

    // MARK: - Initialization

    init(
        authManager: AuthManager = ServiceContainer.shared.authManager,
        validator: AuthValidating = ServiceContainer.shared.authValidator
    ) {
        self.authManager = authManager
        self.validator = validator
    }

    // MARK: - Common Validation Methods (blur 시 호출)

    /// 이메일 필드 검증
    func validateEmail() {
        guard !email.isEmpty else { return }
        let result = validator.validateEmail(email)
        emailError = result.isValid ? nil : result.errorMessage
    }

    /// 비밀번호 필드 검증
    func validatePassword() {
        guard !password.isEmpty else { return }
        let result = validator.validatePassword(password)
        passwordError = result.isValid ? nil : result.errorMessage
    }

    // MARK: - Common Clear Methods (타이핑 시 호출)

    /// 이메일 에러 클리어
    func clearEmailError() {
        emailError = nil
    }

    /// 비밀번호 에러 클리어
    func clearPasswordError() {
        passwordError = nil
    }

    // MARK: - Public Methods

    /// 소셜 로그인
    /// - Parameter provider: 소셜 제공자 (.google, .apple, .native)
    func signInWith(_ provider: SocialProvider) {
        performAsyncTask(fallbackError: Localized.Error.errorLoginFailed) {
            try await self.authManager.signInWith(provider)
        }
    }

    /// 에러 메시지 초기화
    func clearError() {
        errorMessage = ""
        showError = false
    }

    /// 마지막 작업 재시도
    func retryLastAction() {
        guard let action = lastAction, let fallbackError = lastFallbackError else { return }
        performAsyncTask(fallbackError: fallbackError, action: action)
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
        // 재시도를 위해 저장
        lastAction = action
        lastFallbackError = fallbackError

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
