//
//  AuthInputField.swift
//  example
//
//  Path: Presentation/Views/Components/Auth/AuthInputField.swift
//  Created by 정희석 on 02/23/26.
//

import SwiftUI

/// 인증 폼용 입력 필드 컴포넌트
/// 라벨 + 입력박스 + 에러 메시지를 하나의 단위로 묶음
///
/// - 포커스 바인딩 지원 (blur 검증용)
/// - 타이핑 시 에러 자동 클리어
/// - 에러 시 빨간 border + 인라인 에러 텍스트
struct AuthInputField<FocusValue: Hashable>: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var error: String?
    var leadingIcon: String? = nil
    var focusedField: FocusState<FocusValue?>.Binding
    var fieldValue: FocusValue
    var onClearError: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppDimension.Spacing.inner) {
            Text(label)
                .font(.system(size: AppDimension.FontSize.text))
                .fontWeight(.medium)
                .foregroundStyle(AppColor.textPrimary)
            ExampleInputBox(
                placeholder: placeholder,
                text: $text,
                isSecure: isSecure,
                hasError: error != nil,
                leadingIcon: leadingIcon
            )
            .focused(focusedField, equals: fieldValue)
            .onChange(of: text) {
                onClearError()
            }
            if let error = error {
                Text(error)
                    .font(.system(size: AppDimension.FontSize.text))
                    .foregroundStyle(AppColor.error)
            }
        }
    }
}
