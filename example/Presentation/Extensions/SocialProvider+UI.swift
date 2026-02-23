//
//  SocialProvider+UI.swift
//  example
//
//  Path: Presentation/Extensions/SocialProvider+UI.swift
//  Created by Claude on 2/23/26.
//

// MARK: - SocialProvider UI Properties
/// Domain 모델인 SocialProvider의 UI 표시용 프로퍼티
/// Domain 계층의 순수성을 유지하기 위해 Presentation 계층 extension으로 분리
extension SocialProvider {
    /// 버튼에 표시될 제목
    var title: String {
        switch self {
        case .google:
            return Localized.Auth.oauthGoogle
        case .apple:
            return Localized.Auth.oauthApple
        case .native:
            return Localized.Auth.oauthApple + "(native)"
        }
    }

    /// 버튼 아이콘 이름
    var icon: String {
        switch self {
        case .google:
            return "google"
        case .apple, .native:
            return "apple"
        }
    }
}
