//
//  AuthFormData.swift
//  example
//
//  Path: Domain/Models/Auth/AuthFormData.swift
//  Created by 정희석 on 1/7/26.
//

import Foundation

// MARK: - Validatable Protocol
/// 폼 검증 기능을 제공하는 프로토콜
protocol Validatable {
    /// 모든 검증 결과를 배열로 반환
    var validations: [ValidationResult] { get }
}

extension Validatable {
    /// 모든 검증을 수행하고 첫 번째 실패를 반환
    func validateAll() -> ValidationResult {
        if let failure = validations.first(where: { !$0.isValid }) {
            return failure
        }
        return .success
    }
}

// MARK: - Login Form Data
struct LogInFormData: Validatable {
    var email: String
    var password: String
    private let validator: AuthValidating

    init(
        email: String,
        password: String,
        validator: AuthValidating = AuthValidator.shared
    ) {
        self.email = email
        self.password = password
        self.validator = validator
    }

    var validations: [ValidationResult] {
        [
            validator.validateEmail(email),
            validator.validatePassword(password)
        ]
    }

    func toLogInRequest() -> LogInRequest {
        LogInRequest(
            email: email.trimmingCharacters(in: .whitespaces),
            password: password
        )
    }
}

// MARK: - Sign Up Form Data
struct SignUpFormData: Validatable {
    var email: String
    var password: String
    var confirmPassword: String
    var name: String
    var isAgreeToTerms: Bool
    private let validator: AuthValidating

    init(
        email: String,
        password: String,
        confirmPassword: String,
        name: String,
        isAgreeToTerms: Bool,
        validator: AuthValidating = AuthValidator.shared
    ) {
        self.email = email
        self.password = password
        self.confirmPassword = confirmPassword
        self.name = name
        self.isAgreeToTerms = isAgreeToTerms
        self.validator = validator
    }

    var validations: [ValidationResult] {
        [
            validator.validateEmail(email),
            validator.validatePassword(password),
            validator.validatePasswordConfirmation(password: password, confirmPassword: confirmPassword),
            validator.validateName(name)
        ]
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
