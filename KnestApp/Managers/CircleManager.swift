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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Load All Circles
    
    func loadCircles(page: Int = 1, search: String? = nil, category: String? = nil) {
        guard let token = networkManager.getAuthToken() else {
            errorMessage = "認証トークンがありません"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.getCircles(token: token, page: page, search: search, category: category)
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
                            self?.circles = response.results
                        } else {
                            self?.circles.append(contentsOf: response.results)
                        }
                    }
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
        guard let token = networkManager.getAuthToken() else {
            errorMessage = "認証トークンがありません"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        networkManager.getRecommendedCircles(token: token)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] recommendations in
                    DispatchQueue.main.async {
                        self?.recommendedCircles = recommendations
                    }
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
        guard let token = networkManager.getAuthToken() else {
            errorMessage = "認証トークンがありません"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let request = JoinCircleRequest(applicationMessage: message)
        
        networkManager.joinCircle(token: token, circleId: circleId, request: request)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                },
                receiveValue: { [weak self] membership in
                    DispatchQueue.main.async {
                        // 参加成功時の処理
                        self?.loadMyCircles() // マイサークルを再読み込み
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
            print("❌ チャット取得失敗：認証トークンがありません")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        print("📥 チャット取得開始：circle: \(circleId), page: \(page)")
        print("🔑 使用トークン：\(token.prefix(20))...")
        
        networkManager.getCircleChats(token: token, circleId: circleId, page: page)
            .sink(
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = error.localizedDescription
                            print("❌ チャット取得失敗：\(error.localizedDescription)")
                            print("❌ エラー詳細：\(error)")
                        }
                    }
                },
                receiveValue: { [weak self] chats in
                    DispatchQueue.main.async {
                        print("✅ チャット取得成功：\(chats.count)件のメッセージ")
                        
                        // 各チャットメッセージの詳細を表示
                        for (index, chat) in chats.enumerated() {
                            print("💬 メッセージ[\(index)]: \"\(chat.content)\" from \(chat.sender.displayName)")
                        }
                        
                        if page == 1 {
                            self?.circleChats = chats
                        } else {
                            self?.circleChats.append(contentsOf: chats)
                        }
                        print("📊 現在のチャット表示数：\(self?.circleChats.count ?? 0)")
                        
                        // 現在のcircleChatsの内容をすべて表示
                        print("📋 現在のcircleChats一覧:")
                        for (index, chat) in self?.circleChats.enumerated() ?? [].enumerated() {
                            print("  [\(index)]: \"\(chat.content)\" from \(chat.sender.displayName)")
                        }
                        
                        // デバッグ：最新のメッセージ内容を表示
                        if let latestMessage = chats.last {
                            print("📝 最新メッセージ：\(latestMessage.content)")
                        }
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Send Circle Message
    
    func sendMessage(circleId: String, content: String) {
        guard let token = networkManager.getAuthToken() else {
            errorMessage = "認証トークンがありません"
            print("❌ 送信失敗：認証トークンがありません")
            return
        }
        
        print("📤 メッセージ送信開始：\(content) to circle: \(circleId)")
        
        networkManager.sendCircleMessage(token: token, circleId: circleId, content: content)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        DispatchQueue.main.async {
                            self?.errorMessage = error.localizedDescription
                            print("❌ メッセージ送信失敗：\(error.localizedDescription)")
                        }
                    }
                },
                receiveValue: { [weak self] chat in
                    DispatchQueue.main.async {
                        print("✅ メッセージ送信成功：\(chat.content)")
                        self?.circleChats.append(chat)
                        print("📊 現在のチャット数：\(self?.circleChats.count ?? 0)")
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
} 