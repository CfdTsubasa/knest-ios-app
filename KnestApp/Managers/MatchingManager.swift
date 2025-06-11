//
//  MatchingManager.swift
//  KnestApp
//
//  Created by Claude on 2025/06/08.
//

import Foundation
import Combine

@MainActor
class MatchingManager: ObservableObject {
    @Published var userMatches: [UserMatch] = []
    @Published var circleMatches: [CircleMatch] = []
    @Published var recommendedCircles: [CircleMatch] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let networkManager = NetworkManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - ユーザーマッチング
    
    func findMatchingUsers(limit: Int = 20) {
        isLoading = true
        error = nil
        
        // makeRequestメソッドを使用
        networkManager.makeRequest(
            endpoint: "/interests/matching/find_user_matches/?limit=\(limit)",
            method: .GET,
            responseType: [UserMatch].self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("❌ ユーザーマッチングエラー: \(error.localizedDescription)")
                    // フォールバック: サンプルデータを使用
                    self?.userMatches = self?.generateSampleUserMatches() ?? []
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] matches in
                print("✅ ユーザーマッチング成功: \(matches.count)件")
                self?.userMatches = matches
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - サークルマッチング
    
    func findMatchingCircles(limit: Int = 20) {
        isLoading = true
        error = nil
        
        // TODO: バックエンドAPIが実装されるまで、サンプルデータを生成
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.circleMatches = self.generateSampleCircleMatches()
            self.isLoading = false
        }
        
        /*
        networkManager.request(
            endpoint: "/matching/circles/?limit=\(limit)",
            method: .GET,
            responseType: [CircleMatch].self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    self?.error = "サークルマッチングに失敗しました: \(error.localizedDescription)"
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] matches in
                self?.circleMatches = matches
            }
        )
        .store(in: &cancellables)
        */
    }
    
    // MARK: - おすすめサークル
    
    func loadRecommendedCircles() {
        isLoading = true
        error = nil
        
        // TODO: バックエンドAPIが実装されるまで、サンプルデータを生成
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.recommendedCircles = self.generateSampleRecommendations()
            self.isLoading = false
        }
        
        /*
        networkManager.request(
            endpoint: "/matching/circles/recommended/",
            method: .GET,
            responseType: [CircleMatch].self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    self?.error = "おすすめサークルの取得に失敗しました: \(error.localizedDescription)"
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] circles in
                self?.recommendedCircles = circles
            }
        )
        .store(in: &cancellables)
        */
    }
    
    // MARK: - 検索
    
    func searchCircles(query: String, filters: [String: Any] = [:]) {
        isLoading = true
        error = nil
        
        // TODO: バックエンドAPIが実装されるまで、サンプルデータを生成
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.circleMatches = self.generateSampleSearchResults(query: query)
            self.isLoading = false
        }
        
        /*
        var endpoint = "/circles/search/?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        // フィルター追加
        for (key, value) in filters {
            endpoint += "&\(key)=\(value)"
        }
        
        networkManager.request(
            endpoint: endpoint,
            method: .GET,
            responseType: [Circle].self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    self?.error = "検索に失敗しました: \(error.localizedDescription)"
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] circles in
                // CircleをCircleMatchに変換（スコアは仮の値）
                let matches = circles.map { circle in
                    CircleMatch(
                        id: circle.id,
                        circle: circle,
                        score: MatchingScore(totalScore: 0.0, interestScore: 0.0, locationScore: 0.0, ageScore: 0.0, commonInterests: []),
                        memberCount: 0,
                        matchReason: "検索結果"
                    )
                }
                self?.circleMatches = matches
            }
        )
        .store(in: &cancellables)
        */
    }
}

// MARK: - サンプルデータ生成（開発用）

