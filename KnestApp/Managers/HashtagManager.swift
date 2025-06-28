//
//  HashtagManager.swift
//  KnestApp
//
//  Created by t.i on 2025/06/08.
//

import Foundation
import Combine

class HashtagManager: ObservableObject {
    static let shared = HashtagManager()
    
    @Published var userTags: [UserTag] = []
    @Published var suggestedTags: [Tag] = []
    @Published var popularTags: [Tag] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let networkManager = NetworkManager.shared
    private let authManager = AuthenticationManager.shared
    
    private init() {}
    
    // MARK: - Public Methods
    
    func loadUserTags() {
        isLoading = true
        errorMessage = nil
        
        networkManager.getUserTags()
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            print("[ERROR] ユーザータグ取得エラー: \(error)")
                            
                            // エラー詳細処理（認証不要のAPIだが、念のため確認）
                            if let networkError = error as? NetworkError {
                                switch networkError {
                                case .httpError(401):
                                    self?.errorMessage = "ログイン期限が切れました。再ログインしてください"
                                    if self?.authManager.isAuthenticated == true {
                                        self?.authManager.refreshTokenIfNeeded()
                                    }
                                case .httpError(404):
                                    // 404は新規ユーザーの正常状態
                                    print("[WARNING] 新規ユーザーのため、ユーザータグがありません")
                                    self?.userTags = []
                                    self?.errorMessage = nil
                                case .httpError(500):
                                    self?.errorMessage = "サーバーエラーが発生しました。しばらく後に再試行してください"
                                default:
                                    self?.errorMessage = self?.getUserFriendlyErrorMessage(for: error)
                                }
                            } else {
                                self?.errorMessage = self?.getUserFriendlyErrorMessage(for: error)
                            }
                        }
                    }
                },
                receiveValue: { [weak self] userTags in
                    DispatchQueue.main.async {
                        self?.userTags = userTags
                        print("[SUCCESS] ユーザータグ取得成功: \(userTags.count)個")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func loadPopularTags() {
        networkManager.getPopularTags()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        DispatchQueue.main.async {
                            self?.popularTags = self?.getSamplePopularTags() ?? []
                            self?.errorMessage = self?.getUserFriendlyErrorMessage(for: error)
                        }
                        print("[ERROR] 人気タグ取得エラー: \(error)")
                    }
                },
                receiveValue: { [weak self] tags in
                    DispatchQueue.main.async {
                        self?.popularTags = tags
                        self?.errorMessage = nil
                        print("[SUCCESS] 人気タグ取得成功: \(tags.count)個")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func searchTags(query: String) {
        guard !query.isEmpty else {
            suggestedTags = []
            return
        }
        
        networkManager.getTags(search: query)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        DispatchQueue.main.async {
                            self?.errorMessage = self?.getUserFriendlyErrorMessage(for: error)
                        }
                        print("[ERROR] タグ検索エラー: \(error)")
                    }
                },
                receiveValue: { [weak self] tags in
                    DispatchQueue.main.async {
                        self?.suggestedTags = tags
                        self?.errorMessage = nil
                        print("[SUCCESS] タグ検索成功: \(tags.count)個")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func addTag(name: String) {
        // 認証状態を確認（認証が必要な場合のみ）
        guard authManager.isAuthenticated else {
            errorMessage = "ログインが必要です"
            return
        }
        
        // 正規化：#を除去、トリミング
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        
        guard !cleanedName.isEmpty else {
            errorMessage = "タグ名を入力してください"
            return
        }
        
        // 重複チェック
        if userTags.contains(where: { $0.tag.name == cleanedName }) {
            errorMessage = "このタグは既に追加されています"
            return
        }
        
        let request = CreateUserTagRequest(tag_name: cleanedName)
        
        networkManager.createUserTag(request: request)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        DispatchQueue.main.async {
                            print("[ERROR] タグ追加エラー: \(error)")
                            
                            // エラー詳細処理
                            if let networkError = error as? NetworkError {
                                switch networkError {
                                case .httpError(401):
                                    self?.errorMessage = "ログイン期限が切れました。再ログインしてください"
                                    self?.authManager.refreshTokenIfNeeded()
                                case .httpError(404):
                                    self?.errorMessage = "タグの作成に失敗しました"
                                case .httpError(400):
                                    self?.errorMessage = "既に追加済みのタグです"
                                case .httpError(500):
                                    self?.errorMessage = "サーバーエラーが発生しました。しばらく後に再試行してください"
                                default:
                                    self?.errorMessage = "タグの追加に失敗しました"
                                }
                            } else {
                                self?.errorMessage = error.localizedDescription
                            }
                        }
                    }
                },
                receiveValue: { [weak self] userTag in
                    DispatchQueue.main.async {
                        self?.userTags.append(userTag)
                        self?.errorMessage = nil
                        print("[SUCCESS] タグ追加成功: #\(userTag.tag.name)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func removeTag(_ userTag: UserTag) {
        // 認証状態を確認
        guard authManager.isAuthenticated else {
            errorMessage = "ログインが必要です"
            return
        }
        
        networkManager.deleteUserTag(id: userTag.id)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        DispatchQueue.main.async {
                            print("[ERROR] タグ削除エラー: \(error)")
                            
                            // エラー詳細処理
                            if let networkError = error as? NetworkError {
                                switch networkError {
                                case .httpError(401):
                                    self?.errorMessage = "ログイン期限が切れました。再ログインしてください"
                                    self?.authManager.refreshTokenIfNeeded()
                                case .httpError(404):
                                    self?.errorMessage = "削除対象のタグが見つかりません"
                                case .httpError(500):
                                    self?.errorMessage = "サーバーエラーが発生しました。しばらく後に再試行してください"
                                default:
                                    self?.errorMessage = "タグの削除に失敗しました"
                                }
                            } else {
                                self?.errorMessage = error.localizedDescription
                            }
                        }
                    }
                },
                receiveValue: { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.userTags.removeAll { $0.id == userTag.id }
                        self?.errorMessage = nil
                        print("[SUCCESS] タグ削除成功: #\(userTag.tag.name)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func clearError() {
        errorMessage = nil
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
    
    private func getSamplePopularTags() -> [Tag] {
        return [
            Tag(id: 1, name: "プログラミング", usageCount: 150, createdAt: "2025-01-01T00:00:00Z"),
            Tag(id: 2, name: "読書", usageCount: 120, createdAt: "2025-01-01T00:00:00Z"),
            Tag(id: 3, name: "映画鑑賞", usageCount: 100, createdAt: "2025-01-01T00:00:00Z"),
            Tag(id: 4, name: "音楽", usageCount: 95, createdAt: "2025-01-01T00:00:00Z"),
            Tag(id: 5, name: "料理", usageCount: 80, createdAt: "2025-01-01T00:00:00Z"),
            Tag(id: 6, name: "スポーツ", usageCount: 75, createdAt: "2025-01-01T00:00:00Z"),
            Tag(id: 7, name: "写真", usageCount: 70, createdAt: "2025-01-01T00:00:00Z"),
            Tag(id: 8, name: "旅行", usageCount: 65, createdAt: "2025-01-01T00:00:00Z")
        ]
    }
    
    // MARK: - Retry Methods
    
    func retryLoadUserTags() {
        loadUserTags()
    }
    
    func retryLoadPopularTags() {
        loadPopularTags()
    }
} 