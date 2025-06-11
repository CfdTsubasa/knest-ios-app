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
    
    // MARK: - Public Methods
    
    func loadInterests() {
        isLoading = true
        errorMessage = nil
        
        networkManager.getInterests()
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] interests in
                    self?.interests = interests
                }
            )
            .store(in: &cancellables)
    }
    
    func loadUserInterests() {
        isLoading = true
        errorMessage = nil
        
        networkManager.getUserInterests()
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("❌ ユーザー興味取得エラー: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] userInterests in
                    print("✅ ユーザー興味を取得: \(userInterests.count)件")
                    self?.userInterests = userInterests
                    // デバッグ用：取得した興味の詳細を表示
                    for userInterest in userInterests {
                        print("  - \(userInterest.interest.name) (ID: \(userInterest.id))")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func addUserInterest(interestId: String) {
        // より厳密な重複チェック
        guard !isUserInterestedIn(interestId) else { 
            print("⚠️ 既に選択済みの興味です: \(interestId)")
            return 
        }
        
        print("🚀 興味を追加開始: \(interestId)")
        let request = CreateUserInterestRequest(interest_id: interestId)
        
        // 楽観的更新を一時的に無効化（IDの型不一致のため）
        // TODO: より良い解決策を検討
        
        networkManager.createUserInterest(request: request)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("❌ 興味追加エラー: \(error)")
                        print("❌ 詳細エラー: \(error.localizedDescription)")
                        self?.errorMessage = "興味の追加に失敗しました: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] userInterest in
                    print("✅ 興味追加成功: \(userInterest.interest.name)")
                    print("✅ レスポンスID: \(userInterest.id)")
                    print("✅ 現在のユーザー興味数: \(self?.userInterests.count ?? 0)")
                    
                    // 実際のレスポンスで更新（重複がないことを確認してから追加）
                    if !(self?.isUserInterestedIn(userInterest.interest.id) ?? false) {
                        self?.userInterests.append(userInterest)
                        print("✅ ユーザー興味リストに追加完了。新しい数: \(self?.userInterests.count ?? 0)")
                    } else {
                        print("⚠️ 既にリストに存在するためスキップ")
                    }
                    self?.errorMessage = nil
                }
            )
            .store(in: &cancellables)
    }
    
    func removeUserInterest(userInterestId: Int) {
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
                        self?.errorMessage = "興味の削除に失敗しました: \(error.localizedDescription)"
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
} 