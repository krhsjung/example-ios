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
/// - SNS 로그인 (부모 클래스에서 상속)
/// - 폼 유효성 검사
@MainActor
@Observable
final class SignUpViewModel: BaseAuthViewModel {
    // MARK: - Observable Properties

    /// 이메일 입력값
    var email: String = ""

    /// 비밀번호 입력값
    var password: String = ""

    /// 비밀번호 확인 입력값
    var confirmPassword: String = ""

    /// 이름 입력값
    var name: String = ""

    /// 이용약관 동의 여부
    var isAgreeToTerms: Bool = false

    // MARK: - Initialization

    override init() {
        super.init()
        #if DEBUG
        self.email = TestFixtures.Auth.email
        self.password = TestFixtures.Auth.password
        self.confirmPassword = TestFixtures.Auth.password
        self.name = TestFixtures.Auth.name
        self.isAgreeToTerms = true
        #endif
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

    // MARK: - Public Methods

    /// 회원가입 처리
    func signUp() {
        let validationResult = formData.validateAll()

        guard validationResult.isValid else {
            errorMessage = validationResult.errorMessage
            showError = true
            return
        }

        let request = formData.toSignUpRequest()

        performAsyncTask(fallbackError: Localized.Error.errorSignupFailed) {
            try await self.authManager.signUp(request: request)
        }
    }
}
