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
/// 이메일/비밀번호 입력, SNS 로그인, 회원가입 네비게이션을 제공
struct LogInView: View {
    @State private var viewModel = LogInViewModel()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                TitleSection()
                CredentialsSection(viewModel: viewModel)
                ExampleDividerWithText(text: Localized.Auth.loginContinueWith)
                SocialLoginButtonsView { provider in
                    viewModel.signInWith(provider)
                }
                SignupSection {
                    viewModel.navigateToSignUp()
                }
            }
            .frame(maxWidth: 450, maxHeight: .infinity)
            .padding(.horizontal, 20)
            // 입력 필드 외부 탭 시 키보드 내리기
            // contentShape(Rectangle())로 빈 영역도 탭 가능하게 설정
            // resignFirstResponder를 UIKit 경로로 호출하여 부드러운 키보드 해제
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
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
            // NavigationStack 내부 배경색 적용
            // (NavigationStack의 기본 흰색 배경을 AppColor.background로 덮어씀)
            .pageBackground()
        }
        .overlay(alignment: .topTrailing) {
            ExampleThemeToggle()
                .padding(.trailing, 20)
        }
    }
}

// MARK: - Title Section
/// 앱 이름과 로그인 부제목을 표시하는 상단 타이틀 영역
private struct TitleSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Localized.Common.applicationName)
                .font(.system(size: 30))
                .fontWeight(.bold)
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(Localized.Auth.loginSubtitle)
                .font(.system(size: 16))
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
        VStack(alignment: .leading, spacing: 16) {
            // 이메일 필드
            VStack(alignment: .leading, spacing: 8) {
                Text(Localized.Common.email)
                    .font(Font.caption.bold())
                    .foregroundStyle(AppColor.textPrimary)
                ExampleInputBox(
                    placeholder: Localized.Common.email,
                    text: $viewModel.email,
                    hasError: viewModel.emailError != nil
                )
                .focused($focusedField, equals: .email)
                .onChange(of: viewModel.email) {
                    viewModel.clearEmailError()
                }
                // 이메일 에러 메시지 (에러가 있을 때만 표시)
                if let emailError = viewModel.emailError {
                    Text(emailError)
                        .font(.system(size: 14))
                        .foregroundStyle(AppColor.error)
                }
            }

            // 비밀번호 필드
            VStack(alignment: .leading, spacing: 8) {
                Text(Localized.Common.password)
                    .font(Font.caption.bold())
                    .foregroundStyle(AppColor.textPrimary)
                ExampleInputBox(
                    placeholder: Localized.Common.password,
                    text: $viewModel.password,
                    isSecure: true,
                    hasError: viewModel.passwordError != nil
                )
                .focused($focusedField, equals: .password)
                .onChange(of: viewModel.password) {
                    viewModel.clearPasswordError()
                }
                // 비밀번호 에러 메시지 (에러가 있을 때만 표시)
                if let passwordError = viewModel.passwordError {
                    Text(passwordError)
                        .font(.system(size: 14))
                        .foregroundStyle(AppColor.error)
                }
            }
            
            Text(Localized.Auth.loginForgetPassword)
              .font(Font.custom("Inter", size: 14))
              .foregroundColor(AppColor.linkTextColor)
              .frame(maxWidth: .infinity, alignment: .trailing)

            // resignFirstResponder를 UIKit 경로로 호출하여
            // SwiftUI 상태 변경(focusedField = nil)과 달리 부드러운 키보드 해제
            ExampleButton(title: Localized.Common.login) {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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

// MARK: - Signup Section
/// 회원가입 버튼 영역
/// 탭 시 SignUpView로 네비게이션
private struct SignupSection: View {
    let onSignup: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(Localized.Auth.loginNoAccount)
                .font(Font.footnote.bold())
            
            Text(Localized.Common.signup)
                .font(Font.footnote.bold())
                .foregroundColor(AppColor.linkTextColor)
                .onTapGesture {
                    onSignup()
                }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Preview
#Preview {
    LogInView()
}
