import Foundation
import SwiftUI

extension KnestCircle {
    /// レガシーコード互換の簡易イニシャライザ
    /// 不要なパラメータは破棄し、新モデルに合わせてマッピングします。
    init(id: String,
         name: String,
         description: String,
         status: CircleStatus,
         circleType: CircleType,
         createdAt: String,
         updatedAt: String,
         owner: User,
         interests: [String],
         lastActivityAt: String,
         memberCount: Int,
         isMember: Bool,
         membershipStatus: MembershipStatus?,
         categories: [InterestCategory],
         tags: [String],
         postCount: Int,
         iconUrl: String?,
         coverUrl: String?,
         rules: String?,
         memberLimit: Int?) {
        self.init(
            id: id,
            name: name,
            description: description,
            avatarUrl: iconUrl,
            coverImageUrl: coverUrl,
            owner: owner,
            members: [],
            categories: categories,
            subcategories: [],
            tags: [],
            isPrivate: circleType == .private,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// 旧コードが参照するステータス（常に .open を返す簡易実装）
    var status: CircleStatus { .open }

    var coverUrl: String? { coverImageUrl }
    var circleType: CircleType { isPrivate ? .private : .public }
    var rules: String? { nil }
    var isMember: Bool { false }
    var memberLimit: Int? { nil }
} 
