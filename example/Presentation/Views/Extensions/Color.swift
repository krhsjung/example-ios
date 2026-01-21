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

    // Brand Colors
    static let brand = Color("Brand")
    static let primaryButton = Color("PrimaryButton")

    // Text Colors
    static let textPrimary = Color("TextPrimary")
    static let textBlack = Color("TextBlack")
    static let textSecondary = Color("TextSecondary")

    // Border Colors
    static let borderPrimary = Color("BorderPrimary")

    // Divider Colors
    static let dividerLine = Color("DividerLine")

    // Input Box Colors
    static let inputBoxBackground = Color("InputBoxBackground")
    static let placeholderColor = Color("PlaceholderColor")
}
