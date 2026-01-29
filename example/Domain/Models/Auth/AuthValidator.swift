//
//  Validator.swift
//  example
//
//  Path: Domain/Models/Auth/AuthValidator.swift
//  Created by 정희석 on 12/29/25.
//

import Foundation

// MARK: - Auth Validating Protocol
/// 인증 관련 유효성 검사 프로토콜
/// 테스트 시 Mock 객체로 대체 가능
protocol AuthValidating {
    func validateEmail(_ email: String) -> ValidationResult
    func validatePassword(_ password: String) -> ValidationResult
    func validatePasswordConfirmation(password: String, confirmPassword: String) -> ValidationResult
    func validateName(_ name: String) -> ValidationResult
}

// MARK: - Auth Validator
/// 인증 관련 유효성 검사 구현체
struct AuthValidator: AuthValidating {
    /// 공유 인스턴스 (기본값으로 사용)
    static let shared = AuthValidator()

    // MARK: - Email Validation
    func validateEmail(_ email: String) -> ValidationResult {
        guard !email.isEmpty else {
            return .failure(Localized.Error.errorEmptyEmail)
        }

        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        guard emailPredicate.evaluate(with: email) else {
            return .failure(Localized.Error.errorInvalidEmail)
        }

        return .success
    }

    // MARK: - Password Validation
    func validatePassword(_ password: String) -> ValidationResult {
        guard !password.isEmpty else {
            return .failure(Localized.Error.errorEmptyPassword)
        }

        guard password.count >= 8 else {
            return .failure(Localized.Error.errorWeakPassword)
        }

        let hasUpperCase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        guard hasUpperCase else {
            return .failure(Localized.Error.errorPasswordNoUppercase)
        }

        let hasLowerCase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        guard hasLowerCase else {
            return .failure(Localized.Error.errorPasswordNoLowercase)
        }

        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        guard hasNumber else {
            return .failure(Localized.Error.errorPasswordNoNumber)
        }

        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;':\",./<>?`~")
        let hasSpecialCharacter = password.unicodeScalars.contains(where: { specialCharacters.contains($0) })
        guard hasSpecialCharacter else {
            return .failure(Localized.Error.errorPasswordNoSpecialCharacter)
        }

        return .success
    }

    // MARK: - Password Confirmation Validation
    func validatePasswordConfirmation(password: String, confirmPassword: String) -> ValidationResult {
        guard !confirmPassword.isEmpty else {
            return .failure(Localized.Error.errorEmptyConfirmPassword)
        }

        guard password == confirmPassword else {
            return .failure(Localized.Error.errorPasswordNotMatch)
        }

        return .success
    }

    // MARK: - Name Validation
    func validateName(_ name: String) -> ValidationResult {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(Localized.Error.errorEmptyUsername)
        }

        guard name.count >= 2 else {
            return .failure(Localized.Error.errorNameMinLength)
        }

        return .success
    }
}

#if DEBUG
// MARK: - Mock Auth Validator
/// 테스트용 Mock Validator
/// 항상 성공 또는 실패를 반환하도록 설정 가능
struct MockAuthValidator: AuthValidating {
    var emailResult: ValidationResult = .success
    var passwordResult: ValidationResult = .success
    var confirmPasswordResult: ValidationResult = .success
    var nameResult: ValidationResult = .success

    func validateEmail(_ email: String) -> ValidationResult {
        emailResult
    }

    func validatePassword(_ password: String) -> ValidationResult {
        passwordResult
    }

    func validatePasswordConfirmation(password: String, confirmPassword: String) -> ValidationResult {
        confirmPasswordResult
    }

    func validateName(_ name: String) -> ValidationResult {
        nameResult
    }

    /// 모든 검증이 성공하는 Mock
    static let alwaysSuccess = MockAuthValidator()

    /// 모든 검증이 실패하는 Mock
    static let alwaysFailing = MockAuthValidator(
        emailResult: .failure("Mock email error"),
        passwordResult: .failure("Mock password error"),
        confirmPasswordResult: .failure("Mock confirm password error"),
        nameResult: .failure("Mock name error")
    )
}
#endif
