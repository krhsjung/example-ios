//
//  ValidationResult.swift
//  example
//
//  Path: Domain/Models/ValidationResult.swift
//  Created by 정희석 on 1/6/26.
//

import Foundation

// MARK: - ValidationResult
enum ValidationResult {
    case success
    case failure(String)

    var isValid: Bool {
        if case .success = self { return true }
        return false
    }

    var errorMessage: String {
        if case .failure(let message) = self { return message }
        return ""
    }
}
