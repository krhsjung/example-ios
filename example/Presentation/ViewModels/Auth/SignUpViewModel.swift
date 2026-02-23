//
//  SignUpViewModel.swift
//  example
//
//  Path: Presentation/ViewModels/Auth/SignUpViewModel.swift
//  Created by 정희석 on 12/18/25.
//

import SwiftUI
import Observation

/// 회원가입 화면의 ViewModel
///
/// 기능:
/// - 이메일/비밀번호 회원가입
/// - 소셜 로그인 (부모 클래스에서 상속)
/// - 필드별 인라인 검증
@MainActor
@Observable
final class SignUpViewModel: BaseAuthViewModel {
    // MARK: - Observable Properties

    /// 비밀번호 확인 입력값
    var confirmPassword: String = ""

    /// 이름 입력값
    var name: String = ""

    /// 이용약관 동의 여부
    var isAgreeToTerms: Bool = false

    /// 비밀번호 확인 필드 인라인 에러 메시지 (nil이면 에러 없음)
    var confirmPasswordError: String? = nil

    /// 이름 필드 인라인 에러 메시지 (nil이면 에러 없음)
    var nameError: String? = nil

    // MARK: - Initialization

    override init(
        authManager: AuthManager = ServiceContainer.shared.authManager,
        validator: AuthValidating = ServiceContainer.shared.authValidator
    ) {
        super.init(authManager: authManager, validator: validator)
        #if DEBUG
        self.email = TestFixtures.Auth.email
        self.password = TestFixtures.Auth.password
        self.confirmPassword = TestFixtures.Auth.password
        self.name = TestFixtures.Auth.name
        self.isAgreeToTerms = true
        #endif
    }

    // MARK: - Private Properties

    private var formData: SignUpFormData {
        SignUpFormData(
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            name: name,
            isAgreeToTerms: isAgreeToTerms
        )
    }

    // MARK: - Computed Properties

    /// 폼 입력 완료 여부 (모든 필드가 채워졌는지 확인)
    var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !name.isEmpty &&
        isAgreeToTerms
    }

    // MARK: - Validation Methods (blur 시 호출)

    /// 비밀번호 확인 필드 검증
    func validateConfirmPassword() {
        guard !confirmPassword.isEmpty else { return }
        let result = validator.validatePasswordConfirmation(password: password, confirmPassword: confirmPassword)
        confirmPasswordError = result.isValid ? nil : result.errorMessage
    }

    /// 이름 필드 검증
    func validateName() {
        guard !name.isEmpty else { return }
        let result = validator.validateName(name)
        nameError = result.isValid ? nil : result.errorMessage
    }

    // MARK: - Clear Methods (타이핑 시 호출)

    func clearConfirmPasswordError() {
        confirmPasswordError = nil
    }

    func clearNameError() {
        nameError = nil
    }

    // MARK: - Public Methods

    /// 회원가입 처리
    /// 전체 필드 검증 후 각 필드에 인라인 에러 표시, 서버 에러는 alert로 표시
    func signUp() {
        let emailResult = validator.validateEmail(email)
        let passwordResult = validator.validatePassword(password)
        let confirmPasswordResult = validator.validatePasswordConfirmation(password: password, confirmPassword: confirmPassword)
        let nameResult = validator.validateName(name)

        emailError = emailResult.isValid ? nil : emailResult.errorMessage
        passwordError = passwordResult.isValid ? nil : passwordResult.errorMessage
        confirmPasswordError = confirmPasswordResult.isValid ? nil : confirmPasswordResult.errorMessage
        nameError = nameResult.isValid ? nil : nameResult.errorMessage

        guard emailResult.isValid && passwordResult.isValid &&
              confirmPasswordResult.isValid && nameResult.isValid else { return }

        let request = formData.toSignUpRequest()

        performAsyncTask(fallbackError: Localized.Error.errorSignupFailed) {
            try await self.authManager.signUp(request: request)
        }
    }
}
