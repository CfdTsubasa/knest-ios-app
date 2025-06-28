//
//  CircleManager.swift
//  KnestApp
//
//  Created by t.i on 2025/06/08.
//

import Foundation
import Combine
import SwiftUI

class CircleManager: ObservableObject {
    static let shared = CircleManager()
    
    @Published var circles: [KnestCircle] = []
    @Published var myCircles: [KnestCircle] = []
    @Published var recommendedCircles: [CircleRecommendation] = []
    @Published var circleDetail: KnestCircle?
    @Published var circleChats: [CircleChat] = []
    @Published var circlePosts: [CirclePost] = []
    @Published var circleEvents: [CircleEvent] = []
    @Published var circleMembers: [CircleMember] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var allCircles: [KnestCircle] = []
    
    // ページネーション用のプロパティ
    @Published var hasMoreChats = true
    @Published var isLoadingMoreChats = false
    private var currentChatPage = 1
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Load All Circles
    
    func loadCircles(page: Int = 1, search: String? = nil, category: String? = nil) {
        guard let token = networkManager.getAuthToken() else {
            errorMessage = "認証トークンがありません"
            return
        }
        
        print("[INFO] CircleManager.loadCircles 開始")
        print("   page: \(page), search: \(search ?? "nil"), category: \(category ?? "nil")")
        
        isLoading = true
        errorMessage = nil
        
        networkManager.getCircles(token: token, page: page, search: search, category: category)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("[ERROR] サークル取得失敗: \(error)")
                    }
                },
                receiveValue: { [weak self] response in
                    print("[SUCCESS] サークル取得成功")
                    print("   レスポンス: count=\(response.count)")
                    self?.allCircles = response.results
                    self?.isLoading = false
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Load My Circles
    
    func loadMyCircles() {
        guard let token = networkManager.getAuthToken() else {
            errorMessage = "認証トークンがありません"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.getMyCircles(token: token)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] circles in
                    DispatchQueue.main.async {
                        self?.myCircles = circles
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Load Recommended Circles
    
    func loadRecommendedCircles() {
        print("[INFO] CircleManager.loadRecommendedCircles 開始")
        guard let token = AuthenticationManager.shared.getAccessToken() else {
            print("[ERROR] 認証トークンがありません")
            return
        }
        
        isLoading = true
        
        networkManager.getRecommendedCircles(token: token)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        print("[ERROR] CircleManager.loadRecommendedCircles 失敗: \(error)")
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] circles in
                    print("[SUCCESS] CircleManager.loadRecommendedCircles 成功")
                    print("   取得されたサークル数: \(circles.count)")
                    // [KnestCircle] から [CircleRecommendation] に変換
                    let recommendations = circles.map { circle in
                        CircleRecommendation(
                            id: circle.id,
                            circle: circle,
                            recommendationScore: 0.8, // デフォルト値
                            recommendationReason: "おすすめ",
                            createdAt: circle.createdAt,
                            isViewed: false
                        )
                    }
                    self?.recommendedCircles = recommendations
                    print("   推薦サークル設定完了: \(recommendations.count)件")
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Load Circle Detail
    
    func loadCircleDetail(circleId: String) {
        guard let token = networkManager.getAuthToken() else {
            errorMessage = "認証トークンがありません"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.getCircleDetail(token: token, circleId: circleId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] circle in
                    DispatchQueue.main.async {
                        self?.circleDetail = circle
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Create Circle
    
    func createCircle(request: CreateCircleRequest) {
        guard let token = networkManager.getAuthToken() else {
            errorMessage = "認証トークンがありません"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.createCircle(token: token, request: request)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] circle in
                    DispatchQueue.main.async {
                        self?.myCircles.append(circle)
                        // 作成成功時に何らかの通知を出すことも可能
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Join Circle
    
    func joinCircle(circleId: String, message: String? = nil) {
        print("[START] CircleManager.joinCircle 開始")
        print("   サークルID: '\(circleId)'")
        print("   メッセージ: '\(message ?? "なし")'")
        
        guard let token = networkManager.getAuthToken() else {
            print("[ERROR] 認証トークンがありません")
            errorMessage = "認証トークンがありません"
            return
        }
        
        print("[SUCCESS] 認証トークン取得成功: \(token.prefix(20))...")
        
        isLoading = true
        errorMessage = nil
        
        let request = JoinCircleRequest(message: message)
        
        networkManager.joinCircle(token: token, circleId: circleId, request: request)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            print("[ERROR] CircleManager.joinCircle 失敗: \(error.localizedDescription)")
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] membership in
                    DispatchQueue.main.async {
                        print("[SUCCESS] CircleManager.joinCircle 成功")
                        print("   メンバーシップ: \(membership)")
                        // 参加成功時はエラーメッセージをクリア
                        self?.errorMessage = nil
                        
                        // 少し遅延してからマイサークルを再読み込み（UIの更新とのタイミング調整）
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.loadMyCircles()
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Leave Circle
    
    func leaveCircle(circleId: String) {
        guard let token = networkManager.getAuthToken() else {
            errorMessage = "認証トークンがありません"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.leaveCircle(token: token, circleId: circleId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] _ in
                    DispatchQueue.main.async {
                        // 退出成功時の処理
                        self?.myCircles.removeAll { $0.id == circleId }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Load Circle Chats
    
    func loadCircleChats(circleId: String, page: Int = 1) {
        guard let token = networkManager.getAuthToken() else {
            errorMessage = "認証トークンがありません"
            print("[ERROR] チャット取得失敗：認証トークンがありません")
            return
        }
        
        isLoading = true
        errorMessage = nil
        currentChatPage = 1
        hasMoreChats = true
        
        print("[START] チャット取得開始：circle: \(circleId), page: \(page)")
        print("[AUTH] 使用トークン：\(token.prefix(20))...")
        print("[URL] リクエストURL: /api/circles/chats/?circle=\(circleId)&page=\(page)")
        
        networkManager.getCircleChats(token: token, circleId: circleId, page: page)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = error.localizedDescription
                            print("[ERROR] チャット取得失敗：\(error.localizedDescription)")
                            print("[ERROR] エラー詳細：\(error)")
                            
                            // ネットワークエラーの詳細情報を出力
                            if let networkError = error as? NetworkError {
                                print("[ERROR] NetworkError type: \(networkError)")
                                switch networkError {
                                case .httpError(let code):
                                    print("[ERROR] HTTP Status Code: \(code)")
                                case .serverError(let message):
                                    print("[ERROR] Server Error: \(message)")
                                case .invalidURL:
                                    print("[ERROR] Invalid URL")
                                case .invalidResponse:
                                    print("[ERROR] Invalid Response")
                                case .encodingError:
                                    print("[ERROR] Encoding Error")
                                }
                            }
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    DispatchQueue.main.async {
                        print("[SUCCESS] チャット取得成功：\(response.results.count)件のメッセージ")
                        
                        // 各チャットメッセージの詳細を表示
                        for (index, chat) in response.results.enumerated() {
                            print("[MESSAGE] メッセージ[\(index)]: \"\(chat.content)\" from \(chat.sender.displayName ?? chat.sender.username)")
                        }
                        
                        self?.circleChats = response.results
                        self?.hasMoreChats = response.next != nil
                        print("[STATS] 現在のチャット表示数：\(self?.circleChats.count ?? 0)")
                        print("[STATUS] 次のページあり：\(self?.hasMoreChats ?? false)")
                        
                        // 現在のcircleChatsの内容をすべて表示
                        print("[LIST] 現在のcircleChats一覧:")
                        for (index, chat) in self?.circleChats.enumerated() ?? [].enumerated() {
                            print("  [\(index)]: \"\(chat.content)\" from \(chat.sender.displayName ?? chat.sender.username)")
                        }
                        
                        // デバッグ：最新のメッセージ内容を表示
                        if let latestMessage = response.results.last {
                            print("[LATEST] 最新メッセージ：\(latestMessage.content)")
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Load More Circle Chats (Pagination)
    
    func loadMoreCircleChats(circleId: String) {
        guard hasMoreChats && !isLoadingMoreChats else {
            print("[STATUS] ページネーション：読み込み不要（hasMore: \(hasMoreChats), isLoading: \(isLoadingMoreChats)）")
            return
        }
        
        guard let token = networkManager.getAuthToken() else {
            errorMessage = "認証トークンがありません"
            print("[ERROR] 追加チャット取得失敗：認証トークンがありません")
            return
        }
        
        isLoadingMoreChats = true
        currentChatPage += 1
        
        print("[START] 追加チャット取得開始：circle: \(circleId), page: \(currentChatPage)")
        
        networkManager.getCircleChats(token: token, circleId: circleId, page: currentChatPage)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoadingMoreChats = false
                        if case .failure(let error) = completion {
                            self?.currentChatPage -= 1 // エラー時はページ番号を戻す
                            print("[ERROR] 追加チャット取得失敗：\(error.localizedDescription)")
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    DispatchQueue.main.async {
                        print("[SUCCESS] 追加チャット取得成功：\(response.results.count)件のメッセージ")
                        
                        // 古いメッセージを先頭に追加（チャットは新しいものが下に表示されるため）
                        let newChats = response.results
                        self?.circleChats.insert(contentsOf: newChats, at: 0)
                        self?.hasMoreChats = response.next != nil
                        
                        print("[STATS] 追加後のチャット数：\(self?.circleChats.count ?? 0)")
                        print("[STATUS] 次のページあり：\(self?.hasMoreChats ?? false)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Send Circle Message
    
    func sendMessage(circleId: String, content: String) {
        guard let token = networkManager.getAuthToken() else {
            errorMessage = "認証トークンがありません"
            print("[ERROR] 送信失敗：認証トークンがありません")
            return
        }
        
        print("[START] メッセージ送信開始：\(content) to circle: \(circleId)")
        
        networkManager.sendCircleMessage(token: token, circleId: circleId, content: content)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        DispatchQueue.main.async {
                            self?.errorMessage = error.localizedDescription
                            print("[ERROR] メッセージ送信失敗：\(error.localizedDescription)")
                        }
                    }
                },
                receiveValue: { [weak self] chat in
                    DispatchQueue.main.async {
                        print("[SUCCESS] メッセージ送信成功：\(chat.content)")
                        
                        // 送信されたメッセージを即座にリストに追加
                        self?.circleChats.append(chat)
                        print("[STATS] 現在のチャット数：\(self?.circleChats.count ?? 0)")
                        
                        // 念のため少し遅延後にチャット一覧を再読み込み（最新状態を確保）
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.refreshCircleChats(circleId: circleId)
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Refresh Circle Chats (for ensuring latest state)
    
    private func refreshCircleChats(circleId: String) {
        guard let token = networkManager.getAuthToken() else { return }
        
        print("[INFO] チャット一覧を再読み込み中...")
        
        networkManager.getCircleChats(token: token, circleId: circleId, page: 1)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("[ERROR] チャット再読み込み失敗：\(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    DispatchQueue.main.async {
                        print("[SUCCESS] チャット再読み込み成功：\(response.results.count)件")
                        self?.circleChats = response.results
                        print("[STATS] 更新後のチャット数：\(self?.circleChats.count ?? 0)")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Load Circle Posts
    
    func loadCirclePosts(circleId: String, page: Int = 1) {
        guard let token = networkManager.getAuthToken() else {
            errorMessage = "認証トークンがありません"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.getCirclePosts(token: token, circleId: circleId, page: page)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    DispatchQueue.main.async {
                        if page == 1 {
                            self?.circlePosts = response.results
                        } else {
                            self?.circlePosts.append(contentsOf: response.results)
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Create Circle Post
    
    func createPost(circleId: String, content: String, mediaUrls: [String] = []) {
        guard let token = networkManager.getAuthToken() else {
            errorMessage = "認証トークンがありません"
            return
        }
        
        networkManager.createCirclePost(token: token, circleId: circleId, content: content, mediaUrls: mediaUrls)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        DispatchQueue.main.async {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] post in
                    DispatchQueue.main.async {
                        self?.circlePosts.insert(post, at: 0) // 最新の投稿を先頭に追加
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Load Circle Events
    
    func loadCircleEvents(circleId: String) {
        guard let token = networkManager.getAuthToken() else {
            errorMessage = "認証トークンがありません"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.getCircleEvents(token: token, circleId: circleId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] events in
                    DispatchQueue.main.async {
                        self?.circleEvents = events
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Create Circle Event
    
    func createEvent(circleId: String, request: CreateEventRequest) {
        guard let token = networkManager.getAuthToken() else {
            errorMessage = "認証トークンがありません"
            return
        }
        
        networkManager.createCircleEvent(token: token, circleId: circleId, request: request)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        DispatchQueue.main.async {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] event in
                    DispatchQueue.main.async {
                        self?.circleEvents.append(event)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Load Circle Members
    
    func loadCircleMembers(circleId: String) {
        print("[START] CircleManager.loadCircleMembers - circleId: \(circleId)")
        
        guard let token = networkManager.getAuthToken() else {
            print("[ERROR] loadCircleMembers: 認証トークンがありません")
            errorMessage = "認証トークンがありません"
            return
        }
        
        print("[AUTH] loadCircleMembers: トークン取得成功")
        isLoading = true
        errorMessage = nil
        
        print("[API] NetworkManager.getCircleMembers 呼び出し開始")
        
        networkManager.getCircleMembers(token: token, circleId: circleId)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            print("[ERROR] loadCircleMembers 失敗: \(error.localizedDescription)")
                            self?.errorMessage = error.localizedDescription
                        } else {
                            print("[SUCCESS] loadCircleMembers 完了処理")
                            self?.errorMessage = nil
                        }
                    }
                },
                receiveValue: { [weak self] members in
                    DispatchQueue.main.async {
                        print("[SUCCESS] loadCircleMembers メンバー取得成功:")
                        print("   取得メンバー数: \(members.count)")
                        
                        // 各メンバーの詳細を表示
                        for (index, member) in members.enumerated() {
                            print("   メンバー[\(index)]: \(member.user.displayName ?? member.user.username) (\(member.role.rawValue))")
                        }
                        
                        self?.circleMembers = members
                        print("[FINAL] circleMembers設定完了: \(self?.circleMembers.count ?? 0)人")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Utility Methods
    
    func clearError() {
        errorMessage = nil
    }
    
    func resetCircleDetail() {
        circleDetail = nil
    }
    
    func resetCircleChats() {
        circleChats = []
    }
    
    func resetCirclePosts() {
        circlePosts = []
    }
    
    func resetCircleEvents() {
        circleEvents = []
    }
    
    func resetCircleMembers() {
        circleMembers = []
    }
} 