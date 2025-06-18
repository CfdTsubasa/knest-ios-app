//
//  CircleDetailView.swift
//  KnestApp
//
//  Created by t.i on 2025/06/07.
//

import SwiftUI

struct CircleDetailView: View {
    let circle: KnestCircle
    @StateObject private var circleManager = CircleManager.shared
    @State private var showingJoinSheet = false
    @State private var joinMessage = ""
    @State private var showingJoinSuccess = false
    @State private var navigateToChat = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @ObservedObject private var recommendationManager = RecommendationManager.shared
    @State private var showingJoinDialog = false
    @State private var applicationMessage = ""
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss
    
    private let tabs = ["概要", "チャット", "イベント", "メンバー"]
    
    // 現在のサークル情報を取得（更新された詳細があればそれを使用、なければ初期値を使用）
    private var currentCircle: KnestCircle {
        return circleManager.circleDetail ?? circle
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // ヘッダー画像と戻るボタン
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: URL(string: currentCircle.coverUrl ?? "")) { image in
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
                    
                    // 検索画面に戻るボタン
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("検索に戻る")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Capsule())
                    }
                    .padding(.top, 12)
                    .padding(.leading, 16)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    // サークル基本情報
                    CircleHeaderView(circle: currentCircle)
                    
                    // 参加ボタン
                    JoinButtonView(
                        circle: currentCircle,
                        showingJoinDialog: $showingJoinDialog,
                        onJoinRequest: {
                            // 参加申請のフィードバックを送信
                            recommendationManager.trackJoinRequest(for: currentCircle)
                        },
                        onJoinSuccess: {
                            // 参加成功のフィードバックを送信
                            recommendationManager.trackJoinSuccess(for: currentCircle)
                            // サークル詳細を再読み込み
                            refreshCircleDetail()
                        },
                        selectedTab: $selectedTab
                    )
                    
                    // タブ
                    TabSelectionView(selectedTab: $selectedTab, tabs: tabs)
                    
                    // コンテンツ
                    TabContentView(
                        circle: currentCircle,
                        selectedTab: selectedTab,
                        circleManager: circleManager,
                        mainSelectedTab: $selectedTab
                    )
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingJoinDialog) {
            JoinCircleSheet(
                circle: currentCircle,
                applicationMessage: $applicationMessage,
                onJoin: {
                    circleManager.joinCircle(circleId: currentCircle.id, message: applicationMessage.isEmpty ? nil : applicationMessage)
                    showingJoinDialog = false
                    
                    // 参加申請完了のフィードバックを送信
                    recommendationManager.trackJoinRequest(for: currentCircle)
                },
                onSuccess: {
                    // 参加成功のフィードバックを送信
                    recommendationManager.trackJoinSuccess(for: currentCircle)
                    // サークル詳細を再読み込み
                    refreshCircleDetail()
                }
            )
        }
        .onAppear {
            print("[INFO] CircleDetailView表示: ID='\(currentCircle.id)', Name='\(currentCircle.name)'")
            refreshCircleDetail()
            if selectedTab == 1 {
                circleManager.loadCircleChats(circleId: currentCircle.id)
            }
            
            // サークル詳細表示のフィードバックを送信
            recommendationManager.trackCircleView(for: currentCircle)
        }
    }
    
    private func refreshCircleDetail() {
        circleManager.loadCircleDetail(circleId: circle.id)
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
    let onJoinRequest: () -> Void
    let onJoinSuccess: (() -> Void)?
    @StateObject private var circleManager = CircleManager()
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var showingChatView = false
    @State private var showingLimitAlert = false
    @State private var errorMessage = ""
    @Binding var selectedTab: Int
    
    init(circle: KnestCircle, showingJoinDialog: Binding<Bool>, onJoinRequest: @escaping () -> Void, onJoinSuccess: (() -> Void)? = nil, selectedTab: Binding<Int>) {
        self.circle = circle
        self._showingJoinDialog = showingJoinDialog
        self.onJoinRequest = onJoinRequest
        self.onJoinSuccess = onJoinSuccess
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        HStack {
            Spacer()
            
            if circle.isMember {
                // 既に参加済みの場合：チャットボタンを表示
                Button {
                    // 「参加中」タブに切り替え
                    selectedTab = 3
                    showingChatView = true
                } label: {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("チャットを見る")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                // 未参加の場合：参加ボタンを表示
                Button {
                    onJoinRequest()
                    
                    // サークルタイプに応じて処理を分岐
                    if circle.circleType == .public && circle.status == .open {
                        // 公開サークルは即座に参加
                        joinDirectly()
                    } else if circle.circleType == .approval {
                        // 承認制サークルは申請シート表示
                        showingJoinDialog = true
                    } else {
                        // その他（プライベートなど）はエラー
                        showingErrorAlert = true
                    }
                } label: {
                    HStack {
                        if circleManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "person.badge.plus")
                        }
                        Text(buttonText)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(buttonColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!isJoinable || circleManager.isLoading)
            }
            
            Spacer()
        }
        .alert("参加完了", isPresented: $showingSuccessAlert) {
            Button("チャットを見る") {
                // 「参加中」タブに切り替え
                selectedTab = 3
                showingChatView = true
            }
            Button("OK") { }
        } message: {
            Text("サークルに参加しました！チャット画面で他のメンバーと交流しましょう。")
        }
        .alert("エラー", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage.isEmpty ? "参加できませんでした" : errorMessage)
        }
        .sheet(isPresented: $showingChatView) {
            NavigationView {
                CircleChatView(circle: circle, selectedTab: $selectedTab)
                    .navigationTitle("\(circle.name)のチャット")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("閉じる") {
                                showingChatView = false
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showingLimitAlert) {
            CircleLimitAlertView(isPresented: $showingLimitAlert)
        }
    }
    
    private var buttonText: String {
        switch circle.circleType {
        case .public:
            return circle.status == .open ? "参加する" : "参加不可"
        case .approval:
            return "参加申請"
        case .private:
            return "招待制"
        }
    }
    
    private var buttonColor: Color {
        if !isJoinable {
            return .gray
        }
        
        switch circle.circleType {
        case .public:
            return circle.status == .open ? .blue : .gray
        case .approval:
            return .orange
        case .private:
            return .gray
        }
    }
    
    private var isJoinable: Bool {
        switch circle.circleType {
        case .public:
            return circle.status == .open
        case .approval:
            return circle.status == .open
        case .private:
            return false
        }
    }
    
    private func joinDirectly() {
        print("[DEBUG] 参加処理開始 - サークルID: \(circle.id), サークル名: \(circle.name)")
        
        // 参加前のエラーメッセージをクリア
        circleManager.errorMessage = nil
        
        circleManager.joinCircle(circleId: circle.id, message: nil)
        
        // 結果を監視（ローディング状態を確認）
        checkJoinResult()
    }
    
    private func checkJoinResult() {
        // ローディング中の場合は少し待ってから再チェック
        if circleManager.isLoading {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                checkJoinResult()
            }
            return
        }
        
        // ローディング完了後の状態をチェック
        if let error = circleManager.errorMessage {
            print("[ERROR] 参加失敗: \(error)")
            
            // 上限エラーかどうかをチェック
            if error.contains("参加可能なサークル数の上限に達しています") {
                showingLimitAlert = true
            } else {
                errorMessage = error
                showingErrorAlert = true
            }
        } else {
            print("[SUCCESS] 参加成功 - チャット画面を表示します")
            showingSuccessAlert = true
            // 成功時のコールバックを呼び出し
            onJoinSuccess?()
        }
    }
}

// MARK: - Circle Limit Alert View
struct CircleLimitAlertView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 20) {
                // アイコン
                ZStack {
                    SwiftUI.Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                }
                
