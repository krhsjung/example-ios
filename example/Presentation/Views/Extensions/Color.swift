//
//  AppColor.swift
//  example
//
//  Path: Presentation/Views/Extensions/Color.swift
//  Created by 정희석 on 12/17/25.
//

import SwiftUI

/// 앱 전용 Color 네임스페이스
/// Asset Catalog의 Color Set을 참조하여 다크모드 자동 대응
enum AppColor {
    // Background Colors
    static let background = Color("AppBackground")
    static let snsButtonBackground = Color("SnsButtonBackground")
    
    // Text Colors
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")

    // Brand Colors
    static let brand = Color("Brand")
    static let primaryButton = Color("PrimaryButton")
    static let buttonTextColor = Color("ButtonTextColor")

    static let linkTextColor = Color("LinkTextColor")

    // SNS Colors
    static let snsIconColor = Color("SnsIconColor")

    // Border Colors
    static let borderPrimary = Color("BorderPrimary")

    // Divider Colors
    static let dividerLine = Color("DividerLine")

    // Input Box Colors
    static let inputBoxBackground = Color("InputBoxBackground")
    static let placeholderColor = Color("PlaceholderColor")

    // Error Colors
    static let error = Color("ErrorColor")

    // Theme Toggle Colors
    static let themeToggleIcon = Color("ThemeToggleIcon")
    static let themeToggleBackground = Color("ThemeToggleBackground")
    static let themeToggleStrokeColor = Color("ThemeToggleStrokeColor")
}

// MARK: - Page Background
extension View {
    /// NavigationStack 내부 콘텐츠에 배경색을 적용하는 ViewModifier
    ///
    /// NavigationStack은 내부적으로 UINavigationController를 사용하여
    /// 기본 흰색(또는 시스템) 배경을 가지므로, exampleApp의 ZStack 배경이 가려짐.
    /// 이 modifier를 NavigationStack 내부 콘텐츠에 적용하면 해당 배경을 덮어씀.
    ///
    /// 사용 예:
    /// ```swift
    /// NavigationStack {
    ///     VStack { ... }
    ///         .pageBackground()           // 기본: AppColor.background
    ///         .pageBackground(.red)       // 커스텀 색상
    /// }
    /// ```
    func pageBackground(_ color: Color = AppColor.background) -> some View {
        self.background(color.ignoresSafeArea())
    }
}
