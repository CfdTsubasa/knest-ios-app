//
//  User.swift
//  KnestApp
//
//  Created by Claude on 2025/06/08.
//

import Foundation

// MARK: - User Model

public struct User: Codable, Identifiable {
    public let id: String
    public let username: String
    public let email: String
    public let displayName: String?
    public let birthDate: String?
    public let prefecture: String?
    public let bio: String?
    public let emotionState: String?
    public let avatarUrl: String?
    public let createdAt: String
    public let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, username, email
        case displayName = "display_name"
        case birthDate = "birth_date"
        case prefecture
        case bio
        case emotionState = "emotion_state"
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public static func sample() -> User {
        return User(
            id: UUID().uuidString,
            username: "testuser",
            email: "test@example.com",
            displayName: "テストユーザー",
            birthDate: "1990-01-01",
            prefecture: "東京都",
            bio: nil,
            emotionState: nil,
            avatarUrl: nil,
            createdAt: "2025-06-08T00:00:00Z",
            updatedAt: "2025-06-08T00:00:00Z"
        )
    }
}

// MARK: - User Requests

public struct RegisterRequest: Codable {
    public let username: String
    public let email: String
    public let password: String
    public let password2: String
    public let displayName: String?
    public let birthDate: String?
    public let prefecture: String?
    
    public init(
        username: String,
        email: String,
        password: String,
        password2: String,
        displayName: String? = nil,
        birthDate: String? = nil,
        prefecture: String? = nil
    ) {
        self.username = username
        self.email = email
        self.password = password
        self.password2 = password2
        self.displayName = displayName
        self.birthDate = birthDate
        self.prefecture = prefecture
    }
    
    enum CodingKeys: String, CodingKey {
        case username, email, password, password2
        case displayName = "display_name"
        case birthDate = "birth_date"
        case prefecture
    }
}

public struct UpdateUserRequest: Codable {
    public let displayName: String?
    public let birthDate: String?
    public let prefecture: String?
    
    public init(
        displayName: String? = nil,
        birthDate: String? = nil,
        prefecture: String? = nil
    ) {
        self.displayName = displayName
        self.birthDate = birthDate
        self.prefecture = prefecture
    }
    
    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case birthDate = "birth_date"
        case prefecture
    }
}

struct LoginRequest: Codable {
    let username: String
    let password: String
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

struct LoginResponse: Codable {
    let access: String
    let refresh: String
    let user: User
} 