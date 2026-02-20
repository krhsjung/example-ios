//
//  ExampleThemeToggle.swift
//  example
//
//  Path: Presentation/Views/Components/Common/ExampleThemeToggle.swift
//  Created by 정희석 on 2/19/26.
//

import SwiftUI

/// 라이트/다크 모드 전환 토글 버튼
///
/// React의 ThemeToggle 컴포넌트와 동일한 구조:
/// - 라이트 모드: 달(moon) 아이콘 표시 → 다크 모드로 전환
/// - 다크 모드: 해(sun) 아이콘 표시 → 라이트 모드로 전환
/// - 테마 설정을 UserDefaults에 저장하여 앱 재시작 시에도 유지
struct ExampleThemeToggle: View {
    /// exampleApp의 @AppStorage("theme")와 동일한 키를 공유
    /// 이 값을 토글하면 exampleApp에서 .preferredColorScheme이 변경되어
    /// 앱 전체의 라이트/다크 모드가 전환됨
    @AppStorage("theme") private var isDarkMode: Bool = false

    var body: some View {
        Button {
            isDarkMode.toggle()
        } label: {
            // 라이트 모드: moon 아이콘 (다크 모드로 전환 유도)
            // 다크 모드: sun 아이콘 (라이트 모드로 전환 유도)
            Image(systemName: isDarkMode ? "sun.max.fill" : "moon")
                .font(.system(size: 18))
                // Asset Catalog 기반 색상 — 다크/라이트 자동 대응
                .foregroundStyle(AppColor.themeToggleIcon)
                .frame(width: 40, height: 40)
                .background(AppColor.themeToggleBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppColor.borderPrimary, lineWidth: 1.5)
                )
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ExampleThemeToggle()
        ExampleThemeToggle()
            .environment(\.colorScheme, .dark)
    }
    .padding()
}
