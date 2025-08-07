//
//  User.swift
//  KnestApp
//
//  Created by t.i on 2025/06/07.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let username: String
    let email: String
    let displayName: String?
    let birthDate: String?        // 追加: 生年月日 (YYYY-MM-DD形式)
    let prefecture: String?       // 追加: 都道府県
    let bio: String?
    let emotionState: String?
    let avatarUrl: String?
    let isPremium: Bool?          // Bool?のまま（プレミアム機能は今後実装のため）
    let lastActive: String?       // バックエンドからnullが返される可能性があるためオプショナル
    let createdAt: String?        // バックエンドからnullが返される可能性があるためオプショナル
    let updatedAt: String?        // バックエンドからnullが返される可能性があるためオプショナル
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, bio
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case emotionState = "emotion_state"
        case birthDate = "birth_date"
        case prefecture = "prefecture"
        case isPremium = "is_premium"
        case lastActive = "last_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // プレミアム会員判定用の計算プロパティ
    var isValidPremiumUser: Bool {
        return isPremium ?? false
    }
    
    // 安全な日時フィールドアクセス
    var safeLastActive: String {
        return lastActive ?? "未設定"
    }
    
    var safeCreatedAt: String {
        return createdAt ?? "未設定"
    }
    
    var safeUpdatedAt: String {
        return updatedAt ?? "未設定"
    }
    
    // プレビュー・テスト用のサンプルデータ
    static func sample() -> User {
        return User(
            id: "sample-user-id",
            username: "sampleuser",
            email: "sample@example.com",
            displayName: "サンプルユーザー",
            birthDate: "1995-06-15",
            prefecture: "東京都",
            bio: "サンプルの自己紹介です。",
            emotionState: "happy",
            avatarUrl: nil,
            isPremium: false,
            lastActive: "2025-06-08T00:00:00Z",
            createdAt: "2025-06-08T00:00:00Z",
            updatedAt: "2025-06-08T00:00:00Z"
        )
    }
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let access: String
    let refresh: String
    let user: User
}

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
    let password2: String
    let displayName: String?
    let birthDate: String?       // 追加: 生年月日
    let prefecture: String?      // 追加: 都道府県
    
    enum CodingKeys: String, CodingKey {
        case username, email, password, password2
        case displayName = "display_name"
        case birthDate = "birth_date"
        case prefecture = "prefecture"
    }
} 