//
//  Validator.swift
//  example
//
//  Path: Domain/Models/Auth/AuthValidator.swift
//  Created by 정희석 on 12/29/25.
//

import Foundation

// MARK: - Validator
struct AuthValidator {
    
    // MARK: - Email Validation
    static func validateEmail(_ email: String) -> ValidationResult {
        guard !email.isEmpty else {
            return .failure(Localized.Auth.validationEmailEmpty)
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            return .failure(Localized.Auth.validationEmailInvalid)
        }
        
        return .success
    }
    
    // MARK: - Password Validation
    static func validatePassword(_ password: String) -> ValidationResult {
        guard !password.isEmpty else {
            return .failure(Localized.Auth.validationPasswordEmpty)
        }
        
        guard password.count >= 8 else {
            return .failure(Localized.Auth.validationPasswordMinLength)
        }
        
        let hasUpperCase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        guard hasUpperCase else {
            return .failure(Localized.Auth.validationPasswordNoUppercase)
        }
        
        let hasLowerCase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        guard hasLowerCase else {
            return .failure(Localized.Auth.validationPasswordNoLowercase)
        }
        
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        guard hasNumber else {
            return .failure(Localized.Auth.validationPasswordNoNumber)
        }
        
        return .success
    }
    
    // MARK: - Password Confirmation Validation
    static func validatePasswordConfirmation(password: String, confirmPassword: String) -> ValidationResult {
        guard !confirmPassword.isEmpty else {
            return .failure(Localized.Auth.validationConfirmPasswordEmpty)
        }
        
        guard password == confirmPassword else {
            return .failure(Localized.Auth.validationPasswordsNotMatch)
        }
        
        return .success
    }
    
    // MARK: - Name Validation
    static func validateName(_ name: String) -> ValidationResult {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return .failure(Localized.Auth.validationNameEmpty)
        }
        
        guard name.count >= 2 else {
            return .failure(Localized.Auth.validationNameMinLength)
        }
        
        return .success
    }
}
