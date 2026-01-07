//
//  SignUpView.swift
//  example
//
//  Path: Presentation/Views/Pages/Auth/SignUpView.swift
//  Created by 정희석 on 12/18/25.
//

import SwiftUI

/// 회원가입 메인 뷰
/// 이메일/비밀번호 기반 회원가입 및 소셜 로그인(Google, Apple)을 제공
struct SignUpView: View {
    /// 회원가입 로직을 처리하는 ViewModel
    @StateObject private var viewModel = SignUpViewModel()
    /// 현재 뷰를 닫기 위한 환경 변수
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ExamplePageLayout(
            header: {
                SignUpHeaderView()
            },
            container: {
                SignUpContainerView(viewModel: viewModel)
            },
            footer: {
                SignUpFooterView(dismiss: dismiss)
            }
        )
        .padding(.horizontal, 20)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .exampleLoadingOverlay(isLoading: viewModel.isLoading)
        .exampleErrorAlert(
            isPresented: $viewModel.showError,
            message: viewModel.errorMessage,
            onDismiss: viewModel.clearError
        )
    }
}

// MARK: - Header
/// 회원가입 화면 상단 헤더
/// 타이틀과 서브타이틀을 중앙 정렬로 표시
struct SignUpHeaderView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // 메인 타이틀 (예: "회원가입")
            Text(Localized.Auth.signupTitle)
                .font(.system(size: 28))
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            // 서브 타이틀 (설명 텍스트)
            Text(Localized.Auth.signupSubtitle)
                .font(.system(size: 15))
                .foregroundColor(.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .center) // 전체 너비를 차지하며 중앙 정렬
        .padding(.top, 30)
    }
}

// MARK: - Container
/// 회원가입 화면의 메인 컨텐츠 영역
/// 회원가입 폼과 소셜 로그인 버튼들을 포함
struct SignUpContainerView: View {
    @ObservedObject var viewModel: SignUpViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            // 이메일/비밀번호 입력 폼
            SignUpFormView(viewModel: viewModel)

            // 구분선
            ExampleDividerWithText(text: Localized.Auth.signupContinueWith)

            // Google, Apple 소셜 로그인 버튼
            SocialLoginButtonsView { provider in
                viewModel.signInWith(provider)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 32)
    }
}

// MARK: - Form
/// 회원가입 입력 폼
/// 이메일, 비밀번호, 비밀번호 확인, 이름 입력 필드와 약관 동의 체크박스, 회원가입 버튼 포함
struct SignUpFormView: View {
    @ObservedObject var viewModel: SignUpViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 이메일 입력
            ExampleInputBox(placeholder: Localized.Auth.placeholderEmailPlaceholder, text: $viewModel.email)
            // 비밀번호 입력 (보안 필드)
            ExampleInputBox(placeholder: Localized.Auth.placeholderPasswordPlaceholder, text: $viewModel.password, isSecure: true)
            // 비밀번호 확인 입력 (보안 필드)
            ExampleInputBox(placeholder: Localized.Auth.placeholderConfirmPasswordPlaceholder, text: $viewModel.confirmPassword, isSecure: true)
            // 이름 입력
            ExampleInputBox(placeholder: Localized.Auth.placeholderNamePlaceholder, text: $viewModel.name)
            
            // 이용약관 동의 체크박스
            TermsAgreementCheckbox(isAgreed: $viewModel.isAgreeToTerms)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        
        // Button 영역
        VStack(alignment: .leading, spacing: 18) {
            // 회원가입 버튼 (폼 유효성 검사에 따라 활성화/비활성화)
            ExampleButton(title: Localized.Common.signup) {
                viewModel.signUp()
            }
            .disabled(!viewModel.isFormValid) // 폼이 유효하지 않으면 비활성화
            .opacity(viewModel.isFormValid ? 1.0 : 0.5) // 비활성화 시 투명도 조절
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

// MARK: - Terms Agreement Checkbox
/// 이용약관 동의 체크박스
/// 사용자가 약관에 동의했는지 표시하고 토글할 수 있는 UI 제공
struct TermsAgreementCheckbox: View {
    @Binding var isAgreed: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            // 체크박스 버튼
            Button(action: {
                isAgreed.toggle() // 동의 상태 토글
            }) {
                // 동의 여부에 따라 체크된 아이콘 또는 빈 사각형 표시
                Image(systemName: isAgreed ? "checkmark.square.fill" : "square")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundColor(isAgreed ? .brand : .textSecondary) // 동의 시 브랜드 컬러, 미동의 시 회색
            }
            
            // 약관 동의 텍스트
            Text(Localized.Auth.signupContinueWith)
                .font(.system(size: 13))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Footer
/// 회원가입 화면 하단 푸터
/// 로그인 화면으로 돌아가기 버튼 제공
struct SignUpFooterView: View {
    let dismiss: DismissAction

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            // 로그인 화면으로 돌아가기 버튼
            Button(action: { dismiss() }) {
                Text(Localized.Common.login)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.brand)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40)
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
    .environmentObject(AuthManager.shared)
}
