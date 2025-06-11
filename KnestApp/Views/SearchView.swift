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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // モード選択セグメント
                ModeSelector(selectedMode: $selectedMode)
                    .padding()
                
                // 選択されたモードの内容
                switch selectedMode {
                case .active:
                    ActiveSearchView(searchText: $searchText, showingFilters: $showingFilters)
                case .passive:
                    PassiveRecommendationView()
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
        .background(Color(UIColor.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - 能動検索（Active Search）

struct ActiveSearchView: View {
    @EnvironmentObject var matchingManager: MatchingManager
    @Binding var searchText: String
    @Binding var showingFilters: Bool
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
                    .background(Color(UIColor.systemGray6))
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
                    NavigationLink(destination: CircleDetailView(circle: match.circle)) {
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
        let filters = selectedFilters.toDictionary()
        matchingManager.searchCircles(query: searchText, filters: filters)
    }
    
    private func loadPopularCircles() {
        matchingManager.searchCircles(query: "", filters: ["sort": "popular"])
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
        .background(Color(UIColor.systemGray6))
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
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // ヘッダー
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
                
                if matchingManager.isLoading {
                    ProgressView("おすすめを計算中...")
                        .frame(height: 200)
                } else if matchingManager.recommendedCircles.isEmpty {
                    EmptyRecommendationView()
                } else {
                    ForEach(matchingManager.recommendedCircles) { match in
                        NavigationLink(destination: CircleDetailView(circle: match.circle)) {
                            RecommendationCard(match: match)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            matchingManager.loadRecommendedCircles()
        }
        .refreshable {
            matchingManager.loadRecommendedCircles()
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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ヘッダー
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("サークルを作ってみませんか？")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("あなたと似た興味を持つ人たちが\nサークルを待っています")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // 類似ユーザー統計
                if !matchingManager.userMatches.isEmpty {
                    SimilarUsersCard(matches: matchingManager.userMatches)
                }
                
                // 作成提案カード
                CreateCircleSuggestionCard {
                    showingCreateCircle = true
                }
                
                // 類似ユーザー一覧
                if !matchingManager.userMatches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("あなたと似た人たち")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(matchingManager.userMatches.prefix(5)) { match in
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
            VStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("新しいサークルを作成")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("あなたの興味に合った\nサークルを立ち上げて\n仲間を集めましょう")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Text("サークル作成")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
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
        .background(Color(UIColor.systemGray6))
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

struct EmptyRecommendationView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("おすすめを準備中")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("興味関心を登録すると\nぴったりのサークルをおすすめします")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: HierarchicalInterestSelectionView()) {
                Text("興味関心を登録")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(height: 300)
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
            .navigationBarTitleDisplayMode(.inline)
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
    SearchView()
        .environmentObject(MatchingManager())
} 