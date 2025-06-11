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
                            self?.errorMessage = error.localizedDescription
                            print("❌ ユーザータグ取得エラー: \(error)")
                        }
                    }
                },
                receiveValue: { [weak self] userTags in
                    DispatchQueue.main.async {
                        self?.userTags = userTags
                        print("✅ ユーザータグ取得成功: \(userTags.count)個")
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
                        self?.errorMessage = error.localizedDescription
                        print("❌ 人気タグ取得エラー: \(error)")
                    }
                },
                receiveValue: { [weak self] tags in
                    DispatchQueue.main.async {
                        self?.popularTags = tags
                        print("✅ 人気タグ取得成功: \(tags.count)個")
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
                        self?.errorMessage = error.localizedDescription
                        print("❌ タグ検索エラー: \(error)")
                    }
                },
                receiveValue: { [weak self] tags in
                    DispatchQueue.main.async {
                        self?.suggestedTags = tags
                        print("✅ タグ検索成功: \(tags.count)個")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func addTag(name: String) {
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
                            self?.errorMessage = error.localizedDescription
                            print("❌ タグ追加エラー: \(error)")
                        }
                    }
                },
                receiveValue: { [weak self] userTag in
                    DispatchQueue.main.async {
                        self?.userTags.append(userTag)
                        self?.errorMessage = nil
                        print("✅ タグ追加成功: #\(userTag.tag.name)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func removeTag(_ userTag: UserTag) {
        networkManager.deleteUserTag(id: userTag.id)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        DispatchQueue.main.async {
                            self?.errorMessage = error.localizedDescription
                            print("❌ タグ削除エラー: \(error)")
                        }
                    }
                },
                receiveValue: { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.userTags.removeAll { $0.id == userTag.id }
                        self?.errorMessage = nil
                        print("✅ タグ削除成功: #\(userTag.tag.name)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func clearError() {
        errorMessage = nil
    }
} 