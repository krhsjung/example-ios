//
//  ExampleCheckbox.swift
//  example
//
//  Created by 정희석 on 01/15/26.
//

import SwiftUI

struct ExampleCheckbox: View {
    let label: String
    @Binding var isChecked: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: {
                isChecked.toggle()
            }) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .foregroundStyle(isChecked ? AppColor.brand : AppColor.textSecondary)
            }

            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    VStack(spacing: 20) {
        ExampleCheckbox(label: "이용약관에 동의합니다", isChecked: .constant(false))
        ExampleCheckbox(label: "이용약관에 동의합니다", isChecked: .constant(true))
    }
    .padding()
}
