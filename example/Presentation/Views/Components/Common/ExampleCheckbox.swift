//
//  ExampleCheckbox.swift
//  example
//
//  Path: Presentation/Views/Components/Common/ExampleCheckbox.swift
//  Created by 정희석 on 01/15/26.
//

import SwiftUI

struct ExampleCheckbox<Label: View>: View {
    @Binding var isChecked: Bool
    @ViewBuilder let label: () -> Label

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: {
                isChecked.toggle()
            }) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(AppColor.checkboxChecked)
            }

            label()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// String 라벨을 사용하는 편의 이니셜라이저
extension ExampleCheckbox where Label == Text {
    init(label: String, isChecked: Binding<Bool>) {
        self._isChecked = isChecked
        self.label = {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(AppColor.textSecondary)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ExampleCheckbox(label: "이용약관에 동의합니다", isChecked: .constant(false))
        ExampleCheckbox(label: "이용약관에 동의합니다", isChecked: .constant(true))
    }
    .padding()
}
