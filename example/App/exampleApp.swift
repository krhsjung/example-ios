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
    @ObservedObject private var authManager = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.background.ignoresSafeArea()

                if authManager.isCheckingSession {
                    ProgressView()
                } else if authManager.isLoggedIn {
                    MainView()
                } else {
                    LogInView()
                }
            }
            .environmentObject(authManager)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // 앱이 활성화될 때 (앱 실행, 백그라운드에서 복귀)
                print("App became active")
                authManager.checkSession()
            case .inactive:
                // 앱이 비활성화될 때
                print("App became inactive")
            case .background:
                // 앱이 백그라운드로 갈 때
                print("App went to background")
            @unknown default:
                break
            }
        }
    }
}
