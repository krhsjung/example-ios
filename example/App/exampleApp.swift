//
//  exampleApp.swift
//  example
//
//  Path: App/exampleApp.swift
//  Created by 정희석 on 12/17/25.
//

import SwiftUI

@main
struct exampleApp: App {
    @Environment(\.scenePhase) private var scenePhase

    /// ExampleThemeToggle과 동일한 UserDefaults 키("theme")를 공유하여
    /// 토글에서 값을 변경하면 여기서 읽어 앱 전체 colorScheme에 반영
    @AppStorage("theme") private var isDarkMode: Bool = false
    private var authManager = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                // NavigationStack이 없는 화면(ProgressView 등)의 배경색
                // NavigationStack이 있는 화면은 .pageBackground()로 별도 적용 필요
                AppColor.background.ignoresSafeArea()

                if authManager.isCheckingSession {
                    ProgressView()
                } else if authManager.isLoggedIn {
                    MainView()
                } else {
                    LogInView()
                }
            }
            // isDarkMode 값에 따라 앱 전체 라이트/다크 모드 전환
            // Asset Catalog의 Color Set이 자동으로 해당 모드의 색상을 적용
            .preferredColorScheme(isDarkMode ? .dark : .light)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // 앱이 활성화될 때 (앱 실행, 백그라운드에서 복귀)
                Log.info("App became active")
                authManager.checkSession()
            case .inactive:
                // 앱이 비활성화될 때
                Log.info("App became inactive")
            case .background:
                // 앱이 백그라운드로 갈 때
                Log.info("App went to background")
            @unknown default:
                break
            }
        }
    }
}