extension MatchingManager {
    private func generateSampleUserMatches() -> [UserMatch] {
        let sampleUsers = [
            ("田中太郎", "tanaka", "プログラミングが好きな大学生です", 0.85),
            ("佐藤花子", "sato", "読書と映画鑑賞が趣味です", 0.78),
            ("山田次郎", "yamada", "スポーツ全般が大好きです", 0.72),
            ("鈴木美咲", "suzuki", "料理とカフェ巡りが趣味です", 0.89),
            ("高橋健太", "takahashi", "旅行と写真撮影が好きです", 0.65)
        ]
        
        return sampleUsers.enumerated().map { index, userData in
            let (displayName, username, bio, totalScore) = userData
            
            return UserMatch(
                id: "user_match_\(index)",
                user: User(
                    id: "user_\(index)",
                    username: username,
                    email: "\(username)@example.com",
                    displayName: displayName,
                    avatarUrl: nil,
                    bio: bio,
                    emotionState: "happy",
                    birthDate: "1995-06-15",
                    prefecture: "東京都",
                    isPremium: false,
                    lastActive: "2025-06-08T12:00:00Z",
                    createdAt: "2025-06-08T12:00:00Z",
                    updatedAt: "2025-06-08T12:00:00Z"
                ),
                score: MatchingScore(
                    totalScore: totalScore,
                    interestScore: totalScore * 0.6,
                    locationScore: totalScore * 0.2,
                    ageScore: totalScore * 0.2,
                    commonInterests: Array(["プログラミング", "ゲーム", "読書"].prefix(Int.random(in: 1...3)))
                ),
                matchReason: "興味関心が\(Int(totalScore * 100))%一致しています"
            )
        }
    }
    
    private func generateSampleCircleMatches() -> [CircleMatch] {
        let sampleCircles = [
            ("Swiftプログラミング部", "iOS開発を学びながら、楽しくアプリを作ろう！", 0.92),
            ("読書愛好会", "月1回の読書会で、様々なジャンルの本について語り合いましょう", 0.85),
            ("カフェ巡りサークル", "東京都内の素敵なカフェを一緒に巡りませんか？", 0.78),
            ("フットサル仲間募集", "週末に気軽にフットサルを楽しむサークルです", 0.71),
            ("料理研究会", "みんなで料理を作って、レシピをシェアしよう", 0.88)
        ]
        
        return sampleCircles.enumerated().map { index, circleData in
            let (name, description, totalScore) = circleData
            
            return CircleMatch(
                id: "circle_match_\(index)",
                circle: KnestCircle(
                    id: "circle_\(index)",
                    name: name,
                    description: description,
                    status: .open,
                    circleType: .public,
                    createdAt: "2025-06-08T12:00:00Z",
                    updatedAt: "2025-06-08T12:00:00Z",
                    owner: User.sample(),
                    interests: [],
                    lastActivityAt: "2025-06-08T12:00:00Z",
                    memberCount: Int.random(in: 5...15),
                    isMember: false,
                    membershipStatus: nil,
                    categories: [],
                    tags: Array(["プログラミング", "読書", "カフェ"].prefix(Int.random(in: 1...3))),
                    postCount: Int.random(in: 0...20),
                    iconUrl: nil,
                    coverUrl: nil,
                    rules: nil,
                    memberLimit: nil
                ),
                score: MatchingScore(
                    totalScore: totalScore,
                    interestScore: totalScore * 0.7,
                    locationScore: totalScore * 0.2,
                    ageScore: totalScore * 0.1,
                    commonInterests: Array(["プログラミング", "読書", "カフェ"].prefix(Int.random(in: 1...3)))
                ),
                memberCount: Int.random(in: 5...15),
                matchReason: "あなたの興味に\(Int(totalScore * 100))%マッチしています"
            )
        }
    }
    
    private func generateSampleRecommendations() -> [CircleMatch] {
        return generateSampleCircleMatches().sorted { $0.score.totalScore > $1.score.totalScore }
    }
    
    private func generateSampleSearchResults(query: String) -> [CircleMatch] {
        if query.isEmpty {
            return generateSampleCircleMatches()
        }
        
        let allMatches = generateSampleCircleMatches()
        return allMatches.filter { match in
            match.circle.name.localizedCaseInsensitiveContains(query) ||
            match.circle.description.localizedCaseInsensitiveContains(query) ||
            match.circle.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
} 