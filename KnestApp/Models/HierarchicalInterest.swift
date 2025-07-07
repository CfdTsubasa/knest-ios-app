//
//  HierarchicalInterest.swift
//  KnestApp
//
//  Created by Claude on 2025/06/08.
//

import Foundation

// MARK: - 3階層興味関心システム

/// 興味関心カテゴリ（第1階層）
public struct InterestCategory: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let type: String
    public let description: String
    public let iconUrl: String?
    public let createdAt: String
    
    public init(id: String, name: String, type: String = "default", description: String, iconUrl: String? = nil, createdAt: String = "2025-01-01T00:00:00Z") {
        self.id = id
        self.name = name
        self.type = type
        self.description = description
        self.iconUrl = iconUrl
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, description
        case iconUrl = "icon_url"
        case createdAt = "created_at"
    }
}

/// 興味関心サブカテゴリ（第2階層）
public struct InterestSubcategory: Codable, Identifiable, Hashable {
    public let id: String
    public let category: InterestCategory
    public let name: String
    public let description: String
    public let iconUrl: String?
    public let createdAt: String
    
    public init(id: String, category: InterestCategory, name: String, description: String, createdAt: String = "2025-01-01T00:00:00Z", iconUrl: String? = nil) {
        self.id = id
        self.category = category
        self.name = name
        self.description = description
        self.iconUrl = iconUrl
        self.createdAt = createdAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, category, name, description
        case iconUrl = "icon_url"
        case createdAt = "created_at"
    }
}

/// 興味関心タグ（第3階層）
public struct InterestTag: Codable, Identifiable, Hashable {
    public let id: String
    public let subcategory: InterestSubcategory
    public let name: String
    public let description: String?
    public let isOfficial: Bool
    public let usageCount: Int
    public let iconUrl: String?
    public let createdAt: String
    public let updatedAt: String?
    
