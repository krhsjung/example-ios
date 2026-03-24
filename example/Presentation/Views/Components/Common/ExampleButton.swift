//
//  ExampleButton.swift
//  example
//
//  Path: Presentation/Views/Components/Common/ExampleButton.swift
//  Created by 정희석 on 12/17/25.
//

import SwiftUI

struct ExampleButton: View {
    let title: String
    var icon: String? = nil
    var iconSpacing: CGFloat = AppDimension.Button.spacing
    var backgroundColor: Color = AppColor.buttonBackground
    var textColor: Color = AppColor.buttonText
    var borderColor: Color? = nil
    var borderWidth: CGFloat = AppDimension.Border.width
    var cornerRadius: CGFloat = AppDimension.CornerRadius.medium
    var horizontalPadding: CGFloat = AppDimension.Button.horizontalPadding
    var verticalPadding: CGFloat = AppDimension.Button.verticalPadding
    var minHeight: CGFloat? = nil
    var maxHeight: CGFloat? = nil
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: icon != nil ? iconSpacing : 0) {
                if let icon = icon {
                    Image(icon)
                        .frame(width: AppDimension.Icon.size, height: AppDimension.Icon.size)
                }

                Text(title)
                    .font(.system(size: AppDimension.FontSize.text))
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(textColor)
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(
                maxWidth: .infinity,
                minHeight: minHeight,
                maxHeight: maxHeight,
                alignment: .center
            )
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                Group {
                    if let borderColor = borderColor {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .inset(by: AppDimension.Border.inset)
                            .stroke(borderColor, lineWidth: borderWidth)
                    }
                }
            )
            .opacity(isEnabled ? 1.0 : 0.5)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // 기본 로그인 버튼 (trailing closure)
        ExampleButton(title: "login") {
            print("Log In tapped")
        }

        // 기본 회원가입 버튼 (trailing closure)
        ExampleButton(title: "Sign Up") {
            print("Sign Up tapped")
        }

        // Google 소셜 버튼 (trailing closure)
        ExampleButton(
            title: "Continue with Google",
            icon: "google",
            backgroundColor: AppColor.socialButtonBackground,
            textColor: .black,
            borderColor: AppColor.socialButtonStroke,
            horizontalPadding: 20,
            minHeight: AppDimension.Button.height,
            maxHeight: AppDimension.Button.height
        ) {
            print("Google login tapped")
        }

        // Apple 소셜 버튼 (trailing closure)
        ExampleButton(
            title: "Continue with Apple",
            icon: "apple",
            backgroundColor: AppColor.socialButtonBackground,
            textColor: .black,
            borderColor: AppColor.socialButtonStroke,
            horizontalPadding: 20,
            minHeight: AppDimension.Button.height,
            maxHeight: AppDimension.Button.height
        ) {
            print("Apple login tapped")
        }

        // 커스텀 색상 버튼 (trailing closure)
        ExampleButton(
            title: "Custom Color",
            backgroundColor: .blue,
            textColor: .white
        ) {
            print("Custom tapped")
        }
    }
    .padding()
}
