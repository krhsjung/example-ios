//
//  Color+Extensions.swift
//  example
//
//  Path: Presentation/Views/Extensions/Color.swift
//  Created by 정희석 on 12/17/25.
//

import SwiftUI

extension Color {
    // Background Colors
    static let background = Color(red: 1, green: 0.98, blue: 0.98)
    static let snsButtonBackground = Color(red: 1, green: 0.98, blue: 0.98)
    
    // Brand Colors
    static let brand = Color(red: 0.84, green: 0.15, blue: 0)
    static let primaryButton = Color(red: 1, green: 0.34, blue: 0.2)
    
    // Text Colors
    static let textPrimary = Color(red: 0.16, green: 0.11, blue: 0.1)
    static let textBlack = Color(red: 0.02, green: 0, blue: 0)
    static let textSecondary = Color(red: 0.18, green: 0.1, blue: 0.08).opacity(0.62)
    
    // Border Colors
    static let borderPrimary = Color(red: 0.43, green: 0.31, blue: 0.29).opacity(0.2)
    
    // Divider Colors
    static let dividerLine = Color(red: 0.43, green: 0.31, blue: 0.29).opacity(0.2)
}
