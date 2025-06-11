//
//  HierarchicalInterestManager.swift
//  KnestApp
//
//  Created by Claude on 2025/06/08.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class HierarchicalInterestManager: ObservableObject {
    @Published var categories: [InterestCategory] = []
    @Published var subcategories: [InterestSubcategory] = []
    @Published var tags: [InterestTag] = []
    @Published var userProfile: [UserInterestProfile] = []
    @Published var userProfiles: [UserInterestProfile] = [] // ProfileViewで使用されるプロパティ
    @Published var isLoading = false
    @Published var error: String?
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - カテゴリ管理
    
    func loadCategories() {
        isLoading = true
        error = nil
        
        // makeRequestメソッドを使用
        networkManager.makeRequest(
            endpoint: "/interests/hierarchical/categories_with_subcategories_and_tags/",
            method: .GET,
            responseType: [HierarchicalTree].self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("❌ カテゴリ取得エラー: \(error.localizedDescription)")
                    // フォールバック: サンプルデータを使用
                    self?.categories = self?.generateSampleCategories() ?? []
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] trees in
                print("✅ カテゴリ取得成功: \(trees.count)個のカテゴリ")
                // 受信したデータを各配列に分解して設定
                self?.processHierarchicalTrees(trees)
            }
        )
        .store(in: &cancellables)
    }
    
    func loadSubcategories(for categoryId: String) {
        isLoading = true
        error = nil
        
        // makeRequestメソッドを使用
        networkManager.makeRequest(
            endpoint: "/interests/hierarchical/subcategories/?category_id=\(categoryId)",
            method: .GET,
            responseType: [InterestSubcategory].self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("❌ サブカテゴリ取得エラー: \(error.localizedDescription)")
                    // フォールバック: サンプルデータを使用
                    self?.subcategories = self?.generateSampleSubcategories(for: categoryId) ?? []
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] subcategories in
                print("✅ サブカテゴリ取得成功: \(subcategories.count)個")
                self?.subcategories = subcategories
            }
        )
        .store(in: &cancellables)
    }
    
    func loadTags(for subcategoryId: String) {
        isLoading = true
        error = nil
        
        // makeRequestメソッドを使用
        networkManager.makeRequest(
            endpoint: "/interests/hierarchical/tags/?subcategory_id=\(subcategoryId)",
            method: .GET,
            responseType: [InterestTag].self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("❌ タグ取得エラー: \(error.localizedDescription)")
                    // フォールバック: サンプルデータを使用
                    self?.tags = self?.generateSampleTags(for: subcategoryId) ?? []
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] tags in
                print("✅ タグ取得成功: \(tags.count)個")
                self?.tags = tags
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - ユーザープロフィール管理
    
    func loadUserProfile() {
        isLoading = true
        error = nil
        
        // makeRequestメソッドを使用
        networkManager.makeRequest(
            endpoint: "/interests/hierarchical/user-profiles/",
            method: .GET,
            responseType: [UserInterestProfile].self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("❌ ユーザープロフィール取得エラー: \(error.localizedDescription)")
                    // フォールバック: サンプルデータを使用
                    self?.userProfile = self?.generateSampleUserProfile() ?? []
                    self?.userProfiles = self?.userProfile ?? [] // 同期
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] profiles in
                print("✅ ユーザープロフィール取得成功: \(profiles.count)個")
                self?.userProfile = profiles
                self?.userProfiles = profiles // 同期
            }
        )
        .store(in: &cancellables)
    }
    
    func loadUserInterestProfiles() {
        loadUserProfile() // エイリアスメソッド
    }
    
    func addInterest(tagId: String, intensity: Int) {
        isLoading = true
        error = nil
        
        let requestBody = CreateUserInterestProfileRequest(tagId: tagId, intensity: intensity)
        
        guard let body = try? JSONEncoder().encode(requestBody) else {
            error = "リクエストのエンコードに失敗しました"
            isLoading = false
            return
        }
        
        // makeRequestメソッドを使用
        networkManager.makeRequest(
            endpoint: "/interests/hierarchical/user-profiles/",
            method: .POST,
            body: body,
            responseType: UserInterestProfile.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("❌ 興味追加エラー: \(error.localizedDescription)")
                    self?.error = "興味の追加に失敗しました"
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] profile in
                print("✅ 興味追加成功: \(profile.tag?.name ?? "Unknown")")
                // ユーザープロフィールを再読み込み
                self?.loadUserProfile()
            }
        )
        .store(in: &cancellables)
    }

    func removeInterest(profileId: String) {
        isLoading = true
        error = nil
        
        // makeRequestメソッドを使用
        networkManager.makeRequest(
            endpoint: "/interests/hierarchical/user-profiles/\(profileId)/",
            method: .DELETE,
            responseType: EmptyResponse.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("❌ 興味削除エラー: \(error.localizedDescription)")
                    self?.error = "興味の削除に失敗しました"
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] _ in
                print("✅ 興味削除成功")
                // ユーザープロフィールを再読み込み
                self?.loadUserProfile()
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - 階層ツリー取得
    
    func loadHierarchicalTree() {
        isLoading = true
        error = nil
        
        // makeRequestメソッドを使用
        networkManager.makeRequest(
            endpoint: "/interests/hierarchical/categories_with_subcategories_and_tags/",
            method: .GET,
            responseType: [HierarchicalTree].self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("❌ 階層ツリー取得エラー: \(error.localizedDescription)")
                    // フォールバック: サンプルデータを生成
                    self?.loadCategories()
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] trees in
                print("✅ 階層ツリー取得成功: \(trees.count)個のカテゴリ")
                // 受信したデータを各配列に分解して設定
                self?.processHierarchicalTrees(trees)
            }
        )
        .store(in: &cancellables)
    }
    
    private func processHierarchicalTrees(_ trees: [HierarchicalTree]) {
        var allCategories: [InterestCategory] = []
        var allSubcategories: [InterestSubcategory] = []
        var allTags: [InterestTag] = []
        
        for tree in trees {
            allCategories.append(tree.category)
            
            // InterestSubcategoryWithTagsをInterestSubcategoryに変換
            for subcategoryWithTags in tree.subcategories {
                let subcategory = InterestSubcategory(
                    id: subcategoryWithTags.id,
                    category: subcategoryWithTags.categoryId,
                    name: subcategoryWithTags.name,
                    description: subcategoryWithTags.description,
                    createdAt: "2025-01-27T10:00:00Z" // デフォルト値を使用
                )
                allSubcategories.append(subcategory)
                allTags.append(contentsOf: subcategoryWithTags.tags)
            }
        }
        
        self.categories = allCategories
        self.subcategories = allSubcategories
        self.tags = allTags
    }

    // MARK: - サンプルデータ生成（フォールバック用）
    
    private func generateSampleCategories() -> [InterestCategory] {
        return [
            InterestCategory(
                id: "tech-001",
                name: "テクノロジー",
                type: "technical",
                description: "プログラミング、AI、ガジェットなど技術分野",
                iconUrl: "https://example.com/icons/technology.png",
                createdAt: "2025-01-27T10:00:00Z"
            ),
            InterestCategory(
                id: "art-001",
                name: "アート・クリエイティブ",
                type: "creative",
                description: "デザイン、音楽、写真などクリエイティブ分野",
                iconUrl: "https://example.com/icons/art.png",
                createdAt: "2025-01-27T10:00:00Z"
            ),
            InterestCategory(
                id: "sport-001",
                name: "スポーツ・健康",
                type: "health",
                description: "フィットネス、スポーツ、健康管理",
                iconUrl: "https://example.com/icons/sports.png",
                createdAt: "2025-01-27T10:00:00Z"
            ),
            InterestCategory(
                id: "study-001",
                name: "学習・スキルアップ",
                type: "learning",
                description: "資格取得、語学学習、専門スキル向上",
                iconUrl: "https://example.com/icons/learning.png",
                createdAt: "2025-01-27T10:00:00Z"
            )
        ]
    }
    
    private func generateSampleSubcategories(for categoryId: String) -> [InterestSubcategory] {
        switch categoryId {
        case "tech-001":
            return [
                InterestSubcategory(
                    id: "tech-sub-001",
                    category: categoryId,
                    name: "プログラミング",
                    description: "Web開発、アプリ開発",
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestSubcategory(
                    id: "tech-sub-002",
                    category: categoryId,
                    name: "AI・機械学習",
                    description: "人工知能、データサイエンス",
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestSubcategory(
                    id: "tech-sub-003",
                    category: categoryId,
                    name: "ガジェット",
                    description: "最新デバイス、電子工作",
                    createdAt: "2025-01-27T10:00:00Z"
                )
            ]
        case "art-001":
            return [
                InterestSubcategory(
                    id: "art-sub-001",
                    category: categoryId,
                    name: "デザイン",
                    description: "UI/UX、グラフィック",
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestSubcategory(
                    id: "art-sub-002",
                    category: categoryId,
                    name: "音楽",
                    description: "演奏、作曲、音響技術",
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestSubcategory(
                    id: "art-sub-003",
                    category: categoryId,
                    name: "映像・写真",
                    description: "撮影技術、映像制作",
                    createdAt: "2025-01-27T10:00:00Z"
                )
            ]
        case "sport-001":
            return [
                InterestSubcategory(
                    id: "sport-sub-001",
                    category: categoryId,
                    name: "フィットネス",
                    description: "トレーニング、筋トレ",
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestSubcategory(
                    id: "sport-sub-002",
                    category: categoryId,
                    name: "チームスポーツ",
                    description: "サッカー、バスケ",
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestSubcategory(
                    id: "sport-sub-003",
                    category: categoryId,
                    name: "個人スポーツ",
                    description: "ランニング、水泳",
                    createdAt: "2025-01-27T10:00:00Z"
                )
            ]
        case "study-001":
            return [
                InterestSubcategory(
                    id: "study-sub-001",
                    category: categoryId,
                    name: "語学",
                    description: "英語、中国語学習",
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestSubcategory(
                    id: "study-sub-002",
                    category: categoryId,
                    name: "資格・検定",
                    description: "IT資格、ビジネス資格",
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestSubcategory(
                    id: "study-sub-003",
                    category: categoryId,
                    name: "ビジネススキル",
                    description: "マネジメント、プレゼン",
                    createdAt: "2025-01-27T10:00:00Z"
                )
            ]
        default:
            return []
        }
    }
    
    private func generateSampleTags(for subcategoryId: String) -> [InterestTag] {
        switch subcategoryId {
        case "tech-sub-001":
            return [
                InterestTag(
                    id: "tag-001",
                    subcategory: subcategoryId,
                    name: "iOS開発",
                    description: "SwiftUIアプリ開発",
                    usageCount: 45,
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestTag(
                    id: "tag-002",
                    subcategory: subcategoryId,
                    name: "Web開発",
                    description: "React、Vue.js",
                    usageCount: 38,
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestTag(
                    id: "tag-003",
                    subcategory: subcategoryId,
                    name: "Python",
                    description: "データ分析、自動化",
                    usageCount: 52,
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestTag(
                    id: "tag-004",
                    subcategory: subcategoryId,
                    name: "Django",
                    description: "Webフレームワーク",
                    usageCount: 23,
                    createdAt: "2025-01-27T10:00:00Z"
                )
            ]
        case "art-sub-001":
            return [
                InterestTag(
                    id: "tag-007",
                    subcategory: subcategoryId,
                    name: "UI/UXデザイン",
                    description: "ユーザビリティ設計",
                    usageCount: 31,
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestTag(
                    id: "tag-008",
                    subcategory: subcategoryId,
                    name: "Figma",
                    description: "プロトタイピング",
                    usageCount: 27,
                    createdAt: "2025-01-27T10:00:00Z"
                )
            ]
        case "sport-sub-001":
            return [
                InterestTag(
                    id: "tag-009",
                    subcategory: subcategoryId,
                    name: "筋トレ",
                    description: "ウェイトトレーニング",
                    usageCount: 42,
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestTag(
                    id: "tag-010",
                    subcategory: subcategoryId,
                    name: "ヨガ",
                    description: "ストレッチ、瞑想",
                    usageCount: 35,
                    createdAt: "2025-01-27T10:00:00Z"
                )
            ]
        default:
            return []
        }
    }
    
    private func generateSampleUserProfile() -> [UserInterestProfile] {
        return [
            UserInterestProfile(
                id: "prof-001",
                user: "user-001",
                category: nil,
                subcategory: nil,
                tag: InterestTag(
                    id: "tag-001",
                    subcategory: "tech-sub-001",
                    name: "iOS開発",
                    description: "SwiftUIアプリ開発",
                    usageCount: 45,
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                intensity: 5,
                addedAt: "2025-01-27T10:00:00Z"
            ),
            UserInterestProfile(
                id: "prof-002",
                user: "user-001",
                category: nil,
                subcategory: nil,
                tag: InterestTag(
                    id: "tag-007",
                    subcategory: "art-sub-001",
                    name: "UI/UXデザイン",
                    description: "ユーザビリティ設計",
                    usageCount: 31,
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                intensity: 3,
                addedAt: "2025-01-27T10:01:00Z"
            )
        ]
    }
}

// MARK: - Supporting Types

struct CreateUserInterestProfileRequest: Codable {
    let tagId: String
    let intensity: Int
    
    enum CodingKeys: String, CodingKey {
        case tagId = "tag_id"
        case intensity
    }
}

struct HierarchicalTree: Codable {
    let category: InterestCategory
    let subcategories: [InterestSubcategoryWithTags]
}

struct InterestSubcategoryWithTags: Codable {
    let id: String
    let name: String
    let categoryId: String
    let description: String
    let tags: [InterestTag]
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, tags
        case categoryId = "category_id"
    }
} 