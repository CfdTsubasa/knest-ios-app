//
//  Interest.swift
//  KnestApp
//
//  Created by t.i on 2025/06/08.
//

import Foundation

// DRF Pagination Response
struct InterestsResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [Interest]
}

// 興味・関心のモデル
struct Interest: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let category: String
    let isOfficial: Bool
    let usageCount: Int
    let iconUrl: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category
        case isOfficial = "is_official"
        case usageCount = "usage_count"
        case iconUrl = "icon_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// ユーザーの興味・関心のモデル（シンプル版）
struct UserInterest: Codable, Identifiable {
    let id: Int
    let interest: Interest
    let addedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, interest
        case addedAt = "added_at"
    }
}

// 興味・関心のカテゴリ（旧システム用）
enum LegacyInterestCategory: String, CaseIterable {
    case gaming = "gaming"
    case learning = "learning"
    case creative = "creative"
    case sports = "sports"
    case food = "food"
    case travel = "travel"
    case lifestyle = "lifestyle"
    case entertainment = "entertainment"
    case technical = "technical"
    case business = "business"
    case wellness = "wellness"
    
    var displayName: String {
        switch self {
        case .gaming: return "🎮 ゲーム"
        case .learning: return "📚 学習・知識"
        case .creative: return "🎨 クリエイティブ"
        case .sports: return "🏃‍♂️ スポーツ"
        case .food: return "🍳 料理・グルメ"
        case .travel: return "🌍 旅行・アウトドア"
        case .lifestyle: return "💰 ライフスタイル"
        case .entertainment: return "🎭 エンターテイメント"
        case .technical: return "🔬 技術・専門"
        case .business: return "🎯 ビジネス・キャリア"
        case .wellness: return "🧠 自己開発・ウェルネス"
        }
    }
    
    var icon: String {
        switch self {
        case .gaming: return "gamecontroller"
        case .learning: return "book"
        case .creative: return "paintbrush"
        case .sports: return "figure.run"
        case .food: return "fork.knife"
        case .travel: return "airplane"
        case .lifestyle: return "house"
        case .entertainment: return "tv"
        case .technical: return "cpu"
        case .business: return "briefcase"
        case .wellness: return "heart.text.square"
        }
    }
}

// リクエスト用のモデル（シンプル版）
struct CreateUserInterestRequest: Codable {
    let interest_id: String
    
    enum CodingKeys: String, CodingKey {
        case interest_id
    }
}

// MARK: - ハッシュタグシステム

// ハッシュタグモデル
struct Tag: Codable, Identifiable, Hashable {
    let id: Int
    let name: String
    let usageCount: Int
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case usageCount = "usage_count"
        case createdAt = "created_at"
    }
}

// ユーザーハッシュタグモデル
struct UserTag: Codable, Identifiable {
    let id: Int
    let tag: Tag
    let addedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, tag
        case addedAt = "added_at"
    }
}

// ユーザーハッシュタグ作成リクエスト
struct CreateUserTagRequest: Codable {
    let tag_name: String
    
    enum CodingKeys: String, CodingKey {
        case tag_name
    }
} 