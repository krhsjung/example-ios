//
//  LogInView.swift
//  example
//
//  Path: Presentation/Views/Pages/Auth/LogInView.swift
//  Created by 정희석 on 12/17/25.
//

import SwiftUI

struct LogInView: View {
    @State private var viewModel = LogInViewModel()

    var body: some View {
        NavigationStack {
            ExamplePageLayout(
                header: {
                    LogInHeaderView()
                },
                container: {
                    LogInContainerView(viewModel: viewModel)
                },
                footer: {
                    LogInFooterView()
                }
            )
            .padding(.horizontal, 20)
            .navigationDestination(isPresented: $viewModel.isNavigateToSignUp) {
                SignUpView()
            }
            .exampleLoadingOverlay(isLoading: viewModel.isLoading)
            .exampleErrorAlert(
                isPresented: $viewModel.showError,
                message: viewModel.errorMessage,
                onDismiss: viewModel.clearError
            )
            .onDisappear {
                viewModel.cancelCurrentTask()
            }
        }
    }
}

// MARK: - Header
struct LogInHeaderView: View {
    var body: some View {
        HStack {
            Text(Localized.Common.applicationName)
                .font(.system(size: 28))
                .fontWeight(.bold)
                .foregroundStyle(AppColor.brand)
        }
        .padding(.horizontal, 0)
        .padding(.vertical, 18)
        .frame(minHeight: 50, maxHeight: 50)
    }
}

// MARK: - Container
struct LogInContainerView: View {
    @Bindable var viewModel: LogInViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            LogInDescriptionView()
            LogInFormView(viewModel: viewModel)
            ExampleDividerWithText(text: Localized.Auth.loginContinueWith)
            SocialLoginButtonsView { provider in
                viewModel.signInWith(provider)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Description
struct LogInDescriptionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localized.Auth.loginTitle)
                .font(.system(size: 28))
                .fontWeight(.bold)
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            Text(Localized.Auth.loginSubtitle)
                .font(.system(size: 15))
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - Form
struct LogInFormView: View {
    @Bindable var viewModel: LogInViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 18) {
                ExampleInputBox(placeholder: Localized.Common.email, text: $viewModel.email)
                ExampleInputBox(placeholder: Localized.Common.password, text: $viewModel.password, isSecure: true)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            VStack(alignment: .leading, spacing: 18) {
                ExampleButton(title: Localized.Common.login) {
                    viewModel.logIn()
                }
                ExampleButton(title: Localized.Common.signup) {
                    viewModel.navigateToSignUp()
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - Footer
struct LogInFooterView: View {
    var body: some View {
        Spacer()
            .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40)
    }
}

// MARK: - Preview
#Preview {
    LogInView()
}