    public init(id: String, subcategory: InterestSubcategory, name: String, description: String? = nil, isOfficial: Bool = false, usageCount: Int = 0, iconUrl: String? = nil, createdAt: String = "2025-01-01T00:00:00Z", updatedAt: String? = nil) {
        self.id = id
        self.subcategory = subcategory
        self.name = name
        self.description = description
        self.isOfficial = isOfficial
        self.usageCount = usageCount
        self.iconUrl = iconUrl
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, subcategory, name, description, isOfficial, iconUrl
        case usageCount = "usage_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// ユーザーの興味関心プロフィール
public struct UserInterestProfile: Codable, Identifiable {
    public let id: String
    public let user: String
    public let category: InterestCategory?
    public let subcategory: InterestSubcategory?
    public let tag: InterestTag?
    public let addedAt: String
    
    public init(id: String, user: String, category: InterestCategory? = nil, subcategory: InterestSubcategory? = nil, tag: InterestTag? = nil, addedAt: String = "2025-01-01T00:00:00Z") {
        self.id = id
        self.user = user
        self.category = category
        self.subcategory = subcategory
        self.tag = tag
        self.addedAt = addedAt
    }
    
    enum CodingKeys: String, CodingKey {
        case id, user, category, subcategory, tag
        case addedAt = "added_at"
    }
}

// MARK: - マッチング関連

/// マッチングスコア
struct MatchingScore: Codable {
    let totalScore: Double
    let interestScore: Double
    let locationScore: Double
    let ageScore: Double
    let commonInterests: [String] // 共通の興味関心
    let hierarchicalDetails: HierarchicalMatchDetails? // 階層レベル詳細
    
    enum CodingKeys: String, CodingKey {
        case totalScore = "total_score"
        case interestScore = "interest_score"
        case locationScore = "location_score"
        case ageScore = "age_score"
        case commonInterests = "common_interests"
        case hierarchicalDetails = "hierarchical_details"
    }
}

/// 階層マッチング詳細
struct HierarchicalMatchDetails: Codable {
    let exactMatches: Int         // タグレベル完全一致数
    let subcategoryMatches: Int   // サブカテゴリレベル一致数
    let categoryMatches: Int      // カテゴリレベル一致数
    let weightedScore: Double     // 重み付けスコア
    let maxPossibleScore: Int     // 最大可能スコア
    
    enum CodingKeys: String, CodingKey {
        case exactMatches = "exact_matches"
        case subcategoryMatches = "subcategory_matches"
        case categoryMatches = "category_matches"
        case weightedScore = "weighted_score"
        case maxPossibleScore = "max_possible_score"
    }
    
    /// マッチング詳細の表示テキスト
    var detailText: String {
        var details: [String] = []
        
        if exactMatches > 0 {
            details.append("🎯 完全一致: \(exactMatches)件")
        }
        if subcategoryMatches > 0 {
            details.append("📂 カテゴリ一致: \(subcategoryMatches)件")
        }
        if categoryMatches > 0 {
            details.append("📁 分野一致: \(categoryMatches)件")
        }
        
        return details.isEmpty ? "共通の興味関心なし" : details.joined(separator: " • ")
    }
    
    /// マッチング品質レベル
    var qualityLevel: String {
        let ratio = Double(exactMatches) / Double(maxPossibleScore)
        
        if ratio >= 0.7 {
            return "[HIGH] 高い適合度"
        } else if ratio >= 0.4 {
            return "[GOOD] 良い適合度"
        } else {
            return "[LOW] 基本的な適合度"
        }
    }
}

/// ユーザーマッチング結果
struct UserMatch: Codable, Identifiable {
    let id: String
    let user: User
    let score: MatchingScore
    let matchReason: String
    
    enum CodingKeys: String, CodingKey {
        case id, user, score
        case matchReason = "match_reason"
    }
}

/// サークルマッチング結果
struct CircleMatch: Codable, Identifiable {
    let id: String
    let circle: KnestCircle // KnestCircleを明示的に指定
    let score: MatchingScore
    let memberCount: Int
    let matchReason: String
    
    enum CodingKeys: String, CodingKey {
        case id, circle, score
        case memberCount = "member_count"
        case matchReason = "match_reason"
    }
}

// MARK: - 検索モード列挙型

enum SearchMode: String, CaseIterable {
    case active = "active"      // 能動（検索）
    case passive = "passive"    // 受動（おすすめ）
    case creation = "creation"  // 自己創出（設立）
    
    var title: String {
        switch self {
        case .active: return "検索"
        case .passive: return "おすすめ"
        case .creation: return "設立"
        }
    }
    
    var icon: String {
        switch self {
        case .active: return "magnifyingglass"
        case .passive: return "heart.fill"
        case .creation: return "plus.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .active: return "条件を指定してサークル・人を検索"
        case .passive: return "あなたにおすすめのサークルを発見"
        case .creation: return "似た人と一緒にサークルを作成"
        }
    }
}

// MARK: - 都道府県データ

enum Prefecture: String, CaseIterable {
    case hokkaido = "hokkaido"
    case aomori = "aomori"
    case iwate = "iwate"
    case miyagi = "miyagi"
    case akita = "akita"
    case yamagata = "yamagata"
    case fukushima = "fukushima"
    case ibaraki = "ibaraki"
    case tochigi = "tochigi"
    case gunma = "gunma"
    case saitama = "saitama"
    case chiba = "chiba"
    case tokyo = "tokyo"
    case kanagawa = "kanagawa"
    case niigata = "niigata"
    case toyama = "toyama"
    case ishikawa = "ishikawa"
    case fukui = "fukui"
    case yamanashi = "yamanashi"
    case nagano = "nagano"
    case gifu = "gifu"
    case shizuoka = "shizuoka"
    case aichi = "aichi"
    case mie = "mie"
    case shiga = "shiga"
    case kyoto = "kyoto"
    case osaka = "osaka"
    case hyogo = "hyogo"
    case nara = "nara"
    case wakayama = "wakayama"
    case tottori = "tottori"
    case shimane = "shimane"
    case okayama = "okayama"
    case hiroshima = "hiroshima"
    case yamaguchi = "yamaguchi"
    case tokushima = "tokushima"
    case kagawa = "kagawa"
    case ehime = "ehime"
    case kochi = "kochi"
    case fukuoka = "fukuoka"
    case saga = "saga"
    case nagasaki = "nagasaki"
    case kumamoto = "kumamoto"
    case oita = "oita"
    case miyazaki = "miyazaki"
    case kagoshima = "kagoshima"
    case okinawa = "okinawa"
    
    var displayName: String {
        switch self {
        case .hokkaido: return "北海道"
        case .aomori: return "青森県"
        case .iwate: return "岩手県"
        case .miyagi: return "宮城県"
        case .akita: return "秋田県"
        case .yamagata: return "山形県"
        case .fukushima: return "福島県"
        case .ibaraki: return "茨城県"
        case .tochigi: return "栃木県"
        case .gunma: return "群馬県"
        case .saitama: return "埼玉県"
        case .chiba: return "千葉県"
        case .tokyo: return "東京都"
        case .kanagawa: return "神奈川県"
        case .niigata: return "新潟県"
        case .toyama: return "富山県"
        case .ishikawa: return "石川県"
        case .fukui: return "福井県"
        case .yamanashi: return "山梨県"
        case .nagano: return "長野県"
        case .gifu: return "岐阜県"
        case .shizuoka: return "静岡県"
        case .aichi: return "愛知県"
        case .mie: return "三重県"
        case .shiga: return "滋賀県"
        case .kyoto: return "京都府"
        case .osaka: return "大阪府"
        case .hyogo: return "兵庫県"
        case .nara: return "奈良県"
        case .wakayama: return "和歌山県"
        case .tottori: return "鳥取県"
        case .shimane: return "島根県"
        case .okayama: return "岡山県"
        case .hiroshima: return "広島県"
        case .yamaguchi: return "山口県"
        case .tokushima: return "徳島県"
        case .kagawa: return "香川県"
        case .ehime: return "愛媛県"
        case .kochi: return "高知県"
        case .fukuoka: return "福岡県"
        case .saga: return "佐賀県"
        case .nagasaki: return "長崎県"
        case .kumamoto: return "熊本県"
        case .oita: return "大分県"
        case .miyazaki: return "宮崎県"
        case .kagoshima: return "鹿児島県"
        case .okinawa: return "沖縄県"
        }
    }
}

// MARK: - Recommended Circles Response Models

struct RecommendedCirclesResponse: Codable {
    let circles: [RecommendedCircleData]
    let algorithmUsed: String
    let computationTimeMs: Double
    let totalCandidates: Int
    
    enum CodingKeys: String, CodingKey {
        case circles
        case algorithmUsed = "algorithm_used"
        case computationTimeMs = "computation_time_ms"
        case totalCandidates = "total_candidates"
    }
}

struct RecommendedCircleData: Codable {
    let id: String
    let circle: CircleBasic  // Circleの代わりにCircleBasicを使用
    let matchingDetails: MatchingDetailsAPI
    let memberCount: Int
    let matchReason: String
    
    enum CodingKeys: String, CodingKey {
        case id, circle
        case matchingDetails = "matching_details"
        case memberCount = "member_count"
        case matchReason = "match_reason"
    }
}

// APIレスポンス用のCircle基本情報
struct CircleBasic: Codable {
    let id: String
    let name: String
    let description: String
    let status: String
    let circleType: String
    let memberCount: Int
    let postCount: Int
    let tags: [String]
    let createdAt: String
    let updatedAt: String
    let lastActivityAt: String
    let iconUrl: String?
    let coverUrl: String?
    let owner: CircleOwner?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, status, tags
        case circleType = "circle_type"
        case memberCount = "member_count"
        case postCount = "post_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastActivityAt = "last_activity_at"
        case iconUrl = "icon_url"
        case coverUrl = "cover_url"
        case owner
    }
}

// サークルオーナー情報
struct CircleOwner: Codable {
    let id: String
    let username: String
    let displayName: String
    
