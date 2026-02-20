//
//  CustomInputBox.swift
//  example
//
//  Created by 정희석 on 12/17/25.
//

import SwiftUI

struct ExampleInputBox: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    /// 에러 상태 (true이면 빨간 border 표시)
    var hasError: Bool = false

    /// 비밀번호 표시/숨김 토글 상태
    @State private var isPasswordVisible = false

    var body: some View {
        HStack(spacing: 8) {
            Group {
                if isSecure {
                    SecureTextField(
                        placeholder: placeholder,
                        text: $text,
                        isSecureEntry: !isPasswordVisible
                    )
                } else {
                    TextField(placeholder, text: $text)
                        .font(.system(size: 15))
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
            .frame(maxWidth: .infinity)

            // 비밀번호 표시/숨김 토글 아이콘
            if isSecure {
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                        .font(.system(size: 14))
                        .foregroundStyle(AppColor.placeholderColor)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 20)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.inputBoxBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .inset(by: 0.75)
                .stroke(hasError ? AppColor.error : .black.opacity(0), lineWidth: 1.5)
        )
    }
}

struct SecureTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    /// 보안 입력 모드 (true: 마스킹, false: 평문 표시)
    var isSecureEntry: Bool = true

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.isSecureTextEntry = isSecureEntry
        textField.delegate = context.coordinator
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.font = .systemFont(ofSize: 15)
        textField.textColor = UIColor(named: "TextPrimary") ?? .label
        textField.borderStyle = .none

        // Content hugging과 compression resistance 설정
        textField.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textField.setContentCompressionResistancePriority(.required, for: .vertical)

        // Placeholder 설정
        textField.placeholder = placeholder

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        // 보안 모드 토글 시 텍스트 유지를 위해 재설정
        if uiView.isSecureTextEntry != isSecureEntry {
            uiView.isSecureTextEntry = isSecureEntry
            let existingText = uiView.text
            uiView.text = nil
            uiView.text = existingText
        }
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        let parent: SecureTextField

        init(_ parent: SecureTextField) {
            self.parent = parent
        }

        func textField(
            _ textField: UITextField,
            shouldChangeCharactersIn range: NSRange,
            replacementString string: String
        ) -> Bool {

            guard let currentText = textField.text,
                  let textRange = Range(range, in: currentText)
            else { return false }

            let updatedText = currentText.replacingCharacters(in: textRange, with: string)
            parent.text = updatedText
            return false
        }
    }
}


// Placeholder 텍스트의 색상을 커스터마이징하려면 이 방식을 사용할 수 있습니다
struct ExampleInputBoxWithPlaceholder: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if isSecure {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15))
                        .foregroundStyle(AppColor.placeholderColor)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                } else {
                    SecureField("", text: $text)
                        .font(.system(size: 15))
                        .foregroundStyle(AppColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            } else {
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.system(size: 15))
                            .foregroundStyle(AppColor.placeholderColor)
                    }
                    TextField("", text: $text)
                        .font(.system(size: 15))
                        .foregroundStyle(AppColor.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.inputBoxBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .inset(by: 0.75)
                .stroke(.black.opacity(0), lineWidth: 1.5)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        ExampleInputBox(placeholder: "Email", text: .constant(""))
        ExampleInputBox(placeholder: "Password", text: .constant(""), isSecure: true)
        
        ExampleInputBoxWithPlaceholder(placeholder: "Email", text: .constant(""))
        ExampleInputBoxWithPlaceholder(placeholder: "Password", text: .constant(""), isSecure: true)
    }
    .padding()
}
