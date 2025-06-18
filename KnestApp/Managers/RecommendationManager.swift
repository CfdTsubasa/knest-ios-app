//
//  RecommendationManager.swift
//  KnestApp
//
//  Created by t.i on 2025/06/08.
//

import Foundation
import Combine
import SwiftUI

/// 次世代推薦システム専用マネージャー
class RecommendationManager: ObservableObject {
    static let shared = RecommendationManager()
    
    // MARK: - Published Properties
    @Published var recommendations: [NextGenRecommendation] = []
    @Published var currentSession: NextGenRecommendationResponse?
    @Published var userPreferences: UserPreferences?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Settings
    @Published var selectedAlgorithm: String = "smart"
    @Published var recommendationLimit: Int = 10
    @Published var diversityFactor: Double = 0.3
    @Published var excludedCategories: [String] = []
    @Published var includeNewCircles: Bool = true
    
    // MARK: - Metrics
    @Published var viewedRecommendations: Set<String> = []
    @Published var clickedRecommendations: Set<String> = []
    @Published var dismissedRecommendations: Set<String> = []
    
    private let networkManager = NetworkManager.shared
    private let authManager = AuthenticationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// 推薦を取得
    func loadRecommendations(
        algorithm: String? = nil,
        limit: Int? = nil,
        diversityFactor: Double? = nil,
        excludeCategories: [String]? = nil,
        includeNewCircles: Bool? = nil
    ) {
        guard let token = authManager.getAccessToken() else {
            errorMessage = "認証トークンがありません"
            print("[ERROR] RecommendationManager: 認証トークンがありません")
            return
        }
        
        print("[INFO] RecommendationManager: 推薦データ取得開始")
        
        isLoading = true
        errorMessage = nil
        
        let finalAlgorithm = algorithm ?? selectedAlgorithm
        let finalLimit = limit ?? recommendationLimit
        let finalDiversityFactor = diversityFactor ?? self.diversityFactor
        let finalExcludeCategories = excludeCategories ?? excludedCategories
        let finalIncludeNewCircles = includeNewCircles ?? self.includeNewCircles
        
        print("[DEBUG] 推薦パラメータ: algorithm=\(finalAlgorithm), limit=\(finalLimit)")
        
        networkManager.getRecommendationsV2(
            token: token,
            algorithm: finalAlgorithm,
            limit: finalLimit,
            diversityFactor: finalDiversityFactor,
            excludeCategories: finalExcludeCategories,
            includeNewCircles: finalIncludeNewCircles
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                    print("[ERROR] RecommendationManager: 推薦取得エラー: \(error)")
                }
            },
            receiveValue: { [weak self] response in
                self?.currentSession = response
                self?.recommendations = response.recommendations
                print("[SUCCESS] RecommendationManager: 推薦取得成功: \(response.recommendations.count)件")
                print("[STATS] アルゴリズム: \(response.algorithmUsed)")
                print("[TIME] 計算時間: \(response.computationTimeMs)ms")
                
                // 推薦データの詳細ログ
                for (index, rec) in response.recommendations.enumerated() {
                    print("   [\(index)]: ID='\(rec.circle.id)', Name='\(rec.circle.name)'")
                }
            }
        )
        .store(in: &cancellables)
    }
    
    /// ユーザー設定を取得
    func loadUserPreferences() {
        guard let token = authManager.getAccessToken() else {
            errorMessage = "認証トークンがありません"
            return
        }
        
        networkManager.getUserPreferences(token: token)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("[ERROR] ユーザー設定取得エラー: \(error)")
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] preferences in
                    self?.userPreferences = preferences
                    print("[SUCCESS] ユーザー設定取得成功")
                }
            )
            .store(in: &cancellables)
    }
    
    /// 推薦設定を保存
    func saveSettings() {
        UserDefaults.standard.set(selectedAlgorithm, forKey: "recommendation_algorithm")
        UserDefaults.standard.set(recommendationLimit, forKey: "recommendation_limit")
        UserDefaults.standard.set(diversityFactor, forKey: "recommendation_diversity")
        UserDefaults.standard.set(excludedCategories, forKey: "recommendation_excluded_categories")
        UserDefaults.standard.set(includeNewCircles, forKey: "recommendation_include_new")
    }
    
    /// 推薦設定を読み込み
    func loadSettings() {
        selectedAlgorithm = UserDefaults.standard.string(forKey: "recommendation_algorithm") ?? "smart"
        recommendationLimit = UserDefaults.standard.integer(forKey: "recommendation_limit") == 0 ? 10 : UserDefaults.standard.integer(forKey: "recommendation_limit")
        diversityFactor = UserDefaults.standard.double(forKey: "recommendation_diversity") == 0 ? 0.3 : UserDefaults.standard.double(forKey: "recommendation_diversity")
        excludedCategories = UserDefaults.standard.array(forKey: "recommendation_excluded_categories") as? [String] ?? []
        includeNewCircles = UserDefaults.standard.object(forKey: "recommendation_include_new") == nil ? true : UserDefaults.standard.bool(forKey: "recommendation_include_new")
    }
    
    // MARK: - Feedback Methods
    
    /// フィードバック送信
    private func sendFeedback(
        for circle: KnestCircle,
        feedbackType: FeedbackType,
        score: Double? = nil,
        algorithm: String? = nil,
        reasons: [RecommendationReason]? = nil
    ) {
        guard let token = authManager.getAccessToken(),
              let session = currentSession else {
            print("[ERROR] フィードバック送信失敗: セッション情報がありません")
            return
        }
        
        let feedback = RecommendationFeedback(
            circleId: circle.id,
            feedbackType: feedbackType,
            sessionId: session.sessionId,
            recommendationScore: score,
            recommendationAlgorithm: algorithm ?? session.algorithmUsed,
            recommendationReasons: reasons
        )
        
        networkManager.sendRecommendationFeedback(token: token, feedback: feedback)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("[ERROR] フィードバック送信エラー: \(error)")
                    } else {
                        print("[SUCCESS] フィードバック送信成功: \(feedbackType.displayName)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
    }
    
    /// サークル閲覧をトラッキング
    func trackCircleView(for circle: KnestCircle) {
        if let recommendation = recommendations.first(where: { $0.circle.id == circle.id }) {
            viewedRecommendations.insert(circle.id)
            sendFeedback(
                for: circle,
                feedbackType: .view,
                score: recommendation.score,
                reasons: recommendation.reasons
            )
        }
    }
    
    /// サークルクリックをトラッキング
    func trackCircleClick(for circle: KnestCircle) {
        if let recommendation = recommendations.first(where: { $0.circle.id == circle.id }) {
            clickedRecommendations.insert(circle.id)
            sendFeedback(
                for: circle,
                feedbackType: .click,
                score: recommendation.score,
                reasons: recommendation.reasons
            )
        }
    }
    
    /// 参加申請をトラッキング
    func trackJoinRequest(for circle: KnestCircle) {
        if let recommendation = recommendations.first(where: { $0.circle.id == circle.id }) {
            sendFeedback(
                for: circle,
                feedbackType: .joinRequest,
                score: recommendation.score,
                reasons: recommendation.reasons
            )
        }
    }
    
    /// 参加成功をトラッキング
    func trackJoinSuccess(for circle: KnestCircle) {
        if let recommendation = recommendations.first(where: { $0.circle.id == circle.id }) {
            sendFeedback(
                for: circle,
                feedbackType: .joinSuccess,
                score: recommendation.score,
                reasons: recommendation.reasons
            )
        }
    }
    
    /// ブックマークをトラッキング
    func trackBookmark(for circle: KnestCircle) {
        if let recommendation = recommendations.first(where: { $0.circle.id == circle.id }) {
            sendFeedback(
                for: circle,
                feedbackType: .bookmark,
                score: recommendation.score,
                reasons: recommendation.reasons
            )
        }
    }
    
    /// シェアをトラッキング
    func trackShare(for circle: KnestCircle) {
        if let recommendation = recommendations.first(where: { $0.circle.id == circle.id }) {
            sendFeedback(
                for: circle,
                feedbackType: .share,
                score: recommendation.score,
                reasons: recommendation.reasons
            )
        }
    }
    
    /// 興味なしをトラッキング
    func trackNotInterested(for circle: KnestCircle) {
        if let recommendation = recommendations.first(where: { $0.circle.id == circle.id }) {
            sendFeedback(
                for: circle,
                feedbackType: .notInterested,
                score: recommendation.score,
                reasons: recommendation.reasons
            )
        }
    }
    
    /// 推薦を却下
    func dismissRecommendation(for circle: KnestCircle) {
        if let recommendation = recommendations.first(where: { $0.circle.id == circle.id }) {
            dismissedRecommendations.insert(circle.id)
            sendFeedback(
                for: circle,
                feedbackType: .dismiss,
                score: recommendation.score,
                reasons: recommendation.reasons
            )
            
            // ローカルからも除去
            DispatchQueue.main.async {
                self.recommendations.removeAll { $0.circle.id == circle.id }
            }
        }
    }
    
    // MARK: - Utility Methods
    
    /// 推薦が閲覧済みかチェック
    func isViewed(_ circle: KnestCircle) -> Bool {
        return viewedRecommendations.contains(circle.id)
    }
    
    /// 推薦がクリック済みかチェック
    func isClicked(_ circle: KnestCircle) -> Bool {
        return clickedRecommendations.contains(circle.id)
    }
    
    /// 推薦が却下済みかチェック
    func isDismissed(_ circle: KnestCircle) -> Bool {
        return dismissedRecommendations.contains(circle.id)
    }
    
    /// 推薦結果をリセット
    func resetRecommendations() {
        recommendations.removeAll()
        currentSession = nil
        viewedRecommendations.removeAll()
        clickedRecommendations.removeAll()
        dismissedRecommendations.removeAll()
    }
    
    /// セッションの統計情報を取得
    func getSessionStats() -> (viewed: Int, clicked: Int, dismissed: Int)? {
        guard currentSession != nil else { return nil }
        
        return (
            viewed: viewedRecommendations.count,
            clicked: clickedRecommendations.count,
            dismissed: dismissedRecommendations.count
        )
    }
} 