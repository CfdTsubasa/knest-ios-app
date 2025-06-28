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
    @Published var userProfiles: [UserInterestProfile] = [] // ProfileViewで使用されるプロパティ
    @Published var isLoading = false
    @Published var error: String?
    
    private let networkManager = NetworkManager.shared
    private let authManager = AuthenticationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - カテゴリ管理
    
    func loadCategories() {
        isLoading = true
        error = nil
        
        networkManager.makeRequest(
            endpoint: "/api/interests/hierarchical/categories/",
            method: .GET,
            responseType: [InterestCategory].self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("[ERROR] カテゴリ取得エラー: \(error.localizedDescription)")
                    
                    // エラー詳細処理
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .httpError(404):
                            // 404は正常（データがない状態）
                            print("[WARNING] カテゴリデータが存在しません。サンプルデータを使用します")
                            self?.categories = self?.generateSampleCategories() ?? []
                            self?.error = nil
                        case .httpError(500):
                            self?.error = "サーバーエラーが発生しました。しばらく後に再試行してください"
                            self?.categories = self?.generateSampleCategories() ?? []
                        default:
                            self?.error = "カテゴリの取得に失敗しました"
                            self?.categories = self?.generateSampleCategories() ?? []
                        }
                    } else {
                        self?.error = "カテゴリの取得に失敗しました"
                        self?.categories = self?.generateSampleCategories() ?? []
                    }
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] categories in
                print("[SUCCESS] カテゴリ取得成功: \(categories.count)個のカテゴリ")
                self?.categories = categories
            }
        )
        .store(in: &cancellables)
    }
    
    func loadSubcategories(for categoryId: String) {
        isLoading = true
        error = nil
        
        networkManager.makeRequest(
            endpoint: "/api/interests/hierarchical/subcategories/?category_id=\(categoryId)",
            method: .GET,
            responseType: [InterestSubcategory].self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("[ERROR] サブカテゴリ取得エラー: \(error.localizedDescription)")
                    self?.error = "サブカテゴリの取得に失敗しました"
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] subcategories in
                print("[SUCCESS] サブカテゴリ取得成功: \(subcategories.count)個")
                self?.subcategories = subcategories
            }
        )
        .store(in: &cancellables)
    }
    
    func loadTags(for subcategoryId: String) {
        isLoading = true
        error = nil
        
        networkManager.makeRequest(
            endpoint: "/api/interests/hierarchical/tags/?subcategory_id=\(subcategoryId)",
            method: .GET,
            responseType: [InterestTag].self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("[ERROR] タグ取得エラー: \(error.localizedDescription)")
                    self?.error = "タグの取得に失敗しました"
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] tags in
                print("[SUCCESS] タグ取得成功: \(tags.count)個")
                self?.tags = tags
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - ユーザー興味関心プロフィール操作
    
    func loadUserInterestProfile() {
        // 認証状態を確認
        guard authManager.isAuthenticated else {
            error = "ログインが必要です"
            print("[WARNING] 認証されていないため、ユーザー興味関心を取得できません")
            return
        }
        
        guard let token = authManager.getAccessToken() else {
            error = "認証トークンがありません。再ログインしてください"
            print("[ERROR] 認証トークンなし")
            return
        }
        
        isLoading = true
        error = nil
        
        networkManager.makeRequest(
            endpoint: "/api/interests/hierarchical/user-profiles/",
            method: .GET,
            token: token,
            responseType: [UserInterestProfile].self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("[ERROR] ユーザー興味プロフィール取得エラー: \(error.localizedDescription)")
                    
                    // エラー詳細処理
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .httpError(401):
                            self?.error = "ログイン期限が切れました。再ログインしてください"
                            self?.authManager.refreshTokenIfNeeded()
                        case .httpError(404):
                            // 404は新規ユーザーの正常状態
                            print("[WARNING] 新規ユーザーのため、興味関心プロフィールがありません")
                            self?.userProfiles = []
                            self?.error = nil
                        case .httpError(500):
                            self?.error = "サーバーエラーが発生しました。しばらく後に再試行してください"
                        default:
                            self?.error = "興味関心プロフィールの取得に失敗しました"
                        }
                    } else {
                        self?.error = "興味関心プロフィールの取得に失敗しました"
                    }
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] profiles in
                print("[SUCCESS] ユーザー興味プロフィール取得成功: \(profiles.count)個")
                self?.userProfiles = profiles
            }
        )
        .store(in: &cancellables)
    }
    
    // ProfileViewで使用するためのエイリアス
    func loadUserProfiles() {
        loadUserInterestProfile()
    }
    
    func addInterest(tagId: String) {
        // 認証状態を確認
        guard authManager.isAuthenticated else {
            error = "ログインが必要です"
            print("[WARNING] 認証されていないため、興味関心を追加できません")
            return
        }
        
        guard let token = authManager.getAccessToken() else {
            error = "認証トークンがありません。再ログインしてください"
            print("[ERROR] 認証トークンなし")
            return
        }
        
        isLoading = true
        error = nil
        
        let requestBody = CreateUserInterestProfileRequest(tagId: tagId)
        
        guard let body = try? JSONEncoder().encode(requestBody) else {
            error = "リクエストのエンコードに失敗しました"
            isLoading = false
            return
        }
        
        // makeRequestメソッドを使用（トークン付き）
        networkManager.makeRequest(
            endpoint: "/api/interests/hierarchical/user-profiles/",
            method: .POST,
            body: body,
            token: token,
            responseType: UserInterestProfile.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("[ERROR] 興味追加エラー: \(error.localizedDescription)")
                    self?.error = "興味の追加に失敗しました"
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] profile in
                print("[SUCCESS] 興味追加成功: \(profile.tag?.name ?? "Unknown")")
                // ユーザープロフィールを再読み込み
                self?.loadUserProfiles()
            }
        )
        .store(in: &cancellables)
    }
    
    func addInterestAtCategoryLevel(categoryId: String) {
        // 認証状態を確認
        guard authManager.isAuthenticated else {
            error = "ログインが必要です"
            print("[WARNING] 認証されていないため、興味関心を追加できません")
            return
        }
        
        guard let token = authManager.getAccessToken() else {
            error = "認証トークンがありません。再ログインしてください"
            print("[ERROR] 認証トークンなし")
            return
        }
        
        isLoading = true
        error = nil
        
        let requestBody = CreateUserInterestProfileCategoryRequest(categoryId: categoryId, level: 1)
        
        guard let body = try? JSONEncoder().encode(requestBody) else {
            error = "リクエストのエンコードに失敗しました"
            isLoading = false
            return
        }
        
        // カテゴリレベル追加API呼び出し
        networkManager.makeRequest(
            endpoint: "/api/interests/hierarchical/user-profiles/add_category_level/",
            method: .POST,
            body: body,
            token: token,
            responseType: UserInterestProfile.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("[ERROR] カテゴリレベル興味追加エラー: \(error.localizedDescription)")
                    self?.error = "カテゴリレベルでの興味追加に失敗しました"
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] profile in
                print("[SUCCESS] カテゴリレベル興味追加成功: \(profile.category?.name ?? "Unknown")")
                // ユーザープロフィールを再読み込み
                self?.loadUserProfiles()
            }
        )
        .store(in: &cancellables)
    }
    
    func addInterestAtSubcategoryLevel(categoryId: String, subcategoryId: String) {
        // 認証状態を確認
        guard authManager.isAuthenticated else {
            error = "ログインが必要です"
            print("[WARNING] 認証されていないため、興味関心を追加できません")
            return
        }
        
        guard let token = authManager.getAccessToken() else {
            error = "認証トークンがありません。再ログインしてください"
            print("[ERROR] 認証トークンなし")
            return
        }
        
        isLoading = true
        error = nil
        
        let requestBody = CreateUserInterestProfileSubcategoryRequest(
            categoryId: categoryId, 
            subcategoryId: subcategoryId, 
            level: 2
        )
        
        guard let body = try? JSONEncoder().encode(requestBody) else {
            error = "リクエストのエンコードに失敗しました"
            isLoading = false
            return
        }
        
        // サブカテゴリレベル追加API呼び出し
        networkManager.makeRequest(
            endpoint: "/api/interests/hierarchical/user-profiles/add_subcategory_level/",
            method: .POST,
            body: body,
            token: token,
            responseType: UserInterestProfile.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("[ERROR] サブカテゴリレベル興味追加エラー: \(error.localizedDescription)")
                    self?.error = "サブカテゴリレベルでの興味追加に失敗しました"
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] profile in
                print("[SUCCESS] サブカテゴリレベル興味追加成功: \(profile.subcategory?.name ?? "Unknown")")
                // ユーザープロフィールを再読み込み
                self?.loadUserProfiles()
            }
        )
        .store(in: &cancellables)
    }

    func removeInterest(profileId: String) {
        // 認証状態を確認
        guard authManager.isAuthenticated else {
            error = "ログインが必要です"
            print("[WARNING] 認証されていないため、興味関心を削除できません")
            return
        }
        
        guard let token = authManager.getAccessToken() else {
            error = "認証トークンがありません。再ログインしてください"
            print("[ERROR] 認証トークンなし")
            return
        }
        
        isLoading = true
        error = nil
        
        // makeRequestメソッドを使用（トークン付き）
        networkManager.makeRequest(
            endpoint: "/api/interests/hierarchical/user-profiles/\(profileId)/",
            method: .DELETE,
            token: token,
            responseType: EmptyResponse.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("[ERROR] 興味削除エラー: \(error.localizedDescription)")
                    self?.error = "興味の削除に失敗しました"
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] _ in
                print("[SUCCESS] 興味削除成功")
                // ユーザープロフィールを再読み込み
                self?.loadUserProfiles()
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
            endpoint: "/api/interests/hierarchical/tree/",
            method: .GET,
            responseType: [HierarchicalTree].self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("[ERROR] 階層ツリー取得エラー: \(error.localizedDescription)")
                    // フォールバック: サンプルデータを生成
                    self?.loadCategories()
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] trees in
                print("[SUCCESS] 階層ツリー取得成功: \(trees.count)個のカテゴリ")
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
                    category: tree.category,
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
        // カテゴリオブジェクトを検索
        guard let category = categories.first(where: { $0.id == categoryId }) else {
            return []
        }
        
        switch categoryId {
        case "tech-001":
            return [
                InterestSubcategory(
                    id: "tech-sub-001",
                    category: category,
                    name: "プログラミング",
                    description: "Web開発、アプリ開発",
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestSubcategory(
                    id: "tech-sub-002",
                    category: category,
                    name: "AI・機械学習",
                    description: "人工知能、データサイエンス",
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestSubcategory(
                    id: "tech-sub-003",
                    category: category,
                    name: "ガジェット",
                    description: "最新デバイス、電子工作",
                    createdAt: "2025-01-27T10:00:00Z"
                )
            ]
        case "art-001":
            return [
                InterestSubcategory(
                    id: "art-sub-001",
                    category: category,
                    name: "デザイン",
                    description: "UI/UX、グラフィック",
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestSubcategory(
                    id: "art-sub-002",
                    category: category,
                    name: "音楽",
                    description: "演奏、作曲、音響技術",
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestSubcategory(
                    id: "art-sub-003",
                    category: category,
                    name: "映像・写真",
                    description: "撮影技術、映像制作",
                    createdAt: "2025-01-27T10:00:00Z"
                )
            ]
        case "sport-001":
            return [
                InterestSubcategory(
                    id: "sport-sub-001",
                    category: category,
                    name: "フィットネス",
                    description: "トレーニング、筋トレ",
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestSubcategory(
                    id: "sport-sub-002",
                    category: category,
                    name: "チームスポーツ",
                    description: "サッカー、バスケ",
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestSubcategory(
                    id: "sport-sub-003",
                    category: category,
                    name: "個人スポーツ",
                    description: "ランニング、水泳",
                    createdAt: "2025-01-27T10:00:00Z"
                )
            ]
        case "study-001":
            return [
                InterestSubcategory(
                    id: "study-sub-001",
                    category: category,
                    name: "語学",
                    description: "英語、中国語学習",
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestSubcategory(
                    id: "study-sub-002",
                    category: category,
                    name: "資格・検定",
                    description: "IT資格、ビジネス資格",
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestSubcategory(
                    id: "study-sub-003",
                    category: category,
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
        // サブカテゴリオブジェクトを検索
        guard let subcategory = subcategories.first(where: { $0.id == subcategoryId }) else {
            return []
        }
        
        switch subcategoryId {
        case "tech-sub-001":
            return [
                InterestTag(
                    id: "tag-001",
                    subcategory: subcategory,
                    name: "iOS開発",
                    description: "SwiftUIアプリ開発",
                    usageCount: 45,
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestTag(
                    id: "tag-002",
                    subcategory: subcategory,
                    name: "Web開発",
                    description: "React、Vue.js",
                    usageCount: 38,
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestTag(
                    id: "tag-003",
                    subcategory: subcategory,
                    name: "Python",
                    description: "データ分析、自動化",
                    usageCount: 52,
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestTag(
                    id: "tag-004",
                    subcategory: subcategory,
                    name: "Django",
                    description: "Webフレームワーク",
                    usageCount: 29,
                    createdAt: "2025-01-27T10:00:00Z"
                )
            ]
        case "art-sub-001":
            return [
                InterestTag(
                    id: "tag-005",
                    subcategory: subcategory,
                    name: "Figma",
                    description: "UIデザインツール",
                    usageCount: 34,
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                InterestTag(
                    id: "tag-006",
                    subcategory: subcategory,
                    name: "Adobe XD",
                    description: "プロトタイピング",
                    usageCount: 27,
                    createdAt: "2025-01-27T10:00:00Z"
                )
            ]
        default:
            return []
        }
    }
    
    private func generateSampleUserProfile() -> [UserInterestProfile] {
        // サンプルサブカテゴリを検索
        let techSub = subcategories.first { $0.id == "tech-sub-001" }
        let artSub = subcategories.first { $0.id == "art-sub-001" }
        
        guard let techSubcategory = techSub, let artSubcategory = artSub else {
            return [] // サブカテゴリが見つからない場合は空配列を返す
        }
        
        return [
            UserInterestProfile(
                id: "prof-001",
                user: "user-001",
                category: nil,
                subcategory: nil,
                tag: InterestTag(
                    id: "tag-001",
                    subcategory: techSubcategory,
                    name: "iOS開発",
                    description: "SwiftUIアプリ開発",
                    usageCount: 45,
                    createdAt: "2025-01-27T10:00:00Z"
                ),
                addedAt: "2025-01-27T10:00:00Z"
            ),
            UserInterestProfile(
                id: "prof-002",
                user: "user-001",
                category: nil,
                subcategory: nil,
                tag: InterestTag(
                    id: "tag-007",
                    subcategory: artSubcategory,
                    name: "UI/UXデザイン",
                    description: "ユーザビリティ設計",
                    usageCount: 31,
                    createdAt: "2025-01-27T10:01:00Z"
                ),
                addedAt: "2025-01-27T10:01:00Z"
            )
        ]
    }

    // MARK: - Error Handling & Fallback
    
    private func getUserFriendlyErrorMessage(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "インターネット接続を確認してください"
            case .timedOut:
                return "通信がタイムアウトしました。再度お試しください"
            default:
                return "通信エラーが発生しました"
            }
        }
        
        // HTTPエラーの場合
        let errorString = error.localizedDescription
        if errorString.contains("401") {
            return "ログインの有効期限が切れています。再度ログインしてください"
        } else if errorString.contains("404") {
            return "データが見つかりませんでした"
        } else if errorString.contains("500") {
            return "サーバーで問題が発生しています。しばらくしてから再度お試しください"
        }
        
        return "エラーが発生しました。しばらくしてから再度お試しください"
    }
    
    // MARK: - Retry Methods
    
    func retryLoadUserProfiles() {
        loadUserProfiles()
    }
    
    func retryLoadCategories() {
        loadCategories()
    }
    
    func retryLoadSubcategories(for categoryId: String) {
        loadSubcategories(for: categoryId)
    }
    
    func retryLoadTags(for subcategoryId: String) {
        loadTags(for: subcategoryId)
    }

    // MARK: - 重複防止機能
    
    /// 既に選択済みのタグIDを取得
    var selectedTagIds: Set<String> {
        Set(userProfiles.compactMap { $0.tag?.id })
    }
    
    /// 既に選択済みのサブカテゴリIDを取得
    var selectedSubcategoryIds: Set<String> {
        Set(userProfiles.compactMap { $0.subcategory?.id })
    }
    
    /// 既に選択済みのカテゴリIDを取得
    var selectedCategoryIds: Set<String> {
        Set(userProfiles.compactMap { $0.category?.id })
    }
    
    /// 指定したタグが既に選択済みかチェック
    func isTagSelected(_ tagId: String) -> Bool {
        selectedTagIds.contains(tagId)
    }
    
    /// 指定したサブカテゴリが既に選択済みかチェック
    func isSubcategorySelected(_ subcategoryId: String) -> Bool {
        selectedSubcategoryIds.contains(subcategoryId)
    }
    
    /// 指定したカテゴリが既に選択済みかチェック
    func isCategorySelected(_ categoryId: String) -> Bool {
        selectedCategoryIds.contains(categoryId)
    }
}

// MARK: - Supporting Types

struct CreateUserInterestProfileRequest: Codable {
    let tagId: String
    
    enum CodingKeys: String, CodingKey {
        case tagId = "tag_id"
    }
}

struct CreateUserInterestProfileCategoryRequest: Codable {
    let categoryId: String
    let level: Int
    
    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case level
    }
}

struct CreateUserInterestProfileSubcategoryRequest: Codable {
    let categoryId: String
    let subcategoryId: String
    let level: Int
    
    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case subcategoryId = "subcategory_id"
        case level
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