                VStack(spacing: 12) {
                    Text("サークル参加上限")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("参加可能なサークル数の上限に達しています。")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("プレミアム会員: 4サークルまで")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                            Text("通常会員: 2サークルまで")
                                .font(.caption)
                        }
                    }
                    .padding(.top, 8)
                }
                
                VStack(spacing: 12) {
                    Button {
                        // プレミアム画面への遷移
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                            Text("プレミアムにアップグレード")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.orange, .red]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        isPresented = false
                    } label: {
                        Text("OK")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
            .padding(.horizontal, 40)
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
    @Binding var mainSelectedTab: Int
    
    var body: some View {
        switch selectedTab {
        case 0:
            CircleOverviewView(circle: circle)
        case 1:
            CircleChatTabView(circle: circle, selectedTab: $mainSelectedTab)
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
    @Binding var selectedTab: Int
    
    var body: some View {
        // 新しいリッチなチャット画面を使用
        CircleChatView(circle: circle, selectedTab: $selectedTab)
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
    @StateObject private var circleManager = CircleManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ヘッダー
            HStack {
                Text("メンバー")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(circleManager.circleMembers.count)人")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            // デバッグ情報
            VStack(alignment: .leading, spacing: 4) {
                Text("デバッグ情報:")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("ローディング: \(circleManager.isLoading ? "true" : "false")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("メンバー数: \(circleManager.circleMembers.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("エラー: \(circleManager.errorMessage ?? "なし")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            if circleManager.isLoading {
                VStack {
                    ProgressView("メンバー情報を読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else if circleManager.circleMembers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.2")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("メンバー情報を取得できませんでした")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("サークルID: \(circle.id)")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Button("再読み込み") {
                        loadMembers()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // 管理者セクション
                        let admins = circleManager.circleMembers.filter { $0.role == .admin }
                        if !admins.isEmpty {
                            MemberSectionView(title: "管理者", members: admins, color: .orange)
                        }
                        
                        // モデレーターセクション
                        let moderators = circleManager.circleMembers.filter { $0.role == .moderator }
                        if !moderators.isEmpty {
                            MemberSectionView(title: "モデレーター", members: moderators, color: .blue)
                        }
                        
                        // 一般メンバーセクション
                        let regularMembers = circleManager.circleMembers.filter { $0.role == .member }
                        if !regularMembers.isEmpty {
                            MemberSectionView(title: "メンバー", members: regularMembers, color: .green)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .onAppear {
            print("[DEBUG] CircleMembersView onAppear - circleId: \(circle.id)")
            loadMembers()
        }
        .refreshable {
            loadMembers()
        }
    }
    
    private func loadMembers() {
        print("[DEBUG] CircleMembersView loadMembers 開始")
        circleManager.loadCircleMembers(circleId: circle.id)
    }
}

// MARK: - メンバーセクションビュー
struct MemberSectionView: View {
    let title: String
    let members: [CircleMember]
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: getSectionIcon())
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
                Text("(\(members.count)人)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal)
            
            ForEach(members) { member in
                CircleMemberRow(member: member)
                    .padding(.horizontal)
            }
        }
    }
    
    private func getSectionIcon() -> String {
        switch title {
        case "管理者":
            return "crown.fill"
        case "モデレーター":
            return "shield.fill"
        default:
            return "person.fill"
        }
    }
}

// MARK: - Circle Member Row
struct CircleMemberRow: View {
    let member: CircleMember
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // プロフィール画像
                AsyncImage(url: URL(string: member.user.avatarUrl ?? "")) { image in
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
                .frame(width: 50, height: 50)
                .clipShape(SwiftUI.Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(member.user.displayName ?? member.user.username)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // 参加日
                        Text(formatJoinDate(member.joinedAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // 自己紹介（あれば）
                    if let bio = member.user.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            
            // 興味関心
            if !member.interests.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.pink)
                        
                        Text("興味関心")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(member.interests.prefix(5), id: \.id) { interest in
                                Text(interest.name)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.pink.opacity(0.1))
                                    .foregroundColor(.pink)
                                    .clipShape(Capsule())
                            }
                            
                            if member.interests.count > 5 {
                                Text("+\(member.interests.count - 5)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.1))
                                    .foregroundColor(.gray)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func formatJoinDate(_ dateString: String) -> String {
        // 簡易的な日付フォーマット
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else {
            return "最近"
        }
        
        let now = Date()
        let components = Calendar.current.dateComponents([.day], from: date, to: now)
        
        if let days = components.day {
            if days == 0 {
                return "今日"
            } else if days == 1 {
                return "1日前"
            } else if days < 7 {
                return "\(days)日前"
            } else if days < 30 {
                return "\(days / 7)週間前"
            } else {
                return "\(days / 30)ヶ月前"
            }
        }
        
        return "最近"
    }
}

// MARK: - Circle Member Models
struct CircleMember: Identifiable, Codable {
    let id: String
    let user: CircleMemberUser
    let role: MemberRole
    let joinedAt: String
    let interests: [Interest]
    
    enum MemberRole: String, Codable {
        case member = "member"
        case moderator = "moderator"
        case admin = "admin"
    }
    
    static func sampleMembers() -> [CircleMember] {
        return generateSampleMembers()
    }
    
    static func generateSampleMembers() -> [CircleMember] {
        let sampleUserData = [
            // 管理者・モデレーター
            ("alice_dev", "Alice", "フロントエンド開発者。React/Vue.jsが好きです。", MemberRole.admin, "2024-01-15", ["プログラミング", "Web開発", "デザイン"]),
            ("bob_design", "Bob", "UIデザイナー。美しいインターフェースを作ることが情熱です。", MemberRole.moderator, "2024-02-10", ["デザイン", "UI/UX", "グラフィック"]),
            ("carol_lead", "Carol", "プロジェクトマネージャー。チーム作りが得意です。", MemberRole.moderator, "2024-01-20", ["マネジメント", "チームワーク", "プロジェクト"]),
            
            // アクティブメンバー
            ("charlie_game", "Charlie", "ゲーム開発に興味があります。UnityとC#を学習中。", MemberRole.member, "2024-03-05", ["ゲーム開発", "Unity", "プログラミング"]),
            ("diana_ai", "Diana", "AI・機械学習エンジニア。Pythonとデータサイエンスが専門です。", MemberRole.member, "2024-02-28", ["AI", "機械学習", "Python"]),
            ("edward_mobile", "Edward", "モバイル開発者。SwiftとKotlinでアプリを作っています。", MemberRole.member, "2024-03-12", ["Swift", "iOS", "モバイル開発"]),
            ("fiona_backend", "Fiona", "バックエンドエンジニア。Node.jsとGoが得意です。", MemberRole.member, "2024-03-18", ["バックエンド", "Node.js", "Go"]),
            ("george_data", "George", "データアナリスト。統計とビジュアライゼーションが好きです。", MemberRole.member, "2024-03-25", ["データ分析", "統計", "可視化"]),
            ("hannah_ux", "Hannah", "UXリサーチャー。ユーザーの声を大切にしています。", MemberRole.member, "2024-04-02", ["UX", "リサーチ", "ユーザビリティ"]),
            ("ivan_security", "Ivan", "セキュリティエンジニア。安全なシステム作りに取り組んでいます。", MemberRole.member, "2024-04-08", ["セキュリティ", "インフラ", "ネットワーク"]),
            
            // 新しいメンバー
            ("julia_pm", "Julia", "プロダクトマネージャー。ユーザー体験の向上を目指しています。", MemberRole.member, "2024-04-15", ["プロダクト", "戦略", "ユーザー体験"]),
            ("kevin_devops", "Kevin", "DevOpsエンジニア。CI/CDとクラウドインフラが専門です。", MemberRole.member, "2024-04-20", ["DevOps", "AWS", "Docker"]),
            ("lisa_frontend", "Lisa", "フロントエンドエンジニア。React Nativeでモバイルアプリも作ります。", MemberRole.member, "2024-04-25", ["React", "JavaScript", "フロントエンド"]),
            ("mike_full", "Mike", "フルスタック開発者。何でも作れるようになりたいです！", MemberRole.member, "2024-05-01", ["フルスタック", "Web開発", "データベース"]),
            ("nina_qa", "Nina", "QAエンジニア。品質の高いソフトウェアを目指します。", MemberRole.member, "2024-05-05", ["QA", "テスト", "品質管理"]),
            ("oscar_blockchain", "Oscar", "ブロックチェーン開発者。分散システムに興味があります。", MemberRole.member, "2024-05-10", ["ブロックチェーン", "暗号通貨", "Web3"]),
            ("penny_marketing", "Penny", "テックマーケター。技術とビジネスをつなぐ役割です。", MemberRole.member, "2024-05-15", ["マーケティング", "ビジネス", "コミュニケーション"]),
            ("quinn_student", "Quinn", "コンピューターサイエンス専攻の大学生です。", MemberRole.member, "2024-05-20", ["コンピューターサイエンス", "アルゴリズム", "学習"]),
            ("ruby_designer", "Ruby", "グラフィックデザイナー。ブランディングとロゴデザインが得意。", MemberRole.member, "2024-05-25", ["グラフィックデザイン", "ブランディング", "ロゴ"]),
            ("sam_entrepreneur", "Sam", "起業家志望。テック系スタートアップを準備中です。", MemberRole.member, "2024-06-01", ["起業", "スタートアップ", "ビジネス"])
        ]
        
        return sampleUserData.enumerated().map { index, userData in
            let (username, displayName, bio, role, joinedAt, interestNames) = userData
            
            // 興味関心をInterestオブジェクトに変換
            let interests = interestNames.enumerated().map { interestIndex, name in
                Interest(
                    id: "\(index)_\(interestIndex)",
                    name: name,
                    description: nil,
                    category: getCategoryForInterest(name),
                    isOfficial: true,
                    usageCount: Int.random(in: 10...100),
                    iconUrl: nil,
                    createdAt: "2024-01-01T00:00:00Z",
                    updatedAt: "2024-01-01T00:00:00Z"
                )
            }
            
            return CircleMember(
                id: "\(index + 1)",
                user: CircleMemberUser(
                    id: "user\(index + 1)",
                    username: username,
                    displayName: displayName,
                    bio: bio,
                    avatarUrl: nil
                ),
                role: role,
                joinedAt: joinedAt,
                interests: interests
            )
        }
    }
    
    private static func getCategoryForInterest(_ interestName: String) -> String {
        switch interestName {
        case "プログラミング", "Web開発", "AI", "機械学習", "Python", "Swift", "iOS", "バックエンド", "Node.js", "Go", "セキュリティ", "DevOps", "AWS", "Docker", "React", "JavaScript", "フルスタック", "データベース", "ブロックチェーン", "暗号通貨", "Web3", "Unity", "ゲーム開発", "モバイル開発", "フロントエンド", "インフラ", "ネットワーク", "コンピューターサイエンス", "アルゴリズム":
            return "technical"
        case "デザイン", "UI/UX", "グラフィック", "UX", "ユーザビリティ", "グラフィックデザイン", "ブランディング", "ロゴ":
            return "creative"
        case "マネジメント", "チームワーク", "プロジェクト", "プロダクト", "戦略", "ユーザー体験", "マーケティング", "ビジネス", "起業", "スタートアップ":
            return "business"
        case "データ分析", "統計", "可視化", "リサーチ", "QA", "テスト", "品質管理", "学習":
            return "analysis"
        default:
            return "other"
        }
    }
}

struct CircleMemberUser: Codable {
    let id: String
    let username: String
    let displayName: String?
    let bio: String?
    let avatarUrl: String?
}

// MARK: - API Response Models
struct CircleMembersResponse: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [CircleMember]
}

// MARK: - Join Circle Sheet
struct JoinCircleSheet: View {
    let circle: KnestCircle
    @Binding var applicationMessage: String
    let onJoin: () -> Void
    let onSuccess: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("「\(circle.name)」に参加申請")
                    .font(.title2)
                    .fontWeight(.bold)
                
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
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("承認プロセス")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(.blue)
                            Text("参加申請を送信")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: "2.circle.fill")
                                .foregroundColor(.orange)
                            Text("サークル管理者が申請を確認")
                                .font(.caption)
                        }
                        
                        HStack {
                            Image(systemName: "3.circle.fill")
                                .foregroundColor(.green)
                            Text("承認後、サークルに参加")
                                .font(.caption)
                        }
                    }
                    .padding(.leading, 8)
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
                        .background(applicationMessage.trim().isEmpty ? Color.gray : Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(applicationMessage.trim().isEmpty)
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

// MARK: - String Extension for trim
extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    CircleDetailView(circle: KnestCircle.sample(), selectedTab: .constant(0))
} 
