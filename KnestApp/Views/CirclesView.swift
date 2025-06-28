//
//  CirclesView.swift
//  KnestApp
//
//  Created by t.i on 2025/06/07.
//

import SwiftUI
import Foundation

struct CirclesView: View {
    @StateObject private var circleManager = CircleManager()
    @State private var searchText = ""
    @State private var selectedTab = 0
    @State private var showingCreateCircle = false
    
    var body: some View {
        NavigationView {
            VStack {
                // セグメントコントロール（3つのタブに変更）
                Picker("タブ", selection: $selectedTab) {
                    Text("すべて").tag(0)
                    Text("検索").tag(1)
                    Text("おすすめ").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // コンテンツ
                if circleManager.isLoading {
                    Spacer()
                    ProgressView("読み込み中...")
                    Spacer()
                } else {
                    switch selectedTab {
                    case 0:
                        AllCirclesView(circleManager: circleManager)
                    case 1:
                        SearchCirclesView(circleManager: circleManager, searchText: $searchText)
                    case 2:
                        RecommendedCirclesView(circleManager: circleManager)
                    default:
                        EmptyView()
                    }
                }
            }
            .navigationTitle("サークル")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateCircle = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateCircle) {
                CreateCircleView()
            }
            .onAppear {
                loadDataForSelectedTab()
            }
            .onChange(of: selectedTab) { _, newValue in
                loadDataForSelectedTab()
            }
        }
    }
    
    private func loadDataForSelectedTab() {
        switch selectedTab {
        case 0:
            circleManager.loadCircles()
        case 1:
            // 検索タブでは初期データは読み込まない
            break
        case 2:
            circleManager.loadRecommendedCircles()
        default:
            break
        }
    }
}

// MARK: - All Circles View（すべてのサークル）
struct AllCirclesView: View {
    @ObservedObject var circleManager: CircleManager
    
