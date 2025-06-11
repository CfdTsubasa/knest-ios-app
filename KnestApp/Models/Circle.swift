//
//  Circle.swift
//  KnestApp
//
//  Created by t.i on 2025/06/07.
//

import Foundation

// MARK: - Circle Category
struct CircleCategory: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description
        case createdAt = "created_at"
    }
}

// MARK: - Circle
struct KnestCircle: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let status: CircleStatus
    let circleType: CircleType
    let createdAt: String
    let updatedAt: String
    let owner: User
    let interests: [Interest]
    let lastActivityAt: String?
    let memberCount: Int
    let isMember: Bool
    let membershipStatus: String?
    let categories: [CircleCategory]
    let tags: [String]
    let postCount: Int
    let iconUrl: String?
    let coverUrl: String?
    let rules: String?
    let memberLimit: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, status, owner, interests, categories, tags, rules
        case circleType = "circle_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastActivityAt = "last_activity_at"
        case memberCount = "member_count"
        case isMember = "is_member"
        case membershipStatus = "membership_status"
        case postCount = "post_count"
        case iconUrl = "icon_url"
        case coverUrl = "cover_url"
        case memberLimit = "member_limit"
    }
    
    // プレビュー・テスト用のサンプルデータ
    static func sample() -> KnestCircle {
        return KnestCircle(
            id: "sample-id",
            name: "サンプルサークル",
            description: "これはサンプルのサークルです。",
            status: .open,
            circleType: .public,
            createdAt: "2025-06-08T00:00:00Z",
            updatedAt: "2025-06-08T00:00:00Z",
            owner: User.sample(),
            interests: [],
            lastActivityAt: "2025-06-08T00:00:00Z",
            memberCount: 10,
            isMember: false,
            membershipStatus: nil,
            categories: [],
            tags: ["プログラミング", "技術"],
            postCount: 5,
            iconUrl: nil,
            coverUrl: nil,
            rules: nil,
            memberLimit: 50
        )
    }
}

enum CircleStatus: String, Codable, CaseIterable {
    case open = "open"
    case closed = "closed"
    case full = "full"
    
    var displayName: String {
        switch self {
        case .open: return "募集中"
        case .closed: return "応募締切"
        case .full: return "満員"
        }
    }
    
    var color: String {
        switch self {
        case .open: return "green"
        case .closed: return "orange"
        case .full: return "red"
        }
    }
}

enum CircleType: String, Codable, CaseIterable {
    case `public` = "public"
    case approval = "approval"
    case `private` = "private"
    
    var displayName: String {
        switch self {
        case .public: return "公開"
        case .approval: return "承認制"
        case .private: return "非公開"
        }
    }
}

// MARK: - Circle Membership
struct CircleMembership: Codable, Identifiable {
    let id: String
    let user: User
    let circle: String
    let status: MembershipStatus
    let role: MembershipRole
    let joinedAt: String?
    let applicationMessage: String?
    let rejectionReason: String?
    
    enum CodingKeys: String, CodingKey {
        case id, user, circle, status, role
        case joinedAt = "joined_at"
        case applicationMessage = "application_message"
        case rejectionReason = "rejection_reason"
    }
}

enum MembershipStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case active = "active"
    case rejected = "rejected"
    
    var displayName: String {
        switch self {
        case .pending: return "申請中"
        case .active: return "参加中"
        case .rejected: return "拒否"
        }
    }
}

enum MembershipRole: String, Codable, CaseIterable {
    case owner = "owner"
    case admin = "admin"
    case member = "member"
    
    var displayName: String {
        switch self {
        case .owner: return "オーナー"
        case .admin: return "管理者"
        case .member: return "メンバー"
        }
    }
}

// MARK: - Circle Chat
struct CircleChat: Codable, Identifiable {
    let id: String
    let circle: String
    let sender: ChatUser
    let content: String
    let mediaUrls: [String]
    let createdAt: String
    let updatedAt: String
    let isSystemMessage: Bool
    let isEdited: Bool
    let replyTo: ChatReply?
    let readBy: [ChatUser]
    
    enum CodingKeys: String, CodingKey {
        case id, circle, sender, content
        case mediaUrls = "media_urls"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isSystemMessage = "is_system_message"
        case isEdited = "is_edited"
        case replyTo = "reply_to"
        case readBy = "read_by"
    }
}

// MARK: - Chat Supporting Types
struct ChatUser: Codable, Identifiable {
    let id: String
    let username: String
    let displayName: String
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

struct ChatReply: Codable {
    let id: String
    let content: String
    let sender: ChatUser
}

// MARK: - Circle Post
struct CirclePost: Codable, Identifiable {
    let id: String
    let circle: String
    let author: ChatUser
    let content: String
    let mediaUrls: [String]
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, circle, author, content
        case mediaUrls = "media_urls"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Circle Event
struct CircleEvent: Codable, Identifiable {
    let id: String
    let circle: String
    let title: String
    let description: String
    let startDatetime: String
    let endDatetime: String
    let location: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, circle, title, description, location
        case startDatetime = "start_datetime"
        case endDatetime = "end_datetime"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Create Circle Request
struct CreateCircleRequest: Codable {
    let name: String
    let description: String
    let isPremium: Bool?
    let memberLimit: Int?
    let isPrivate: Bool?
    let interests: [String]? // UUID strings
    
    enum CodingKeys: String, CodingKey {
        case name, description, interests
        case isPremium = "is_premium"
        case memberLimit = "member_limit"
        case isPrivate = "is_private"
    }
}

// MARK: - Join Circle Request
struct JoinCircleRequest: Codable {
    let applicationMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case applicationMessage = "application_message"
    }
}

// MARK: - Circle Recommendation
struct CircleRecommendation: Codable, Identifiable {
    let id: String
    let circle: KnestCircle
    let recommendationScore: Double
    let recommendationReason: String
    let createdAt: String
    let isViewed: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, circle
        case recommendationScore = "recommendation_score"
        case recommendationReason = "recommendation_reason"
        case createdAt = "created_at"
        case isViewed = "is_viewed"
    }
}

// MARK: - API Response Types
struct CircleListResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [KnestCircle]
}

struct PagedResponse<T: Codable>: Codable {
    let count: Int?
    let next: String?
    let previous: String?
    let results: [T]
} 