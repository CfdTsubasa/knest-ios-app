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
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, username, email, bio
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case emotionState = "emotion_state"
        case birthDate = "birth_date"
        case prefecture = "prefecture"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
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