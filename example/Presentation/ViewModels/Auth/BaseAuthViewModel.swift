//
//  BaseAuthViewModel.swift
//  example
//
//  Path: Presentation/ViewModels/Auth/BaseAuthViewModel.swift
//  Created by 정희석 on 1/7/26.
//

import SwiftUI
import Combine

@MainActor
class BaseAuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var errorMessage: String = ""
    @Published var showError: Bool = false
    @Published var isLoading: Bool = false

    // MARK: - Dependencies
    let authManager = AuthManager.shared

    // MARK: - Public Methods

    /// SNS 로그인
    func signInWith(_ sns: SnsProvider) {
        performAsyncTask(fallbackError: Localized.Error.errorLoginFailed) {
            try await self.authManager.signInWith(sns)
        }
    }

    /// 에러 메시지 초기화
    func clearError() {
        errorMessage = ""
        showError = false
    }

    // MARK: - Protected Methods

    /// 비동기 작업 수행 (로딩 상태 및 에러 처리 포함)
    func performAsyncTask(
        fallbackError: String,
        action: @escaping () async throws -> Void
    ) {
        Task {
            isLoading = true
            defer { isLoading = false }

            do {
                try await action()
            } catch let error as NetworkError {
                errorMessage = error.localizedDescription
                showError = true
            } catch {
                errorMessage = fallbackError
                showError = true
            }
        }
    }
}
