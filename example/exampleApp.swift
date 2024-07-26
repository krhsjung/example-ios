//
//  exampleApp.swift
//  example
//
//  Created by 정희석 on 7/24/24.
//

import SwiftUI
import CryptoSwift
import FirebaseCore
import FirebaseMessaging

@main
struct ExampleApp: App {
    // 아래의 AppDelegate UIApplication에 등록합니다.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // @Environment를 사용하여 SwiftUI의 환경 값 중 scenePhase를 가져옵니다.
    // @Environment: 프로퍼티 래퍼는 SwiftUI의 환경 값을 접근할 수 있게 합니다. SwiftUI에서는 여러 가지 환경 값을 제공하며, 이는 뷰 계층 구조 내에서 공유되고, 특정 설정이나 상태를 쉽게 전달할 수 있게 합니다.
    @Environment(\.scenePhase) private var scenePhase

    // SwiftUI에서 초기 설정하거나 필요한 리소스를 가져오는데 사용됩니다.
    init() {
        Log.debug("Init application")
        
        // Firebase 초기화
        FirebaseApp.configure()
        // FCM delegate 설정
        Messaging.messaging().delegate = appDelegate
        // Notification 권한 요청
        requestNotificationAuthorization()
    }
    
    // 원격 알림을 등록합니다. 처음 실행할 때 권한 대화 상자가 표시되므로,
    // 더 적절한 시기에 대화 상자를 표시하려면 이 등록을 적절히 이동합니다.
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().delegate = appDelegate
        
        let notificationAuthOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: notificationAuthOptions) { granted, error in
            if let error = error {
                Log.debug("Notification request error: ", error.localizedDescription)
                return
            } else {
                Log.debug("Notification request authorization: ", granted)
                if granted {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                Log.debug("App is active")
            case .inactive:
                Log.debug("App is inactive")
            case .background:
                Log.debug("App is in background")
            @unknown default:
                Log.debug("Unexpected new value")
            }
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.message_id"
    
    // 앱이 시작될 때 호출됩니다. 초기 설정을 하거나 필요한 리소스를 로드하는 데 사용됩니다.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        Log.debug("Finish app launching")
        return true
    }
    
    // APNs에 등록 성공했을 때 호출됩니다.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Log.debug("APNs token retrieved: ", deviceToken.toHexString())
        Messaging.messaging().apnsToken = deviceToken
    }
    
    // APNs에 등록 실패했을 때 호출됩니다.
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: any Error) {
        Log.debug("Unable to register for remote notifications: ", error.localizedDescription)
    }
}

// Fire Cloud Messaging delegate
extension AppDelegate: MessagingDelegate {
    // Note: This callback is fired at each app startup and whenever a new token is generated.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Log.debug("Fcm token: ", fcmToken ?? "")
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
        
        // TODO: If necessary send token to application server.
    }
}

// Notification Center delegate
@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    // 앱이 포그라운드에 있을 때 알림이 도착하면 호출됩니다.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        Log.debug("Foreground notification: ", userInfo)

        // Do Something With MSG Data...
        if let messageID = userInfo[gcmMessageIDKey] {
            Log.debug("Message ID: ", messageID)
        }
        
        // 알림을 표시하는 옵션을 지정
        completionHandler([[.banner, .badge, .sound]])
    }

    // 사용자가 알림을 클릭하거나 알림의 액션을 수행하면 호출됩니다.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        Log.debug("User responded to notification: ", userInfo)

        // Do Something With MSG Data...
        if let messageID = userInfo[gcmMessageIDKey] {
            Log.debug("Message ID: ", messageID)
        }
        
        // 알림의 카테고리 및 액션에 따라 처리 분기
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // 사용자가 알림을 열었을 때
            Log.debug("Default action")
        case UNNotificationDismissActionIdentifier:
            // 사용자가 알림을 닫았을 때
            Log.debug("Dismiss action")
        default:
            break
        }

        // 작업 완료 알림
        completionHandler()
    }
}
