//
//  CircleDetailView.swift
//  KnestApp
//
//  Created by t.i on 2025/06/07.
//

import SwiftUI

struct CircleDetailView: View {
    let circle: KnestCircle
    @StateObject private var circleManager = CircleManager()
    @State private var selectedTab = 0
    @State private var showingJoinDialog = false
    @State private var applicationMessage = ""
    
    private let tabs = ["概要", "チャット", "イベント", "メンバー"]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // ヘッダー画像
                AsyncImage(url: URL(string: circle.coverUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .overlay(
                            Image(systemName: "person.3")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        )
                }
                .frame(height: 200)
                .clipped()
                
                VStack(alignment: .leading, spacing: 16) {
                    // サークル基本情報
                    CircleHeaderView(circle: circle)
                    
                    // 参加ボタン
                    JoinButtonView(circle: circle, showingJoinDialog: $showingJoinDialog)
                    
                    // タブ
                    TabSelectionView(selectedTab: $selectedTab, tabs: tabs)
                    
                    // コンテンツ
                    TabContentView(
                        circle: circle,
                        selectedTab: selectedTab,
                        circleManager: circleManager
                    )
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingJoinDialog) {
            JoinCircleSheet(
                circle: circle,
                applicationMessage: $applicationMessage,
                onJoin: {
                    circleManager.joinCircle(circleId: circle.id, message: applicationMessage.isEmpty ? nil : applicationMessage)
                    showingJoinDialog = false
                }
            )
        }
        .onAppear {
            circleManager.loadCircleDetail(circleId: circle.id)
            if selectedTab == 1 {
                circleManager.loadCircleChats(circleId: circle.id)
            }
        }
    }
}

// MARK: - Circle Header View
struct CircleHeaderView: View {
    let circle: KnestCircle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // サークルアイコン
                AsyncImage(url: URL(string: circle.iconUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.3")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(circle.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text(circle.status.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color(circle.status.color))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        
                        Text(circle.circleType.displayName)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
            
            // 統計情報
            HStack(spacing: 20) {
                StatView(title: "メンバー", value: "\(circle.memberCount)人")
                StatView(title: "投稿", value: "\(circle.postCount)")
                
                if let memberLimit = circle.memberLimit {
                    StatView(title: "定員", value: "\(memberLimit)人")
                }
                
                Spacer()
            }
            
            // 説明
            Text(circle.description)
                .font(.body)
                .foregroundColor(.primary)
            
            // タグ
            if !circle.tags.isEmpty {
                TagsView(tags: circle.tags)
            }
            
            // 興味
            if !circle.interests.isEmpty {
                CircleInterestsView(interests: circle.interests)
            }
        }
    }
}

// MARK: - Join Button View
struct JoinButtonView: View {
    let circle: KnestCircle
    @Binding var showingJoinDialog: Bool
    
    var body: some View {
        HStack {
            Spacer()
            
            Button {
                showingJoinDialog = true
            } label: {
                HStack {
                    Image(systemName: "person.badge.plus")
                    Text("参加する")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(
                    circle.status == .open ? Color.blue : Color.gray
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(circle.status != .open)
            
            Spacer()
        }
    }
}

// MARK: - Tab Selection View
struct TabSelectionView: View {
    @Binding var selectedTab: Int
    let tabs: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    Button {
                        selectedTab = index
                    } label: {
                        VStack(spacing: 4) {
                            Text(tab)
                                .font(.headline)
                                .foregroundColor(selectedTab == index ? .blue : .secondary)
                            
                            Rectangle()
                                .fill(selectedTab == index ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Tab Content View
struct TabContentView: View {
    let circle: KnestCircle
    let selectedTab: Int
    @ObservedObject var circleManager: CircleManager
    
    var body: some View {
        switch selectedTab {
        case 0:
            CircleOverviewView(circle: circle)
        case 1:
            CircleChatTabView(circle: circle)
        case 2:
            CircleEventsView(circle: circle)
        case 3:
            CircleMembersView(circle: circle)
        default:
            EmptyView()
        }
    }
}

// MARK: - Supporting Views
struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct TagsView: View {
    let tags: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CircleInterestsView: View {
    let interests: [Interest]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("関連する興味")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(interests) { interest in
                        Text(interest.name)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Content Views (Placeholder)
struct CircleOverviewView: View {
    let circle: KnestCircle
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let rules = circle.rules, !rules.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("サークル規約")
                        .font(.headline)
                    Text(rules)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("詳細情報")
                .font(.headline)
            
            Text("このサークルの詳細情報がここに表示されます。")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct CircleChatTabView: View {
    let circle: KnestCircle
    
    var body: some View {
        // 新しいリッチなチャット画面を使用
        CircleChatView(circle: circle)
    }
}

struct CircleEventsView: View {
    let circle: KnestCircle
    
    var body: some View {
        VStack {
            Text("イベント機能（実装予定）")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding()
        }
    }
}

struct CircleMembersView: View {
    let circle: KnestCircle
    
    var body: some View {
        VStack {
            Text("メンバー一覧（実装予定）")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding()
        }
    }
}

// MARK: - Join Circle Sheet
struct JoinCircleSheet: View {
    let circle: KnestCircle
    @Binding var applicationMessage: String
    let onJoin: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("「\(circle.name)」に参加申請")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if circle.circleType == .approval {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("申請メッセージ")
                            .font(.headline)
                        
                        Text("このサークルは承認制です。参加理由や自己紹介を記入してください。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("申請メッセージを入力...", text: $applicationMessage, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                }
                
                Spacer()
                
                Button {
                    onJoin()
                } label: {
                    Text("参加申請を送信")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
            .navigationTitle("参加申請")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CircleDetailView(circle: KnestCircle.sample())
} 
