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
            ExampleButton(
                title: Localized.Auth.oauthGoogle,
                icon: "google",
                backgroundColor: .snsButtonBackground,
                textColor: .black,
                borderColor: .borderPrimary,
                horizontalPadding: 20,
                minHeight: 36,
                maxHeight: 36
            ) {
                onSnsLogin(.google)
            }

            ExampleButton(
                title: Localized.Auth.oauthApple,
                icon: "apple",
                backgroundColor: .snsButtonBackground,
                textColor: .black,
                borderColor: .borderPrimary,
                horizontalPadding: 20,
                minHeight: 36,
                maxHeight: 36
            ) {
                onSnsLogin(.apple)
            }
            
            ExampleButton(
                title: Localized.Auth.oauthApple + "(native)",
                icon: "apple",
                backgroundColor: .snsButtonBackground,
                textColor: .black,
                borderColor: .borderPrimary,
                horizontalPadding: 20,
                minHeight: 36,
                maxHeight: 36
            ) {
                onSnsLogin(.native)
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
