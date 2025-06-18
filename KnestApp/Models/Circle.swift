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
            id: "550e8400-e29b-41d4-a716-446655440000",
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

// 型エイリアス（後方互換性のため）
typealias Circle = KnestCircle

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
    let sender: CircleChatAuthor
    let content: String
    let createdAt: Date
    let circle: String
    let replyTo: ChatReply?
    let mediaUrls: [String]
    let readBy: [ReadByUser]
    let isEdited: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, sender, content, circle
        case createdAt = "created_at"
        case replyTo = "reply_to"
        case mediaUrls = "media_urls"
        case readBy = "read_by"
        case isEdited = "is_edited"
    }
}

struct ReadByUser: Codable {
    let id: String
    let username: String
    let displayName: String?
    
    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
    }
}

struct CircleChatAuthor: Codable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

struct ChatReply: Codable {
    let id: String
    let sender: CircleChatAuthor
    let content: String
}

// MARK: - Circle Post
struct CirclePost: Codable, Identifiable {
    let id: String
    let author: CircleChatAuthor
    let content: String
    let mediaUrls: [String]
    let createdAt: Date
    let updatedAt: Date
    let isSystemMessage: Bool
    let isEdited: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, author, content
        case mediaUrls = "media_urls"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isSystemMessage = "is_system_message"
        case isEdited = "is_edited"
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
    let status: CircleStatus
    let maxMembers: Int?
    let tags: [String]
    let interests: [String]
}

// MARK: - Join Circle Request
struct JoinCircleRequest: Codable {
    let message: String?
}

// MARK: - Circle Recommendation (Next Generation)
struct NextGenRecommendationResponse: Codable {
    let recommendations: [NextGenRecommendation]
    let algorithmUsed: String
    let algorithmWeights: AlgorithmWeights
    let count: Int
    let totalCandidates: Int
    let computationTimeMs: Double
    let sessionId: String
    let generatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case recommendations
        case algorithmUsed = "algorithm_used"
        case algorithmWeights = "algorithm_weights"
        case count
        case totalCandidates = "total_candidates"
        case computationTimeMs = "computation_time_ms"
        case sessionId = "session_id"
        case generatedAt = "generated_at"
    }
}

struct NextGenRecommendation: Codable, Identifiable {
    let circle: KnestCircle
    let score: Double
    let reasons: [RecommendationReason]
    let confidence: Double
    let sessionId: String
    
    enum CodingKeys: String, CodingKey {
        case circle, score, reasons, confidence
        case sessionId = "session_id"
    }
    
    // IDを自動生成（circleのIDを使用）
    var id: String {
        return circle.id
    }
    
    // カスタムDecodable実装
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        circle = try container.decode(KnestCircle.self, forKey: .circle)
        score = try container.decode(Double.self, forKey: .score)
        reasons = try container.decode([RecommendationReason].self, forKey: .reasons)
        confidence = try container.decode(Double.self, forKey: .confidence)
        sessionId = try container.decode(String.self, forKey: .sessionId)
    }
    
    // カスタムEncodable実装（念のため）
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(circle, forKey: .circle)
        try container.encode(score, forKey: .score)
        try container.encode(reasons, forKey: .reasons)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(sessionId, forKey: .sessionId)
    }
}

struct RecommendationReason: Codable {
    let type: String
    let detail: String
    let weight: Double
}

struct AlgorithmWeights: Codable {
    let hierarchical: Double
    let collaborative: Double
    let behavioral: Double
    let diversity: Double
}

// MARK: - Feedback Models
struct RecommendationFeedback: Codable {
    let circleId: String
    let feedbackType: FeedbackType
    let sessionId: String
    let recommendationScore: Double?
    let recommendationAlgorithm: String?
    let recommendationReasons: [RecommendationReason]?
    
    enum CodingKeys: String, CodingKey {
        case circleId = "circle_id"
        case feedbackType = "feedback_type"
        case sessionId = "session_id"
        case recommendationScore = "recommendation_score"
        case recommendationAlgorithm = "recommendation_algorithm"
        case recommendationReasons = "recommendation_reasons"
    }
}

enum FeedbackType: String, Codable, CaseIterable {
    case view = "view"
    case click = "click"
    case joinRequest = "join_request"
    case joinSuccess = "join_success"
    case dismiss = "dismiss"
    case notInterested = "not_interested"
    case bookmark = "bookmark"
    case share = "share"
    
    var displayName: String {
        switch self {
        case .view: return "閲覧"
        case .click: return "クリック"
        case .joinRequest: return "参加申請"
        case .joinSuccess: return "参加成功"
        case .dismiss: return "却下"
        case .notInterested: return "興味なし"
        case .bookmark: return "ブックマーク"
        case .share: return "シェア"
        }
    }
}

struct UserPreferences: Codable {
    let userProfile: UserProfile
    let algorithmWeights: AlgorithmWeights
    let learningPatterns: LearningPatterns
    let recommendationsReceivedCount: Int
    let generatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case userProfile = "user_profile"
        case algorithmWeights = "algorithm_weights"
        case learningPatterns = "learning_patterns"
        case recommendationsReceivedCount = "recommendations_received_count"
        case generatedAt = "generated_at"
    }
}

struct UserProfile: Codable {
    let isNewUser: Bool
    let isActiveUser: Bool
    let hasLimitedData: Bool
    let daysSinceJoined: Int
    let interestCount: Int
    let recentActivity: Int
    
    enum CodingKeys: String, CodingKey {
        case isNewUser = "is_new_user"
        case isActiveUser = "is_active_user"
        case hasLimitedData = "has_limited_data"
        case daysSinceJoined = "days_since_joined"
        case interestCount = "interest_count"
        case recentActivity = "recent_activity"
    }
}

struct LearningPatterns: Codable {
    let preferredCategories: [String: Double]
    let dislikedCategories: [String: Double]
    let successfulAlgorithms: [String: Double]
    
    enum CodingKeys: String, CodingKey {
        case preferredCategories = "preferred_categories"
        case dislikedCategories = "disliked_categories"
        case successfulAlgorithms = "successful_algorithms"
    }
}

// MARK: - Metrics Models
struct RecommendationMetricsResponse: Codable {
    let metrics: [RecommendationMetric]
    let count: Int
}

struct RecommendationMetric: Codable, Identifiable {
    let id: String
    let metricType: String
    let algorithmName: String
    let metricValue: Double
    let userSegment: String?
    let measurementDate: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case metricType = "metric_type"
        case algorithmName = "algorithm_name"
        case metricValue = "metric_value"
        case userSegment = "user_segment"
        case measurementDate = "measurement_date"
        case createdAt = "created_at"
    }
}

// 既存のCircleRecommendationを維持（下位互換性のため）
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
struct CircleResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [KnestCircle]
}

struct CircleJoinResult: Codable {
    let detail: String
    let membership: CircleMembership?
}

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

// MARK: - Additional Circle Models
struct JoinCircleResponse: Codable {
    let detail: String
    let membership: CircleMembership?
} 