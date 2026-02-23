//
//  SignUpView.swift
//  example
//
//  Path: Presentation/Views/Pages/Auth/SignUpView.swift
//  Created by 정희석 on 12/18/25.
//

import SwiftUI

// MARK: - SignUp Form
/// 회원가입 화면
/// 이메일/비밀번호 입력, 소셜 로그인, 로그인 네비게이션을 제공
struct SignUpView: View {
    @State private var viewModel = SignUpViewModel()
    private var router = ServiceContainer.shared.router

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            TitleSection()
            CredentialsSection(viewModel: viewModel)
            ExampleDividerWithText(text: Localized.Auth.signupContinueWith)
            SocialLoginButtonsView { provider in
                viewModel.signInWith(provider)
            }
            LogInSection {
                viewModel.cancelCurrentTask()
                router.goBack()
            }
        }
        .frame(maxWidth: 450, maxHeight: .infinity)
        .padding(.horizontal, 20)
        // 입력 필드 외부 탭 시 키보드 내리기
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.dismissKeyboard()
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
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
        .pageBackground()
    }
}

// MARK: - Title Section
/// 앱 이름과 회원가입 부제목을 표시하는 상단 타이틀 영역
private struct TitleSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localized.Common.applicationName)
                .font(.system(size: 30))
                .fontWeight(.bold)
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(Localized.Auth.signupSubtitle)
                .font(.system(size: 16))
                .foregroundStyle(AppColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - Credentials Section
/// 이메일/비밀번호/이름 입력 필드와 회원가입 버튼을 포함하는 인증 입력 영역
///
/// 동작:
/// - 포커스 해제(blur) 시 해당 필드만 검증 → 인라인 에러 표시
/// - 타이핑 시 해당 필드의 에러 자동 클리어
/// - 회원가입 버튼 클릭 시 전체 필드 검증 후 회원가입 요청
private struct CredentialsSection: View {
    @Bindable var viewModel: SignUpViewModel

    /// 현재 포커스된 입력 필드 추적 (blur 검증에 사용)
    @FocusState private var focusedField: Field?

    private enum Field {
        case email, password, confirmPassword, name
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AuthInputField(
                label: Localized.Common.email,
                placeholder: Localized.Auth.placeholderEmail,
                text: $viewModel.email,
                error: viewModel.emailError,
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
                focusedField: $focusedField,
                fieldValue: .password,
                onClearError: viewModel.clearPasswordError
            )

            AuthInputField(
                label: Localized.Auth.placeholderConfirmPassword,
                placeholder: Localized.Auth.placeholderConfirmPassword,
                text: $viewModel.confirmPassword,
                isSecure: true,
                error: viewModel.confirmPasswordError,
                focusedField: $focusedField,
                fieldValue: .confirmPassword,
                onClearError: viewModel.clearConfirmPasswordError
            )

            AuthInputField(
                label: Localized.Auth.placeholderName,
                placeholder: Localized.Auth.placeholderName,
                text: $viewModel.name,
                error: viewModel.nameError,
                focusedField: $focusedField,
                fieldValue: .name,
                onClearError: viewModel.clearNameError
            )

            // 이용약관 동의 체크박스
            // "이용약관" 과 "개인정보처리방침"은 linkTextColor로 강조
            ExampleCheckbox(isChecked: $viewModel.isAgreeToTerms) {
                (Text(Localized.Auth.signupTermsOfService).foregroundStyle(AppColor.linkTextColor)
                + Text(Localized.Auth.signupAnd)
                + Text(Localized.Auth.signupPrivacyPolicy).foregroundStyle(AppColor.linkTextColor)
                + Text(Localized.Auth.signupAgreeSuffix))
                    .font(.system(size: 13))
                    .foregroundStyle(AppColor.textSecondary)
            }

            // resignFirstResponder를 UIKit 경로로 호출하여 부드러운 키보드 해제
            ExampleButton(title: Localized.Common.signup) {
                UIApplication.dismissKeyboard()
                viewModel.signUp()
            }
            .disabled(!viewModel.isFormValid)
        }
        // 포커스 해제(blur) 시 이전 필드를 검증
        .onChange(of: focusedField) { oldField, _ in
            switch oldField {
            case .email: viewModel.validateEmail()
            case .password: viewModel.validatePassword()
            case .confirmPassword: viewModel.validateConfirmPassword()
            case .name: viewModel.validateName()
            case nil: break
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - LogIn Section
/// 로그인 화면으로 돌아가기 영역
private struct LogInSection: View {
    let onLogIn: () -> Void

    var body: some View {
        Text(Localized.Common.login)
            .font(Font.footnote.bold())
            .foregroundStyle(AppColor.linkTextColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .onTapGesture {
                onLogIn()
            }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        SignUpView()
    }
}
