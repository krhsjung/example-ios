//
//  Dimension.swift
//  example
//
//  Path: Presentation/Views/Extensions/Dimension.swift
//  Created by Claude on 02/25/26.
//

import SwiftUI

/// 앱 전용 Dimension 네임스페이스
/// Figma 디자인 토큰과 1:1 매핑되는 치수 값
enum AppDimension {

    // MARK: - Font Size
    enum FontSize {
        static let title: CGFloat = 30
        static let subtitle: CGFloat = 16
        static let text: CGFloat = 14
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let medium: CGFloat = 8
    }

    // MARK: - Border
    enum Border {
        static let width: CGFloat = 1.5
        static let inset: CGFloat = 0.75
    }

    // MARK: - Icon
    enum Icon {
        static let size: CGFloat = 20
    }

    // MARK: - Spacing
    enum Spacing {
        static let section: CGFloat = 20
        static let field: CGFloat = 16
        static let inner: CGFloat = 8
    }

    // MARK: - Screen
    enum Screen {
        static let maxWidth: CGFloat = 450
        static let horizontalPadding: CGFloat = 25
    }

    // MARK: - Input
    enum Input {
        static let contentHeight: CGFloat = 20
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 8
    }

    // MARK: - Button
    enum Button {
        static let horizontalPadding: CGFloat = 18
        static let verticalPadding: CGFloat = 8
        static let spacing: CGFloat = 10
        static let height: CGFloat = 36
    }

    // MARK: - Divider
    enum Divider {
        static let lineHeight: CGFloat = 1.5
    }
}
