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
/// - 소셜 로그인 (부모 클래스에서 상속)
@MainActor
@Observable
final class LogInViewModel: BaseAuthViewModel {
    // MARK: - Initialization

    override init(
        authManager: AuthManager = ServiceContainer.shared.authManager,
        validator: AuthValidating = ServiceContainer.shared.authValidator
    ) {
        super.init(authManager: authManager, validator: validator)
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

}
