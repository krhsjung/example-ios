//
//  ExampleDividerWithText.swift
//  example
//
//  Path: Presentation/Views/Components/Common/ExampleDividerWithText.swift
//  Created by 정희석 on 12/25/25.
//

import SwiftUI

/// 텍스트가 포함된 구분선 컴포넌트 (재사용 가능)
struct ExampleDividerWithText: View {
    let text: String
    let textColor: Color
    let lineColor: Color
    let lineHeight: CGFloat

    init(
        text: String,
        textColor: Color = AppColor.textSecondary,
        lineColor: Color = AppColor.dividerLine,
        lineHeight: CGFloat = AppDimension.Divider.lineHeight
    ) {
        self.text = text
        self.textColor = textColor
        self.lineColor = lineColor
        self.lineHeight = lineHeight
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppDimension.Spacing.inner) {
            Rectangle()
                .fill(lineColor)
                .frame(maxWidth: .infinity, minHeight: lineHeight, maxHeight: lineHeight)

            Text(text)
                .font(.system(size: AppDimension.FontSize.text))
                .foregroundStyle(textColor)
                .fixedSize(horizontal: true, vertical: false)

            Rectangle()
                .fill(lineColor)
                .frame(maxWidth: .infinity, minHeight: lineHeight, maxHeight: lineHeight)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    VStack(spacing: 20) {
        ExampleDividerWithText(text: "또는")
        ExampleDividerWithText(text: "signup_continue_with")
        ExampleDividerWithText(text: "Custom", textColor: .red, lineColor: .blue)
    }
    .padding()
}
