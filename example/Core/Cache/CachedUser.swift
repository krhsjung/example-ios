//
//  CachedUser.swift
//  example
//
//  Path: Core/Cache/CachedUser.swift
//  Created by Claude on 2/23/26.
//

import Foundation
import SwiftData

// MARK: - Cached User Model
/// 오프라인 지원을 위한 사용자 정보 캐시 (SwiftData)
///
/// `User` struct의 SwiftData 영구 저장 버전입니다.
/// 네트워크 연결이 없을 때 캐싱된 사용자 데이터로 폴백하는 데 사용됩니다.
///
/// - Note: `LoginProvider`는 enum이므로 `String?`으로 저장 후 변환합니다.
@Model
final class CachedUser {
    var idx: Int
    var name: String
    var email: String
    var picture: String?
    var providerRawValue: String?
    var maxSessions: Int?
    var cachedAt: Date

    init(
        idx: Int,
        name: String,
        email: String,
        picture: String?,
        providerRawValue: String?,
        maxSessions: Int?,
        cachedAt: Date = Date()
    ) {
        self.idx = idx
        self.name = name
        self.email = email
        self.picture = picture
        self.providerRawValue = providerRawValue
        self.maxSessions = maxSessions
        self.cachedAt = cachedAt
    }

    /// CachedUser → User 변환
    func toUser() -> User {
        User(
            idx: idx,
            name: name,
            email: email,
            picture: picture,
            provider: providerRawValue.flatMap { LoginProvider(rawValue: $0) },
            maxSessions: maxSessions
        )
    }

    /// User → CachedUser 변환
    static func from(_ user: User) -> CachedUser {
        CachedUser(
            idx: user.idx,
            name: user.name,
            email: user.email,
            picture: user.picture,
            providerRawValue: user.provider?.rawValue,
            maxSessions: user.maxSessions
        )
    }
}
