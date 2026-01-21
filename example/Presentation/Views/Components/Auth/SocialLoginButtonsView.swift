//
//  SocialLoginButtonsView.swift
//  example
//
//  Path: Presentation/Views/Components/Auth/SocialLoginButtonsView.swift
//  Created by 정희석 on 12/25/25.
//

import SwiftUI

struct SocialLoginButtonsView: View {
    let onSnsLogin: (_ snsProvider: SnsProvider) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            ForEach(SnsProvider.allCases, id: \.self) { provider in
                ExampleButton(
                    title: provider.title,
                    icon: provider.icon,
                    backgroundColor: AppColor.snsButtonBackground,
                    textColor: .black,
                    borderColor: AppColor.borderPrimary,
                    horizontalPadding: 20,
                    minHeight: 36,
                    maxHeight: 36
                ) {
                    onSnsLogin(provider)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

#Preview {
    SocialLoginButtonsView { provider in
        print("SNS Login: \(provider)")
    }
}
