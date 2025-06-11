//
//  HierarchicalInterest.swift
//  KnestApp
//
//  Created by Claude on 2025/06/08.
//

import Foundation

// MARK: - 3階層興味関心システム

/// 興味関心カテゴリ（第1階層）
struct InterestCategory: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let type: String
    let description: String
    let iconUrl: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, description
        case iconUrl = "icon_url"
        case createdAt = "created_at"
    }
}

/// 興味関心サブカテゴリ（第2階層）
struct InterestSubcategory: Codable, Identifiable, Hashable {
    let id: String
    let category: String // カテゴリID
    let name: String
    let description: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, category, name, description
        case createdAt = "created_at"
    }
}

/// 興味関心タグ（第3階層）
struct InterestTag: Codable, Identifiable, Hashable {
    let id: String
    let subcategory: String // サブカテゴリID
    let name: String
    let description: String
    let usageCount: Int
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, subcategory, name, description
        case usageCount = "usage_count"
        case createdAt = "created_at"
    }
}

/// ユーザーの興味関心プロフィール
struct UserInterestProfile: Codable, Identifiable {
    let id: String
    let user: String // ユーザーID
    let category: InterestCategory?
    let subcategory: InterestSubcategory?
    let tag: InterestTag?
    let intensity: Int // 1-5の強度
    let addedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, user, category, subcategory, tag, intensity
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
    
    enum CodingKeys: String, CodingKey {
        case totalScore = "total_score"
        case interestScore = "interest_score"
        case locationScore = "location_score"
        case ageScore = "age_score"
        case commonInterests = "common_interests"
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