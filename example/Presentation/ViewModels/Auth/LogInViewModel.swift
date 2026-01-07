//
//  LogInViewModel.swift
//  example
//
//  Path: Presentation/ViewModels/Auth/LogInViewModel.swift
//  Created by 정희석 on 12/18/25.
//

import SwiftUI
import Combine

@MainActor
final class LogInViewModel: BaseAuthViewModel {
    // MARK: - Published Properties
    #if DEBUG
    @Published var email: String = "test@test.com"
    @Published var password: String = "Test2022@!"
    #else
    @Published var email: String = ""
    @Published var password: String = ""
    #endif
    @Published var isNavigateToSignUp: Bool = false

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
