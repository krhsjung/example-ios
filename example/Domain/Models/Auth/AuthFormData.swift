//
//  AuthFormData.swift
//  example
//
//  Path: Domain/Models/Auth/AuthFormData.swift
//  Created by 정희석 on 1/7/26.
//

import Foundation

// MARK: - Login Form Data
struct LogInFormData {
    var email: String
    var password: String

    func validateEmail() -> ValidationResult {
        return AuthValidator.validateEmail(email)
    }

    func validatePassword() -> ValidationResult {
        return AuthValidator.validatePassword(password)
    }

    func validateAll() -> ValidationResult {
        let validations: [ValidationResult] = [
            validateEmail(),
            validatePassword()
        ]

        if let failure = validations.first(where: { !$0.isValid }) {
            return failure
        }

        return .success
    }

    func toLogInRequest() -> LogInRequest {
        LogInRequest(
            email: email.trimmingCharacters(in: .whitespaces),
            password: password
        )
    }
}

// MARK: - Sign Up Form Data
struct SignUpFormData {
    var email: String
    var password: String
    var confirmPassword: String
    var name: String
    var isAgreeToTerms: Bool

    func validateEmail() -> ValidationResult {
        return AuthValidator.validateEmail(email)
    }

    func validatePassword() -> ValidationResult {
        return AuthValidator.validatePassword(password)
    }

    func validateConfirmPassword() -> ValidationResult {
        return AuthValidator.validatePasswordConfirmation(password: password, confirmPassword: confirmPassword)
    }

    func validateName() -> ValidationResult {
        return AuthValidator.validateName(name)
    }

    func validateAll() -> ValidationResult {
        let validations: [ValidationResult] = [
            validateEmail(),
            validatePassword(),
            validateConfirmPassword(),
            validateName(),
        ]

        if let failure = validations.first(where: { !$0.isValid }) {
            return failure
        }

        return .success
    }

    func toSignUpRequest() -> SignUpRequest {
        SignUpRequest(
            email: email.trimmingCharacters(in: .whitespaces),
            password: password,
            name: name.trimmingCharacters(in: .whitespaces),
            provider: .email
        )
    }
}
