//
//  LogInView.swift
//  example
//
//  Path: Presentation/Views/Pages/Auth/LogInView.swift
//  Created by 정희석 on 12/17/25.
//

import SwiftUI

// MARK: - Login Form
/// 로그인 화면
/// 이메일/비밀번호 입력, 소셜 로그인, 회원가입 네비게이션을 제공
struct LogInView: View {
    @State private var viewModel = LogInViewModel()
    private var router = ServiceContainer.shared.router

    var body: some View {
        VStack(alignment: .leading, spacing: AppDimension.Spacing.section) {
            TitleSection()
            CredentialsSection(viewModel: viewModel)
            ExampleDividerWithText(text: Localized.Auth.loginContinueWith)
            SocialLoginButtonsView { provider in
                viewModel.signInWith(provider)
            }
            SignUpSection {
                router.navigate(to: .signUp)
            }
        }
        .frame(maxWidth: AppDimension.Screen.maxWidth, maxHeight: .infinity)
        .padding(.horizontal, AppDimension.Screen.horizontalPadding)
        // 입력 필드 외부 탭 시 키보드 내리기
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.dismissKeyboard()
        }
        .ignoresSafeArea(.keyboard)
        .exampleLoadingOverlay(isLoading: viewModel.isLoading)
        .exampleErrorAlert(
            isPresented: $viewModel.showError,
            message: viewModel.errorMessage,
            onRetry: viewModel.retryLastAction,
            onDismiss: viewModel.clearError
        )
        .onDisappear {
            viewModel.cancelCurrentTask()
        }
        // NavigationStack 내부 배경색 적용
        // (NavigationStack의 기본 흰색 배경을 AppColor.background로 덮어씀)
        .pageBackground()
        .overlay(alignment: .topTrailing) {
            ExampleThemeToggle()
                .padding(.trailing, AppDimension.Screen.horizontalPadding)
        }
    }
}

// MARK: - Title Section
/// 앱 이름과 로그인 부제목을 표시하는 상단 타이틀 영역
private struct TitleSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppDimension.Spacing.inner) {
            Text(Localized.Common.applicationName)
                .font(.system(size: AppDimension.FontSize.title))
                .fontWeight(.bold)
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(Localized.Auth.loginSubtitle)
                .font(.system(size: AppDimension.FontSize.subtitle))
                .foregroundStyle(AppColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - Credentials Section
/// 이메일/비밀번호 입력 필드와 로그인 버튼을 포함하는 인증 입력 영역
///
/// 동작:
/// - 포커스 해제(blur) 시 해당 필드만 검증 → 인라인 에러 표시
/// - 타이핑 시 해당 필드의 에러 자동 클리어
/// - 로그인 버튼 클릭 시 전체 필드 검증 후 로그인 요청
private struct CredentialsSection: View {
    @Bindable var viewModel: LogInViewModel

    /// 현재 포커스된 입력 필드 추적 (blur 검증에 사용)
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppDimension.Spacing.field) {
            AuthInputField(
                label: Localized.Common.email,
                placeholder: Localized.Auth.placeholderEmail,
                text: $viewModel.email,
                error: viewModel.emailError,
                leadingIcon: "envelope",
                focusedField: $focusedField,
                fieldValue: .email,
                onClearError: viewModel.clearEmailError
            )

            AuthInputField(
                label: Localized.Common.password,
                placeholder: Localized.Auth.placeholderPassword,
                text: $viewModel.password,
                isSecure: true,
                error: viewModel.passwordError,
                leadingIcon: "lock",
                focusedField: $focusedField,
                fieldValue: .password,
                onClearError: viewModel.clearPasswordError
            )

            Text(Localized.Auth.loginForgetPassword)
              .font(.system(size: AppDimension.FontSize.text))
              .foregroundStyle(AppColor.linkText)
              .frame(maxWidth: .infinity, alignment: .trailing)

            // resignFirstResponder를 UIKit 경로로 호출하여
            // SwiftUI 상태 변경(focusedField = nil)과 달리 부드러운 키보드 해제
            ExampleButton(title: Localized.Common.login) {
                UIApplication.dismissKeyboard()
                viewModel.logIn()
            }
        }
        // 포커스 해제(blur) 시 이전 필드를 검증
        // oldField: 포커스를 잃은 필드 → 해당 필드만 검증
        .onChange(of: focusedField) { oldField, _ in
            switch oldField {
            case .email: viewModel.validateEmail()
            case .password: viewModel.validatePassword()
            case nil: break
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - SignUp Section
/// 회원가입 버튼 영역
/// 탭 시 SignUpView로 네비게이션
private struct SignUpSection: View {
    let onSignUp: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: AppDimension.Spacing.inner) {
            Text(Localized.Auth.loginNoAccount)
                .font(.system(size: AppDimension.FontSize.text))
                .foregroundStyle(AppColor.textSecondary)

            Text(Localized.Common.signup)
                .font(.system(size: AppDimension.FontSize.text))
                .fontWeight(.medium)
                .foregroundStyle(AppColor.linkText)
                .onTapGesture {
                    onSignUp()
                }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        LogInView()
    }
}
