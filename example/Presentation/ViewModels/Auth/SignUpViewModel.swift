//
//  SignUpViewModel.swift
//  example
//
//  Path: Presentation/ViewModels/Auth/SignUpViewModel.swift
//  Created by 정희석 on 12/18/25.
//

import SwiftUI
import Combine

@MainActor
final class SignUpViewModel: BaseAuthViewModel {
    // MARK: - Published Properties
    #if DEBUG
    @Published var email: String = "test@test.com"
    @Published var password: String = "Test2022@!"
    @Published var confirmPassword: String = "Test2022@!"
    @Published var name: String = "Tester"
    @Published var isAgreeToTerms: Bool = true
    #else
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var name: String = ""
    @Published var isAgreeToTerms: Bool = false
    #endif

    // MARK: - Computed Properties
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
