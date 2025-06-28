//
//  InterestManager.swift
//  KnestApp
//
//  Created by t.i on 2025/06/08.
//

import Foundation
import Combine

class InterestManager: ObservableObject {
    @Published var interests: [Interest] = []
    @Published var userInterests: [UserInterest] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let networkManager = NetworkManager.shared
    private let authManager = AuthenticationManager.shared
    
    // MARK: - Public Methods
    
    func loadInterests() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.getInterests()
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            // エラー時はサンプルデータを表示
                            self?.interests = self?.getSampleInterests() ?? []
                            self?.errorMessage = self?.getUserFriendlyErrorMessage(for: error)
                            print("[ERROR] 興味取得エラー: \(error)")
                        }
                    }
                },
                receiveValue: { [weak self] interests in
                    DispatchQueue.main.async {
                        self?.interests = interests
                        self?.errorMessage = nil
                        print("[SUCCESS] 興味取得成功: \(interests.count)個")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func loadUserInterests() {
        // 認証状態を確認
        guard authManager.isAuthenticated else {
            print("[WARNING] 認証されていないため、ユーザー興味を取得できません")
            errorMessage = "ログインが必要です"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.getUserInterests()
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            print("[ERROR] ユーザー興味取得エラー: \(error)")
                            
                            // エラー詳細処理
                            if let networkError = error as? NetworkError {
                                switch networkError {
                                case .httpError(401):
                                    self?.errorMessage = "ログイン期限が切れました。再ログインしてください"
                                    self?.authManager.refreshTokenIfNeeded()
                                case .httpError(404):
                                    // 404は新規ユーザーの正常状態
                                    print("[WARNING] 新規ユーザーのため、ユーザー興味がありません")
                                    self?.userInterests = []
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
                receiveValue: { [weak self] userInterests in
                    DispatchQueue.main.async {
                        self?.userInterests = userInterests
                        self?.errorMessage = nil
                        print("[SUCCESS] ユーザー興味取得成功: \(userInterests.count)個")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func addUserInterest(interestId: String) {
        // 認証状態を確認
        guard authManager.isAuthenticated else {
            errorMessage = "ログインが必要です"
            return
        }
        
        // より厳密な重複チェック
        guard !isUserInterestedIn(interestId) else { 
            print("[WARNING] 既に選択済みの興味です: \(interestId)")
            return 
        }
        
        print("[ROCKET] 興味を追加開始: \(interestId)")
        let request = CreateUserInterestRequest(interest_id: interestId)
        
        networkManager.createUserInterest(request: request)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("[ERROR] 興味追加エラー: \(error)")
                        
                        // エラー詳細処理
                        if let networkError = error as? NetworkError {
                            switch networkError {
                            case .httpError(401):
                                self?.errorMessage = "ログイン期限が切れました。再ログインしてください"
                                self?.authManager.refreshTokenIfNeeded()
                            case .httpError(404):
                                self?.errorMessage = "指定された興味が見つかりません"
                            case .httpError(400):
                                self?.errorMessage = "既に追加済みの興味です"
                            case .httpError(500):
                                self?.errorMessage = "サーバーエラーが発生しました。しばらく後に再試行してください"
                            default:
                                self?.errorMessage = "興味の追加に失敗しました"
                            }
                        } else {
                            self?.errorMessage = "興味の追加に失敗しました: \(error.localizedDescription)"
                        }
                    }
                },
                receiveValue: { [weak self] userInterest in
                    print("[SUCCESS] 興味追加成功: \(userInterest.interest.name)")
                    print("[SUCCESS] レスポンスID: \(userInterest.id)")
                    print("[SUCCESS] 現在のユーザー興味数: \(self?.userInterests.count ?? 0)")
                    
                    // 実際のレスポンスで更新（重複がないことを確認してから追加）
                    if !(self?.isUserInterestedIn(userInterest.interest.id) ?? false) {
                        self?.userInterests.append(userInterest)
                        print("[SUCCESS] ユーザー興味リストに追加完了。新しい数: \(self?.userInterests.count ?? 0)")
                    } else {
                        print("[WARNING] 既にリストに存在するためスキップ")
                    }
                    self?.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func removeUserInterest(userInterestId: Int) {
        // 認証状態を確認
        guard authManager.isAuthenticated else {
            errorMessage = "ログインが必要です"
            return
        }
        
        // 楽観的更新: UI上で即座に削除
        let removedInterest = userInterests.first { $0.id == userInterestId }
        userInterests.removeAll { $0.id == userInterestId }
        
        networkManager.deleteUserInterest(id: String(userInterestId))
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        // エラー時は削除を取り消し
                        if let interest = removedInterest {
                            self?.userInterests.append(interest)
                        }
                        
                        // エラー詳細処理
                        if let networkError = error as? NetworkError {
                            switch networkError {
                            case .httpError(401):
                                self?.errorMessage = "ログイン期限が切れました。再ログインしてください"
                                self?.authManager.refreshTokenIfNeeded()
                            case .httpError(404):
                                self?.errorMessage = "削除対象の興味が見つかりません"
                            case .httpError(500):
                                self?.errorMessage = "サーバーエラーが発生しました。しばらく後に再試行してください"
                            default:
                                self?.errorMessage = "興味の削除に失敗しました"
                            }
                        } else {
                            self?.errorMessage = "興味の削除に失敗しました: \(error.localizedDescription)"
                        }
                    }
                },
                receiveValue: { [weak self] _ in
                    self?.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Helper Methods
    
    func isUserInterestedIn(_ interestId: String) -> Bool {
        return userInterests.contains { $0.interest.id == interestId }
    }
    
    func getInterestsByCategory(_ category: LegacyInterestCategory) -> [Interest] {
        return interests.filter { $0.category == category.rawValue }
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
    
    private func getSampleInterests() -> [Interest] {
        return [
            Interest(
                id: "1",
                name: "プログラミング",
                description: "ソフトウェア開発とコーディング",
                category: "technical",
                isOfficial: true,
                usageCount: 150,
                iconUrl: nil,
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-01T00:00:00Z"
            ),
            Interest(
                id: "2",
                name: "読書",
                description: "小説、ビジネス書、技術書など",
                category: "learning",
                isOfficial: true,
                usageCount: 120,
                iconUrl: nil,
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-01T00:00:00Z"
            ),
            Interest(
                id: "3",
                name: "音楽",
                description: "楽器演奏、音楽鑑賞、作曲",
                category: "entertainment",
                isOfficial: true,
                usageCount: 100,
                iconUrl: nil,
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-01T00:00:00Z"
            ),
            Interest(
                id: "4",
                name: "映画",
                description: "映画鑑賞、映画制作、映画批評",
                category: "entertainment",
                isOfficial: true,
                usageCount: 95,
                iconUrl: nil,
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-01T00:00:00Z"
            ),
            Interest(
                id: "5",
                name: "料理",
                description: "料理作り、グルメ、食文化",
                category: "food",
                isOfficial: true,
                usageCount: 80,
                iconUrl: nil,
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-01T00:00:00Z"
            ),
            Interest(
                id: "6",
                name: "スポーツ",
                description: "各種スポーツ、フィットネス",
                category: "sports",
                isOfficial: true,
                usageCount: 75,
                iconUrl: nil,
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-01T00:00:00Z"
            ),
            Interest(
                id: "7",
                name: "旅行",
                description: "国内外旅行、観光、文化体験",
                category: "travel",
                isOfficial: true,
                usageCount: 65,
                iconUrl: nil,
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-01T00:00:00Z"
            ),
            Interest(
                id: "8",
                name: "アート",
                description: "絵画、彫刻、デザイン、美術鑑賞",
                category: "creative",
                isOfficial: true,
                usageCount: 70,
                iconUrl: nil,
                createdAt: "2025-01-01T00:00:00Z",
                updatedAt: "2025-01-01T00:00:00Z"
            )
        ]
    }
    
    // MARK: - Retry Methods
    
    func retryLoadUserInterests() {
        loadUserInterests()
    }
    
    func retryLoadInterests() {
        loadInterests()
    }
} 