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
                    NavigationLink(destination: CircleDetailView(circle: circle)) {
                        CircleRowView(circle: circle)
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
                    NavigationLink(destination: CircleDetailView(circle: circle)) {
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
    
    var body: some View {
        VStack {
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
                    NavigationLink(destination: CircleDetailView(circle: recommendation.circle)) {
                        RecommendedCircleRowView(recommendation: recommendation)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

#Preview {
    CirclesView()
} 