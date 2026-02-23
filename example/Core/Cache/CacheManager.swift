//
//  CacheManager.swift
//  example
//
//  Path: Core/Cache/CacheManager.swift
//  Created by Claude on 2/23/26.
//

import Foundation
import SwiftData

// MARK: - Cache Manager
/// SwiftData 기반 오프라인 캐시 매니저
///
/// 네트워크 연결이 없을 때 캐싱된 데이터로 폴백하기 위해 사용합니다.
/// SwiftData 초기화 실패 시에도 앱이 정상 동작하도록 graceful degradation을 적용합니다.
///
/// 사용 예시:
/// ```swift
/// let cacheManager = ServiceContainer.shared.cacheManager
///
/// // 사용자 캐싱
/// cacheManager.saveUser(user)
///
/// // 캐시 조회
/// if let user = cacheManager.loadUser() { ... }
///
/// // 캐시 삭제
/// cacheManager.clearAll()
/// ```
@MainActor
final class CacheManager {
    /// SwiftData 컨텍스트 (초기화 실패 시 nil)
    private let context: ModelContext?

    init() {
        do {
            let schema = Schema([CachedUser.self])
            let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            self.context = ModelContext(container)
        } catch {
            Log.error("SwiftData initialization failed:", error.localizedDescription)
            self.context = nil
        }
    }

    // MARK: - User Cache

    /// 사용자 정보를 캐시에 저장
    ///
    /// 기존 캐시를 모두 삭제하고 새 데이터로 교체합니다 (항상 최신 1건만 유지).
    func saveUser(_ user: User) {
        guard let context else { return }

        do {
            try context.delete(model: CachedUser.self)
            context.insert(CachedUser.from(user))
            try context.save()
            Log.custom(category: "Cache", "User cached: \(user.email)")
        } catch {
            Log.error("Failed to cache user:", error.localizedDescription)
        }
    }

    /// 캐싱된 사용자 정보를 조회
    ///
    /// - Returns: 캐싱된 사용자 정보 (없으면 nil)
    func loadUser() -> User? {
        guard let context else { return nil }

        do {
            let descriptor = FetchDescriptor<CachedUser>()
            let results = try context.fetch(descriptor)

            if let cached = results.first {
                Log.custom(category: "Cache", "Loaded cached user: \(cached.email)")
                return cached.toUser()
            }
        } catch {
            Log.error("Failed to load cached user:", error.localizedDescription)
        }

        return nil
    }

    /// 모든 캐시 데이터를 삭제
    func clearAll() {
        guard let context else { return }

        do {
            try context.delete(model: CachedUser.self)
            try context.save()
            Log.custom(category: "Cache", "All cache cleared")
        } catch {
            Log.error("Failed to clear cache:", error.localizedDescription)
        }
    }
}
