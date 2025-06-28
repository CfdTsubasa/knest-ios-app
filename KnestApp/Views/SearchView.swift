//
//  SearchView.swift
//  KnestApp
//
//  Created by Claude on 2025/06/08.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var matchingManager = MatchingManager()
    @State private var selectedMode: SearchMode = .passive
    @State private var searchText = ""
    @State private var showingFilters = false
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // モード選択セグメント
                ModeSelector(selectedMode: $selectedMode)
                    .padding()
                
                // 選択されたモードの内容
                switch selectedMode {
                case .active:
                    ActiveSearchView(searchText: $searchText, showingFilters: $showingFilters, selectedTab: $selectedTab)
                case .passive:
                    PassiveRecommendationView(selectedTab: $selectedTab)
                case .creation:
                    CreationSuggestionView()
                }
            }
            .navigationTitle("発見")
            .toolbar {
                if selectedMode == .active {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("フィルター") {
                            showingFilters = true
                        }
                    }
                }
            }
        }
        .environmentObject(matchingManager)
    }
}

// MARK: - モード選択

struct ModeSelector: View {
    @Binding var selectedMode: SearchMode
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(SearchMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedMode = mode
                    }
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 20, weight: .medium))
                        
                        Text(mode.title)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(selectedMode == mode ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedMode == mode ? Color.blue : Color.clear)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 能動検索（Active Search）

struct ActiveSearchView: View {
    @EnvironmentObject var matchingManager: MatchingManager
    @Binding var searchText: String
    @Binding var showingFilters: Bool
    @Binding var selectedTab: Int
    @State private var sortOption: SortOption = .popular
    @State private var selectedFilters: SearchFilters = SearchFilters()
    
    enum SortOption: String, CaseIterable {
        case popular = "人気順"
        case recent = "最近アクティブ"
        case newest = "新しい順"
        case memberCount = "メンバー数順"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // 検索バー
            SearchBar(text: $searchText, placeholder: "サークル名やタグで検索...")
                .onSubmit {
                    performSearch()
                }
            
