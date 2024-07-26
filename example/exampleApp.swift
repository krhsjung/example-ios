//
//  exampleApp.swift
//  example
//
//  Created by 정희석 on 7/24/24.
//

import SwiftUI

@main
struct exampleApp: App {
    // 아래의 AppDelegate UIApplication에 등록합니다.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // SwiftUI에서 초기 설정하거나 필요한 리소스를 가져오는데 사용됩니다.
    init() {
        Log.debug("Init application")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    // 앱이 시작될 때 호출됩니다. 초기 설정을 하거나 필요한 리소스를 로드하는 데 사용됩니다.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Log.debug("Finish app launching")
        return true
    }
}