    enum CodingKeys: String, CodingKey {
        case id, username
        case displayName = "display_name"
    }
}

// APIレスポンス用のMatchingDetails
struct MatchingDetailsAPI: Codable {
    let totalScore: Double
    let confidence: Double
    let reasons: [MatchingReasonAPI]
    let matchExplanation: String
    
    enum CodingKeys: String, CodingKey {
        case totalScore = "total_score"
        case confidence
        case reasons
        case matchExplanation = "match_explanation"
    }
}

// APIレスポンス用のマッチング理由
struct MatchingReasonAPI: Codable {
    let type: String
    let detail: String
    let weight: Double
}

extension InterestTag {
    func localizedCaseInsensitiveContains(_ other: String) -> Bool {
        name.localizedCaseInsensitiveContains(other)
    }
    
    // レガシーコード互換（name, description, subcategory 順）
    init(id: String,
         name: String,
         description: String? = nil,
         subcategory: InterestSubcategory,
         isOfficial: Bool = false,
         usageCount: Int = 0,
         iconUrl: String? = nil,
         createdAt: String = "2025-01-01T00:00:00Z",
         updatedAt: String? = nil) {
        self.init(id: id,
                  subcategory: subcategory,
                  name: name,
                  description: description,
                  isOfficial: isOfficial,
                  usageCount: usageCount,
                  iconUrl: iconUrl,
                  createdAt: createdAt,
                  updatedAt: updatedAt)
    }
}

extension InterestSubcategory {
    // レガシー順序 id, name, description, category
    init(id: String,
         name: String,
         description: String,
         category: InterestCategory,
         iconUrl: String? = nil,
         createdAt: String = "2025-01-01T00:00:00Z") {
        self.init(id: id,
                  category: category,
                  name: name,
                  description: description,
                  createdAt: createdAt,
                  iconUrl: iconUrl)
    }
} 