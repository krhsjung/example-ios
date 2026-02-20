//
//  LogInViewModel.swift
//  example
//
//  Path: Presentation/ViewModels/Auth/LogInViewModel.swift
//  Created by 정희석 on 12/18/25.
//

import SwiftUI
import Observation

/// 로그인 화면의 ViewModel
///
/// 기능:
/// - 이메일/비밀번호 로그인
/// - SNS 로그인 (부모 클래스에서 상속)
/// - 회원가입 화면 네비게이션
@MainActor
@Observable
final class LogInViewModel: BaseAuthViewModel {
    // MARK: - Observable Properties

    /// 이메일 입력값
    var email: String = ""

    /// 비밀번호 입력값
    var password: String = ""

    /// 이메일 필드 인라인 에러 메시지 (nil이면 에러 없음)
    var emailError: String? = nil

    /// 비밀번호 필드 인라인 에러 메시지 (nil이면 에러 없음)
    var passwordError: String? = nil

    /// 회원가입 화면 이동 플래그
    var isNavigateToSignUp: Bool = false

    // MARK: - Initialization

    override init() {
        super.init()
        #if DEBUG
        self.email = TestFixtures.Auth.email
        self.password = TestFixtures.Auth.password
        #endif
    }

    // MARK: - Private Properties

    private let validator = AuthValidator.shared

    private var formData: LogInFormData {
        LogInFormData(
            email: email,
            password: password
        )
    }

    // MARK: - Public Methods

    /// 이메일 필드 검증 (blur 시 호출)
    func validateEmail() {
        guard !email.isEmpty else { return }
        let result = validator.validateEmail(email)
        emailError = result.isValid ? nil : result.errorMessage
    }

    /// 비밀번호 필드 검증 (blur 시 호출)
    func validatePassword() {
        guard !password.isEmpty else { return }
        let result = validator.validatePassword(password)
        passwordError = result.isValid ? nil : result.errorMessage
    }

    /// 이메일 에러 클리어 (타이핑 시 호출)
    func clearEmailError() {
        if emailError != nil { emailError = nil }
    }

    /// 비밀번호 에러 클리어 (타이핑 시 호출)
    func clearPasswordError() {
        if passwordError != nil { passwordError = nil }
    }

    /// 일반 로그인 처리
    /// 전체 필드 검증 후 각 필드에 인라인 에러 표시, 서버 에러는 alert로 표시
    func logIn() {
        // 필드별 검증 결과를 각각 매핑
        let emailResult = validator.validateEmail(email)
        let passwordResult = validator.validatePassword(password)

        emailError = emailResult.isValid ? nil : emailResult.errorMessage
        passwordError = passwordResult.isValid ? nil : passwordResult.errorMessage

        // 검증 실패 시 서버 호출하지 않음
        guard emailResult.isValid && passwordResult.isValid else { return }

        let request = formData.toLogInRequest()

        performAsyncTask(fallbackError: Localized.Error.errorLoginFailed) {
            try await self.authManager.logIn(request: request)
        }
    }

    /// 회원가입 화면으로 이동
    func navigateToSignUp() {
        isNavigateToSignUp = true
    }
}