            // ソート・フィルターバー
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // ソートピッカー
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(option.rawValue) {
                                sortOption = option
                                performSearch()
                            }
                        }
                    } label: {
                        HStack {
                            Text(sortOption.rawValue)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                    }
                    
                    // フィルタータグ
                    if selectedFilters.hasActiveFilters {
                        ForEach(selectedFilters.activeFilterTags, id: \.self) { tag in
                            FilterTag(text: tag) {
                                selectedFilters.removeFilter(tag)
                                performSearch()
                            }
                        }
                    }
                    
                    // フィルター追加ボタン
                    Button("フィルター追加") {
                        showingFilters = true
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .clipShape(Capsule())
                }
                .padding(.horizontal)
            }
            
            // 検索結果
            if matchingManager.isLoading {
                ProgressView("検索中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if matchingManager.circleMatches.isEmpty {
                EmptySearchResultView()
            } else {
                List(matchingManager.circleMatches) { match in
                    NavigationLink(destination: CircleDetailView(circle: match.circle, selectedTab: $selectedTab)) {
                        ActiveSearchResultRow(match: match)
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .sheet(isPresented: $showingFilters) {
            SearchFiltersView(filters: $selectedFilters) {
                performSearch()
            }
        }
        .onAppear {
            if searchText.isEmpty {
                loadPopularCircles()
            }
        }
    }
    
    private func performSearch() {
        var filters = selectedFilters.toDictionary()
        
        // ソートオプションをorderingパラメータに変換
        switch sortOption {
        case .popular:
            filters["ordering"] = "-member_count"
        case .recent:
            filters["ordering"] = "-last_activity"
        case .newest:
            filters["ordering"] = "-created_at"
        case .memberCount:
            filters["ordering"] = "-member_count"
        }
        
        matchingManager.searchCircles(query: searchText, filters: filters)
    }
    
    private func loadPopularCircles() {
        matchingManager.searchCircles(query: "", filters: ["ordering": "-member_count"])
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
    }
}

struct ActiveSearchResultRow: View {
    let match: CircleMatch
    
    var body: some View {
        HStack(spacing: 12) {
            // サークルアイコン
            AsyncImage(url: URL(string: match.circle.iconUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                SwiftUI.Circle()
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.blue)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(SwiftUI.Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(match.circle.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(match.circle.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(match.memberCount)人", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(match.circle.status == .open ? "募集中" : "募集停止")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(match.circle.status == .open ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                        .foregroundColor(match.circle.status == .open ? .green : .gray)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 受動おすすめ（Passive Recommendation）

struct PassiveRecommendationView: View {
    @EnvironmentObject var matchingManager: MatchingManager
    @Binding var selectedTab: Int
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // ヘッダー（おすすめサークルがある場合のみ表示）
                if !matchingManager.isLoading && !matchingManager.recommendedCircles.isEmpty {
                    VStack(spacing: 8) {
                        Text("あなたにおすすめ")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("興味関心・年齢・居住地から\nぴったりのサークルを見つけました")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                
                if matchingManager.isLoading {
                    ProgressView("おすすめを計算中...")
                        .frame(height: 200)
                } else if matchingManager.recommendedCircles.isEmpty {
                    EmptyRecommendationView()
                } else {
                    ForEach(matchingManager.recommendedCircles) { match in
                        NavigationLink(destination: CircleDetailView(circle: match.circle, selectedTab: $selectedTab)) {
                            RecommendationCard(match: match)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            matchingManager.getRecommendedCircles()
        }
        .refreshable {
            matchingManager.getRecommendedCircles()
        }
    }
}

struct RecommendationCard: View {
    let match: CircleMatch
    
    var body: some View {
        VStack(spacing: 16) {
            // マッチ度とサークル基本情報
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("マッチ度")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(match.score.totalScore * 100))%")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    ProgressView(value: match.score.totalScore, total: 1.0)
                        .tint(.green)
                }
                
                Spacer()
                
                AsyncImage(url: URL(string: match.circle.iconUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    SwiftUI.Circle()
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.blue)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(SwiftUI.Circle())
            }
            
            // サークル名と説明
            VStack(alignment: .leading, spacing: 8) {
                Text(match.circle.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(match.circle.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
            
            // 共通点ハイライト
            if !match.score.commonInterests.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                        Text("\(match.score.commonInterests.count)個の共通点!")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(match.score.commonInterests.prefix(4), id: \.self) { interest in
                            Text(interest)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.pink.opacity(0.1))
                                .foregroundColor(.pink)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // マッチング理由
            Text(match.matchReason)
                .font(.caption)
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - 自己創出（Creation Suggestion）

struct CreationSuggestionView: View {
    @EnvironmentObject var matchingManager: MatchingManager
    @State private var showingCreateCircle = false
    
    // 70%以上の類似度を持つユーザー
    var highMatchUsers: [UserMatch] {
        matchingManager.userMatches.filter { $0.score.totalScore >= 0.7 }
    }
    
    // その他のユーザー
    var otherUsers: [UserMatch] {
        matchingManager.userMatches.filter { $0.score.totalScore < 0.7 }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ヘッダー（電球アイコン削除、「あなたと似た〜」文言削除）
                VStack(spacing: 12) {
                    Text("サークルを作ってみませんか？")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding()
                
                // 類似ユーザー統計（70%以上のユーザー数を表示）
                if !matchingManager.userMatches.isEmpty {
                    SimilarUsersCard(matches: matchingManager.userMatches)
                }
                
                // 70%以上の類似度ユーザーセクション
                if !highMatchUsers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("高い類似度のユーザー（70%以上）")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(highMatchUsers) { match in
                            HighSimilarityUserRow(match: match)
                        }
                    }
                }
                
                // 作成提案カード
                CreateCircleSuggestionCard {
                    showingCreateCircle = true
                }
                
                // その他のユーザー一覧
                if !otherUsers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("その他のユーザー")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(otherUsers.prefix(5)) { match in
                            SimilarUserRow(match: match)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            matchingManager.findMatchingUsers()
        }
        .sheet(isPresented: $showingCreateCircle) {
            CreateCircleView()
        }
    }
}

// MARK: - 高い類似度ユーザー専用行
struct HighSimilarityUserRow: View {
    let match: UserMatch
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: match.user.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                SwiftUI.Circle()
                    .fill(Color.orange.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.orange)
                    )
            }
            .frame(width: 50, height: 50)
            .clipShape(SwiftUI.Circle())
            .overlay(
                SwiftUI.Circle()
                    .stroke(Color.orange, lineWidth: 2)
            )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(match.user.displayName ?? match.user.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(Int(match.score.totalScore * 100))%")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                if !match.score.commonInterests.isEmpty {
                    Text("共通: \(match.score.commonInterests.prefix(3).joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Image(systemName: "star.fill")
                .font(.title3)
                .foregroundColor(.orange)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.1), Color.yellow.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SimilarUsersCard: View {
    let matches: [UserMatch]
    
    var highMatchCount: Int {
        matches.filter { $0.score.totalScore > 0.7 }.count
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(highMatchCount)人")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("あなたと70%以上類似")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
            }
            
            Text("これだけ似た人がいれば、きっと素敵なサークルができるはず！")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct CreateCircleSuggestionCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // アイコン部分
                ZStack {
                    SwiftUI.Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.8), .purple.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // テキスト部分
                VStack(alignment: .leading, spacing: 4) {
                    Text("新しいサークルを作成")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("興味に合った仲間を集めよう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // 矢印アイコン
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue.opacity(0.3), .purple.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .shadow(color: Color.blue.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
}

struct SimilarUserRow: View {
    let match: UserMatch
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: match.user.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                SwiftUI.Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(SwiftUI.Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(match.user.displayName ?? match.user.username)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(Int(match.score.totalScore * 100))% 類似")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                if !match.score.commonInterests.isEmpty {
                    Text("共通: \(match.score.commonInterests.prefix(2).joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - サポート構造体

struct SearchFilters {
    var category: String?
    var minMembers: Int?
    var maxMembers: Int?
    var status: String?
    var prefecture: String?
    var ageRange: ClosedRange<Int>?
    
    var hasActiveFilters: Bool {
        return category != nil || minMembers != nil || maxMembers != nil || 
               status != nil || prefecture != nil || ageRange != nil
    }
    
    var activeFilterTags: [String] {
        var tags: [String] = []
        if let category = category { tags.append("カテゴリ: \(category)") }
        if let minMembers = minMembers { tags.append("最小: \(minMembers)人") }
        if let maxMembers = maxMembers { tags.append("最大: \(maxMembers)人") }
        if let status = status { tags.append("状態: \(status)") }
        if let prefecture = prefecture { tags.append("地域: \(prefecture)") }
        if let ageRange = ageRange { tags.append("年齢: \(ageRange.lowerBound)-\(ageRange.upperBound)") }
        return tags
    }
    
    mutating func removeFilter(_ tag: String) {
        if tag.hasPrefix("カテゴリ:") { category = nil }
        else if tag.hasPrefix("最小:") { minMembers = nil }
        else if tag.hasPrefix("最大:") { maxMembers = nil }
        else if tag.hasPrefix("状態:") { status = nil }
        else if tag.hasPrefix("地域:") { prefecture = nil }
        else if tag.hasPrefix("年齢:") { ageRange = nil }
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        if let category = category { dict["category"] = category }
        if let minMembers = minMembers { dict["min_members"] = minMembers }
        if let maxMembers = maxMembers { dict["max_members"] = maxMembers }
        if let status = status { dict["status"] = status }
        if let prefecture = prefecture { dict["prefecture"] = prefecture }
        if let ageRange = ageRange { 
            dict["min_age"] = ageRange.lowerBound
            dict["max_age"] = ageRange.upperBound
        }
        return dict
    }
}

struct FilterTag: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .clipShape(Capsule())
    }
}

// MARK: - 空状態View

struct EmptySearchResultView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("検索結果が見つかりませんでした")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("検索条件を変更して\n再度お試しください")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - フィルター設定画面

struct SearchFiltersView: View {
    @Binding var filters: SearchFilters
    let onApply: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section("カテゴリ") {
                    Picker("カテゴリ選択", selection: $filters.category) {
                        Text("すべて").tag(String?.none)
                        Text("🎮 ゲーム").tag(String?.some("gaming"))
                        Text("📚 学習・知識").tag(String?.some("learning"))
                        Text("🎨 クリエイティブ").tag(String?.some("creative"))
                        Text("🏃‍♂️ スポーツ").tag(String?.some("sports"))
                        Text("🍳 料理・グルメ").tag(String?.some("food"))
                    }
                }
                
                Section("メンバー数") {
                    HStack {
                        TextField("最小", value: $filters.minMembers, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("〜")
                        TextField("最大", value: $filters.maxMembers, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Text("人")
                    }
                }
                
                Section("状態") {
                    Picker("募集状態", selection: $filters.status) {
                        Text("すべて").tag(String?.none)
                        Text("募集中").tag(String?.some("open"))
                        Text("募集停止").tag(String?.some("closed"))
                    }
                }
            }
            .navigationTitle("検索フィルター")
            
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("適用") {
                        onApply()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SearchView(selectedTab: .constant(0))
        .environmentObject(MatchingManager())
} 