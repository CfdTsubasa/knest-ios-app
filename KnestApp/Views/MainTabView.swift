//
//  MainTabView.swift
//  KnestApp
//
//  Created by t.i on 2025/06/07.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // ホーム
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("ホーム")
                }
                .tag(0)
            
            // 検索 (新機能)
            SearchView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("検索")
                }
                .tag(1)
            
            // サークル - 一時的に非表示
            /*
            CirclesView()
                .tabItem {
                    Image(systemName: "person.3.fill")
                    Text("サークル")
                }
                .tag(2)
            */
            
            // 参加中サークル
            MyCirclesTabView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("参加中")
                }
                .tag(2)
            
            // プロフィール
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("プロフィール")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

struct HomeView: View {
    @Binding var selectedTab: Int
    @StateObject private var interestManager = InterestManager()
    @StateObject private var hierarchicalInterestManager = HierarchicalInterestManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "network")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Knestへようこそ！")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("興味関心を共有し、新しいつながりを見つけよう")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // 興味関心未設定時の特別なキャプション
                if interestManager.userInterests.isEmpty && hierarchicalInterestManager.userProfiles.isEmpty {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            
                            Text("まず興味関心を設定しませんか？")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                        
                        Text("あなたの興味関心を設定すると、AIがぴったりのサークルとメンバーを見つけます")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                }
                
                VStack(spacing: 12) {
                    NavigationLink(destination: SearchView(selectedTab: $selectedTab)) {
                        FeatureCardView(
                            icon: "magnifyingglass",
                            title: "スマート検索",
                            description: "興味関心マッチング、おすすめ、サークル作成",
                            color: .purple
                        )
                    }
                    
                    NavigationLink(destination: HierarchicalInterestSelectionView()) {
                        FeatureCardView(
                            icon: "heart.text.square",
                            title: "興味関心を設定",
                            description: "3階層システムで詳細な興味関心を登録",
                            color: .orange
                        )
                    }
                    
                    NavigationLink(destination: CirclesView()) {
                        FeatureCardView(
                            icon: "person.3.fill",
                            title: "サークルを探す",
                            description: "興味の合うサークルに参加しよう",
                            color: .blue
                        )
                    }
                    
                    NavigationLink(destination: HashtagSelectionView()) {
                        FeatureCardView(
                            icon: "number",
                            title: "ハッシュタグ登録",
                            description: "あなたの興味をハッシュタグで表現しよう",
                            color: .green
                        )
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            .padding()
            .navigationTitle("ホーム")
        }
        .onAppear {
            interestManager.loadUserInterests()
            hierarchicalInterestManager.loadUserProfiles()
        }
    }
}

struct FeatureCardView: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.1))
                .clipShape(SwiftUI.Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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

// MARK: - My Circles Tab View
struct MyCirclesTabView: View {
    @ObservedObject private var circleManager = CircleManager.shared
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            VStack {
                if circleManager.myCircles.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "person.2")
                            .font(.system(size: 80))
                            .foregroundColor(.gray)
                        
                        Text("参加中のサークルがありません")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("サークルに参加して、新しい仲間と\nつながりを作りましょう")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        NavigationLink(destination: CirclesView()) {
                            Text("サークルを探す")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 32)
                        }
                    }
                    .padding()
                    Spacer()
                } else {
                    List(circleManager.myCircles) { circle in
                        NavigationLink(destination: CircleChatView(circle: circle, circleManager: circleManager, selectedTab: $selectedTab)) {
                            MyCircleRowView(circle: circle)
                        }
                    }
                }
            }
            .navigationTitle("参加中のサークル")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    NavigationLink(destination: CirclesView()) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear {
                circleManager.loadMyCircles()
            }
            .refreshable {
                circleManager.loadMyCircles()
            }
        }
    }
}

// MARK: - My Circle Row View (Copy from CirclesView)
struct MyCircleRowView: View {
    let circle: KnestCircle
    
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
                }
                
                Text(circle.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("\(circle.memberCount)人", systemImage: "person.2")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // 最終活動時間
                    if let lastActivity = circle.lastActivityAt {
                        Text("最終活動: \(formatDate(lastActivity))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 未読通知（今後実装予定）
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(0) // 現在は非表示
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        // 簡易的な日付フォーマット（実際のアプリでは適切な日付パーサーを使用）
        return "今日" // プレースホルダー
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthenticationManager.shared)
} 