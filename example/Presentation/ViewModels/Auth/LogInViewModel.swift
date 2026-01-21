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
    private var formData: LogInFormData {
        LogInFormData(
            email: email,
            password: password
        )
    }

    // MARK: - Public Methods

    /// 일반 로그인 처리
    func logIn() {
        let validationResult = formData.validateAll()

        guard validationResult.isValid else {
            errorMessage = validationResult.errorMessage
            showError = true
            return
        }

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
