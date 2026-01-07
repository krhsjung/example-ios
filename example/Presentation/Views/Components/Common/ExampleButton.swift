//
//  CustomButton.swift
//  example
//
//  Path: Presentation/Views/Components/Common/ExampleButton.swift
//  Created by 정희석 on 12/17/25.
//

import SwiftUI

struct ExampleButton: View {
    let title: String
    var icon: String? = nil
    var iconSpacing: CGFloat = 10
    var backgroundColor: Color = .primaryButton
    var textColor: Color = .textBlack
    var borderColor: Color? = nil
    var borderWidth: CGFloat = 1.5
    var cornerRadius: CGFloat = 16
    var horizontalPadding: CGFloat = 18
    var verticalPadding: CGFloat = 8
    var minHeight: CGFloat? = nil
    var maxHeight: CGFloat? = nil
    let action: () -> Void  // ✅ trailing closure로 사용하기 위해서 맨 마지막으로 이동!
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: icon != nil ? iconSpacing : 0) {
                if let icon = icon {
                    Image(icon)
                        .frame(width: 20, height: 20)
                }
                
                Text(title)
                    .font(.system(size: 15))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor)
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
                            .inset(by: 0.75)
                            .stroke(borderColor, lineWidth: borderWidth)
                    }
                }
            )
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
        
        // Google SNS 버튼 (trailing closure)
        ExampleButton(
            title: "Continue with Google",
            icon: "google",
            backgroundColor: .snsButtonBackground,
            textColor: .black,
            borderColor: .borderPrimary,
            horizontalPadding: 20,
            minHeight: 36,
            maxHeight: 36
        ) {
            print("Google login tapped")
        }
        
        // Apple SNS 버튼 (trailing closure)
        ExampleButton(
            title: "Continue with Apple",
            icon: "apple",
            backgroundColor: .snsButtonBackground,
            textColor: .black,
            borderColor: .borderPrimary,
            horizontalPadding: 20,
            minHeight: 36,
            maxHeight: 36
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