    var body: some View {
        VStack {
            if circleManager.circles.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "globe")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("サークルがありません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("新しいサークルが作成されるとここに表示されます")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                Spacer()
            } else {
                List(circleManager.circles) { circle in
                    NavigationLink(destination: CircleDetailView(circle: circle, selectedTab: .constant(0))) {
                        CircleRowView(circle: circle)
                    }
                    .onTapGesture {
                        print("[DEBUG] サークル選択: ID='\(circle.id)', Name='\(circle.name)'")
                    }
                }
                .onAppear {
                    print("[STATS] AllCirclesView - 表示されているサークル数: \(circleManager.circles.count)")
                    for (index, circle) in circleManager.circles.enumerated() {
                        print("   [\(index)]: ID='\(circle.id)', Name='\(circle.name)'")
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Search Circles View（サークル検索）
struct SearchCirclesView: View {
    @ObservedObject var circleManager: CircleManager
    @Binding var searchText: String
    @State private var searchResults: [KnestCircle] = []
    @State private var isSearching = false
    
    var body: some View {
        VStack {
            // 検索バー
            CircleSearchBar(text: $searchText, onSearchButtonClicked: {
                performSearch()
            })
            .padding(.horizontal)
            
            // 検索結果
            if isSearching {
                VStack {
                    Spacer()
                    ProgressView("検索中...")
                    Spacer()
                }
            } else if searchText.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("サークルを検索")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("キーワードを入力してサークルを探してみましょう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                Spacer()
            } else if searchResults.isEmpty && !searchText.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("検索結果がありません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("「\(searchText)」に一致するサークルが見つかりませんでした")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                Spacer()
            } else {
                List(searchResults) { circle in
                    NavigationLink(destination: CircleDetailView(circle: circle, selectedTab: .constant(0))) {
                        CircleRowView(circle: circle)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        // 検索実行
        circleManager.loadCircles(search: searchText)
        
        // CircleManagerの検索結果を監視
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            searchResults = circleManager.circles
            isSearching = false
        }
    }
}

// MARK: - Recommended Circles View
struct RecommendedCirclesView: View {
    @ObservedObject var circleManager: CircleManager
    @ObservedObject private var recommendationManager = RecommendationManager.shared
    @State private var showingSettings = false
    @State private var useNextGenEngine = true
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("おすすめ")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let session = recommendationManager.currentSession {
                        Text("アルゴリズム: \(session.algorithmUsed) • \(session.count)件")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: { showingSettings = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if useNextGenEngine {
                NextGenRecommendationsListView(
                    circleManager: circleManager,
                    recommendationManager: recommendationManager
                )
            } else {
                LegacyRecommendationsView(circleManager: circleManager)
            }
        }
        .sheet(isPresented: $showingSettings) {
            RecommendationSettingsView(
                circleManager: circleManager,
                recommendationManager: recommendationManager
            )
        }
        .onAppear {
            print("[DEBUG] RecommendedCirclesView.onAppear - useNextGenEngine: \(useNextGenEngine)")
            if useNextGenEngine {
                print("[INFO] NextGen推薦エンジンを使用")
                recommendationManager.loadRecommendations()
                recommendationManager.loadUserPreferences()
            } else {
                print("[INFO] レガシー推薦エンジンを使用（MatchingManager）")
                circleManager.loadRecommendedCircles()
            }
        }
    }
}

// MARK: - Next Generation Recommendations View
struct NextGenRecommendationsListView: View {
    @ObservedObject var circleManager: CircleManager
    @ObservedObject var recommendationManager: RecommendationManager
    
    var body: some View {
        if recommendationManager.isLoading {
            ProgressView("推薦を計算中...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if recommendationManager.recommendations.isEmpty {
            EmptyRecommendationView()
        } else {
            List(recommendationManager.recommendations) { recommendation in
                NavigationLink(
                    destination: CircleDetailView(circle: recommendation.circle, selectedTab: .constant(0))
                        .onAppear {
                            recommendationManager.trackCircleView(for: recommendation.circle)
                        }
                ) {
                    NextGenRecommendationRowView(
                        recommendation: recommendation,
                        onDismiss: {
                            recommendationManager.dismissRecommendation(for: recommendation.circle)
                        },
                        onNotInterested: {
                            recommendationManager.trackNotInterested(for: recommendation.circle)
                        }
                    )
                }
                .onTapGesture {
                    print("[DEBUG] NextGen推薦サークル選択: ID='\(recommendation.circle.id)', Name='\(recommendation.circle.name)'")
                    recommendationManager.trackCircleClick(for: recommendation.circle)
                }
            }
            .refreshable {
                recommendationManager.loadRecommendations()
            }
            .onAppear {
                print("[STATS] NextGenRecommendationsListView - 表示中のrecommendations数: \(recommendationManager.recommendations.count)")
                for (index, rec) in recommendationManager.recommendations.enumerated() {
                    print("   [\(index)]: ID='\(rec.circle.id)', Name='\(rec.circle.name)'")
                }
            }
        }
    }
}

// MARK: - Legacy Recommendations View
struct LegacyRecommendationsView: View {
    @ObservedObject var circleManager: CircleManager
    
    var body: some View {
        if circleManager.recommendedCircles.isEmpty {
            Spacer()
            VStack(spacing: 16) {
                Image(systemName: "star")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("おすすめサークルはありません")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("興味・関心を登録すると、\nあなたにぴったりのサークルを\nおすすめします")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            Spacer()
        } else {
            List(circleManager.recommendedCircles) { recommendation in
                NavigationLink(destination: CircleDetailView(circle: recommendation.circle, selectedTab: .constant(0))) {
                    RecommendedCircleRowView(recommendation: recommendation)
                }
                .onTapGesture {
                    print("[DEBUG] Legacy推薦サークル選択: ID='\(recommendation.circle.id)', Name='\(recommendation.circle.name)'")
                }
            }
            .onAppear {
                print("[STATS] LegacyRecommendationsView - 表示中のrecommendedCircles数: \(circleManager.recommendedCircles.count)")
                for (index, rec) in circleManager.recommendedCircles.enumerated() {
                    print("   [\(index)]: ID='\(rec.circle.id)', Name='\(rec.circle.name)'")
                }
            }
        }
    }
}

// MARK: - Recommended Circle Row View
struct RecommendedCircleRowView: View {
    let recommendation: CircleRecommendation
    
    var body: some View {
        HStack {
            // サークルアイコン
            AsyncImage(url: URL(string: recommendation.circle.iconUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.3")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(recommendation.circle.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // レコメンデーションスコア
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", recommendation.recommendationScore))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(recommendation.circle.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // レコメンド理由
                Text(recommendation.recommendationReason)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .lineLimit(1)
                
                HStack {
                    Label("\(recommendation.circle.memberCount)人", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // ステータスバッジ
                    Text(recommendation.circle.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(recommendation.circle.status.color))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Circle Row View
struct CircleRowView: View {
    let circle: KnestCircle
    var showMembershipInfo = false
    var showRecommendReason = false
    
    var body: some View {
        HStack {
            // サークルアイコン
            AsyncImage(url: URL(string: circle.iconUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.3")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(circle.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    // ステータスバッジ
                    Text(circle.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(circle.status.color))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                
                Text(circle.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(circle.memberCount)人", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !circle.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(circle.tags.prefix(2), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            
                            if circle.tags.count > 2 {
                                Text("+\(circle.tags.count - 2)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Circle Search Bar
struct CircleSearchBar: View {
    @Binding var text: String
    var onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            TextField("サークルを検索...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            Button("検索", action: onSearchButtonClicked)
                .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Next Gen Recommendation Row View
struct NextGenRecommendationRowView: View {
    let recommendation: NextGenRecommendation
    let onDismiss: () -> Void
    let onNotInterested: () -> Void
    @State private var showingReasons = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // サークル基本情報
                HStack {
                    AsyncImage(url: URL(string: recommendation.circle.iconUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Image(systemName: "person.3")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recommendation.circle.name)
                            .font(.headline)
                            .lineLimit(1)
                        
                        Text(recommendation.circle.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // スコアと信頼度
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text(String(format: "%.1f", recommendation.score))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Text("信頼度: \(Int(recommendation.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // 推薦理由（最大2つ表示）
            if !recommendation.reasons.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(recommendation.reasons.prefix(2).enumerated()), id: \.offset) { index, reason in
                        HStack {
                            Image(systemName: reasonIcon(for: reason.type))
                                .foregroundColor(.blue)
                                .font(.caption)
                                .frame(width: 12)
                            
                            Text(reason.detail)
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Text(String(format: "%.0f%%", reason.weight * 100))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if recommendation.reasons.count > 2 {
                        Button("理由をすべて表示") {
                            showingReasons = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // アクションボタン
            HStack {
                Label("\(recommendation.circle.memberCount)人", systemImage: "person.2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(recommendation.circle.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(recommendation.circle.status.color))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                
                Spacer()
                
                Button(action: onNotInterested) {
                    Image(systemName: "hand.thumbsdown")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingReasons) {
            RecommendationReasonsView(reasons: recommendation.reasons)
        }
    }
    
    private func reasonIcon(for type: String) -> String {
        switch type {
        case "interest_match": return "heart"
        case "similar_users": return "person.2"
        case "activity_pattern": return "clock"
        default: return "star"
        }
    }
}

// MARK: - Recommendation Reasons View
struct RecommendationReasonsView: View {
    let reasons: [RecommendationReason]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(reasons, id: \.type) { reason in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(reason.detail)
                            .font(.body)
                        
                        Spacer()
                        
                        Text(String(format: "%.0f%%", reason.weight * 100))
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    Text(reasonDescription(for: reason.type))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("推薦理由")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func reasonDescription(for type: String) -> String {
        switch type {
        case "interest_match": return "あなたの登録した興味・関心との一致度"
        case "similar_users": return "似た興味を持つユーザーの参加状況"
        case "activity_pattern": return "過去の活動パターンとの類似性"
        default: return "その他の要因"
        }
    }
}

// MARK: - Recommendation Settings View
struct RecommendationSettingsView: View {
    @ObservedObject var circleManager: CircleManager
    @ObservedObject var recommendationManager: RecommendationManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("推薦アルゴリズム") {
                    Picker("アルゴリズム", selection: $recommendationManager.selectedAlgorithm) {
                        Text("スマート推薦").tag("smart")
                        Text("興味関心ベース").tag("content")
                        Text("類似ユーザーベース").tag("collaborative")
                        Text("行動ベース").tag("behavioral")
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section("推薦設定") {
                    HStack {
                        Text("表示件数")
                        Spacer()
                        Stepper("\(recommendationManager.recommendationLimit)", value: $recommendationManager.recommendationLimit, in: 5...30, step: 5)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("多様性")
                        HStack {
                            Text("類似性重視")
                                .font(.caption)
                            Slider(value: $recommendationManager.diversityFactor, in: 0...1, step: 0.1)
                            Text("多様性重視")
                                .font(.caption)
                        }
                        Text("現在の値: \(String(format: "%.1f", recommendationManager.diversityFactor))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("学習データ") {
                    if let preferences = recommendationManager.userPreferences {
                        UserPreferencesView(preferences: preferences)
                    } else {
                        Button("学習データを読み込む") {
                            recommendationManager.loadUserPreferences()
                        }
                    }
                }
            }
            .navigationTitle("推薦設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("適用") {
                        recommendationManager.loadRecommendations()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - User Preferences View
struct UserPreferencesView: View {
    let preferences: UserPreferences
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ユーザープロファイル")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("タイプ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if preferences.userProfile.isNewUser {
                        Label("新規ユーザー", systemImage: "person.badge.plus")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else if preferences.userProfile.isActiveUser {
                        Label("アクティブユーザー", systemImage: "person.fill.checkmark")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else {
                        Label("一般ユーザー", systemImage: "person")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("活動")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(preferences.userProfile.recentActivity)回")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            Text("推薦アルゴリズム重み")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.top)
            
            VStack(spacing: 4) {
                AlgorithmWeightRow(name: "階層マッチング", weight: preferences.algorithmWeights.hierarchical)
                AlgorithmWeightRow(name: "協調フィルタリング", weight: preferences.algorithmWeights.collaborative)
                AlgorithmWeightRow(name: "行動ベース", weight: preferences.algorithmWeights.behavioral)
                AlgorithmWeightRow(name: "多様性保証", weight: preferences.algorithmWeights.diversity)
            }
        }
        .padding(.vertical, 8)
    }
}

struct AlgorithmWeightRow: View {
    let name: String
    let weight: Double
    
    var body: some View {
        HStack {
            Text(name)
                .font(.caption)
            
            Spacer()
            
            ProgressView(value: weight, total: 1.0)
                .frame(width: 60)
            
            Text(String(format: "%.0f%%", weight * 100))
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 30)
        }
    }
}

// MARK: - Empty Recommendation View
struct EmptyRecommendationView: View {
    @State private var showingInterestSelection = false
    @State private var showingHierarchicalInterestSelection = false
    
    var body: some View {
        VStack(spacing: 20) {
            // アイコン（グラデーション効果）
            ZStack {
                SwiftUI.Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("あなた専用のおすすめを準備中！")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("興味関心を設定すると、AIがあなたに\nぴったりのサークルを見つけます")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            
            VStack(spacing: 12) {
                // 階層的興味関心設定ボタン
                Button {
                    showingHierarchicalInterestSelection = true
                } label: {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("詳細な興味関心を設定")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("3階層システムで精密なマッチング")
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // 基本興味関心設定ボタン
                Button {
                    showingInterestSelection = true
                } label: {
                    HStack {
                        Image(systemName: "heart.circle")
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("基本的な興味関心を設定")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("かんたん設定でスタート")
                                .font(.caption)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal)
            
            // 補足説明
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("設定後すぐにおすすめが表示されます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("プライバシーは完全に保護されます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 8)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingInterestSelection) {
            InterestSelectionView()
        }
        .sheet(isPresented: $showingHierarchicalInterestSelection) {
            HierarchicalInterestSelectionView()
        }
    }
}

#Preview {
    CirclesView()
} 