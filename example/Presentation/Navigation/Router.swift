//
//  Router.swift
//  example
//
//  Path: Presentation/Navigation/Router.swift
//  Created by Claude on 2/23/26.
//

import SwiftUI
import Observation

// MARK: - Auth Route
/// 인증 플로우의 네비게이션 목적지
enum AuthRoute: Hashable {
    case signUp
}

// MARK: - Router
/// 앱 전체의 네비게이션 상태를 관리하는 라우터
///
/// NavigationPath를 사용하여 타입 안전한 프로그래밍 방식 네비게이션을 제공합니다.
///
/// 사용 예시:
/// ```swift
/// let router = ServiceContainer.shared.router
///
/// // 화면 이동
/// router.navigate(to: .signUp)
///
/// // 뒤로 가기
/// router.goBack()
/// ```
@MainActor
@Observable
final class Router {
    /// 인증 플로우 네비게이션 경로
    var authPath = NavigationPath()

    /// 지정된 인증 화면으로 이동
    func navigate(to route: AuthRoute) {
        authPath.append(route)
    }

    /// 이전 화면으로 돌아가기
    func goBack() {
        guard !authPath.isEmpty else { return }
        authPath.removeLast()
    }

    /// 인증 네비게이션 경로 초기화 (로그인 성공 시 호출)
    func resetAuthPath() {
        authPath = NavigationPath()
    }
}
