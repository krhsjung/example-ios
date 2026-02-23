//
//  SocialLoginButtonsView.swift
//  example
//
//  Path: Presentation/Views/Components/Auth/SocialLoginButtonsView.swift
//  Created by 정희석 on 12/25/25.
//

import SwiftUI

struct SocialLoginButtonsView: View {
    let onSocialLogin: (_ provider: SocialProvider) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            ForEach(SocialProvider.allCases, id: \.self) { provider in
                ExampleButton(
                    title: provider.title,
                    icon: provider.icon,
                    backgroundColor: AppColor.socialButtonBackground,
                    textColor: AppColor.socialColor,
                    borderColor: AppColor.socialButtonStroke,
                    horizontalPadding: 20,
                    minHeight: 36,
                    maxHeight: 36
                ) {
                    onSocialLogin(provider)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

#Preview {
    SocialLoginButtonsView { provider in
        print("Social Login: \(provider)")
    }
}
