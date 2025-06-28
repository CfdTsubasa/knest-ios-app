//
//  ProfileView.swift
//  KnestApp
//
//  Created by t.i on 2025/06/08.
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var interestManager = InterestManager()
    @StateObject private var hierarchicalInterestManager = HierarchicalInterestManager()
    @StateObject private var hashtagManager = HashtagManager.shared
    @State private var showingInterestSelection = false
    @State private var showingHierarchicalInterestSelection = false
    @State private var showingHashtagSelection = false
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // プロフィールヘッダー
                    profileHeader
                    
                    // ユーザー詳細情報（年齢・居住地）
                    userDetailsSection
                    
                    // 新しい階層的興味・関心セクション
                    hierarchicalInterestsSection
                    
                    // 従来の興味・関心セクション
                    interestsSection
                    
                    // ハッシュタグセクション
                    hashtagsSection
                    
                    // アクティビティセクション
                    activitySection
                    
                    // その他のセクション
                    otherSection
                }
                .padding()
            }
            .navigationTitle("プロフィール")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
        .onAppear {
            interestManager.loadUserInterests()
            hierarchicalInterestManager.loadUserProfiles()
            hashtagManager.loadUserTags()
        }
        .sheet(isPresented: $showingInterestSelection, onDismiss: {
            interestManager.loadUserInterests()
        }) {
            InterestSelectionView()
        }
        .sheet(isPresented: $showingHierarchicalInterestSelection, onDismiss: {
            hierarchicalInterestManager.loadUserProfiles()
        }) {
            HierarchicalInterestSelectionView()
        }
        .sheet(isPresented: $showingHashtagSelection, onDismiss: {
            hashtagManager.loadUserTags()
        }) {
            HashtagSelectionView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // アバター
            AsyncImage(url: URL(string: authManager.currentUser?.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                SwiftUI.Circle()
                    .foregroundColor(.gray)
                    .frame(width: 40, height: 40)
                    .clipShape(SwiftUI.Circle())
            }
            .frame(width: 100, height: 100)
            .clipShape(SwiftUI.Circle())
            .overlay(
                SwiftUI.Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            )
            
            // ユーザー情報
            VStack(spacing: 4) {
                Text(authManager.currentUser?.displayName ?? "Unknown User")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let bio = authManager.currentUser?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                if let emotionState = authManager.currentUser?.emotionState, !emotionState.isEmpty {
                    Text("今の気分: \(emotionState)")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(12)
                }
            }
            
            // プロフィール編集ボタン
            Button("プロフィールを編集") {
                showingEditProfile = true
            }
            .font(.subheadline)
            .foregroundColor(.blue)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(16)
    }
    
    // 新しいユーザー詳細情報セクション
    private var userDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("詳細情報")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.title3)
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("年齢")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    if let birthDate = authManager.currentUser?.birthDate {
                        Text("\(calculateAge(from: birthDate))歳")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    } else {
                        Text("未設定")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                HStack {
                    Image(systemName: "location")
                        .font(.title3)
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    Text("居住地")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    if let prefecture = authManager.currentUser?.prefecture {
                        Text(prefecture)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    } else {
                        Text("未設定")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // 新しい階層的興味関心セクション
    private var hierarchicalInterestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("興味関心プロフィール（3階層）")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("\(hierarchicalInterestManager.userProfiles.count)個設定中")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("編集") {
                    showingHierarchicalInterestSelection = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if hierarchicalInterestManager.userProfiles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(.purple)
                    
                    Text("詳細な興味関心を設定して\nより精度の高いマッチングを体験しよう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("興味関心を設定") {
                        showingHierarchicalInterestSelection = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.purple)
                    .cornerRadius(20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 16) {
                    ForEach(hierarchicalInterestManager.userProfiles) { profile in
                        HierarchicalInterestChip(profile: profile)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("興味・関心")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("\(interestManager.userInterests.count)個選択中")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("編集") {
                    showingInterestSelection = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if interestManager.userInterests.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "heart.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("興味・関心を追加して\nおすすめのサークルを見つけよう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("興味・関心を選択") {
                        showingInterestSelection = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(interestManager.userInterests) { userInterest in
                        InterestChip(userInterest: userInterest)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var hashtagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ハッシュタグ")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("\(hashtagManager.userTags.count)個選択中")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("編集") {
                    showingHashtagSelection = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if hashtagManager.userTags.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "number.circle")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("ハッシュタグを追加して\nおすすめのサークルを見つけよう")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("ハッシュタグを選択") {
                        showingHashtagSelection = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(20)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(hashtagManager.userTags) { userTag in
                        ProfileHashtagChip(userTag: userTag)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("アクティビティ")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ActivityRow(
                    icon: "person.3.fill",
                    title: "参加中のサークル",
                    value: "0個",
                    color: .blue
                )
                
                ActivityRow(
                    icon: "message.fill",
                    title: "投稿数",
                    value: "0個",
                    color: .green
                )
                
                ActivityRow(
                    icon: "heart.fill",
                    title: "もらったいいね",
                    value: "0個",
                    color: .pink
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var otherSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("その他")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 0) {
                NavigationLink(destination: Text("プロフィール編集")) {
                    MenuRow(icon: "person.crop.circle", title: "プロフィール編集")
                }
                
                Divider()
                
                NavigationLink(destination: Text("プライバシー設定")) {
                    MenuRow(icon: "lock.shield", title: "プライバシー設定")
                }
                
                Divider()
                
                NavigationLink(destination: Text("通知設定")) {
                    MenuRow(icon: "bell", title: "通知設定")
                }
                
                Divider()
                
                NavigationLink(destination: Text("ヘルプ・サポート")) {
                    MenuRow(icon: "questionmark.circle", title: "ヘルプ・サポート")
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // Helper function for age calculation
    private func calculateAge(from birthDate: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let birth = formatter.date(from: birthDate) else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birth, to: now)
        
        return ageComponents.year ?? 0
    }
}

struct InterestChip: View {
    let userInterest: UserInterest
    
    var body: some View {
        HStack(spacing: 6) {
            Text(userInterest.interest.name)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(12)
    }
}

struct ProfileHashtagChip: View {
    let userTag: UserTag
    
    var body: some View {
        HStack(spacing: 6) {
            Text("#\(userTag.tag.name)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(12)
    }
}

struct ActivityRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

struct MenuRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.gray)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 12)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("アカウント") {
                    Button("ログアウト") {
                        authManager.logout()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// 新しい階層的興味関心チップコンポーネント
struct HierarchicalInterestChip: View {
    let profile: UserInterestProfile
    @State private var isAnimating = false
    
    private var displayText: String {
        if let tag = profile.tag {
            return tag.name
        } else if let subcategory = profile.subcategory {
            return subcategory.name
        } else if let category = profile.category {
            return category.name
        }
        return "Unknown"
    }
    
    private var levelInfo: (icon: String, colors: [Color], title: String) {
        if profile.tag != nil {
            return ("tag.fill", [.purple, .pink], "タグ")
        } else if profile.subcategory != nil {
            return ("folder.badge.plus", [.green, .mint], "サブカテゴリ")
        } else if profile.category != nil {
            return ("folder.fill", [.blue, .cyan], "カテゴリ")
        }
        return ("questionmark.circle", [.gray, .secondary], "不明")
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // レベルアイコン（上部固定）
            ZStack {
                SwiftUI.Circle()
                    .fill(
                        LinearGradient(
                            colors: levelInfo.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .shadow(color: levelInfo.colors[0].opacity(0.3), radius: 3, x: 0, y: 2)
                
                Image(systemName: levelInfo.icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
            
            // テキスト情報（中央固定）
            VStack(spacing: 4) {
                Text(displayText)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 32) // 固定高さ（2行分）
                
                Text(levelInfo.title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(height: 16) // 固定高さ
            }
        }
        .frame(width: 120, height: 100) // 固定サイズ
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: levelInfo.colors[0].opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: levelInfo.colors.map { $0.opacity(0.3) },
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// 新しいプロフィール編集ビュー
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthenticationManager.shared
    
    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var emotionState: String = ""
    @State private var birthDate = Date()
    @State private var selectedPrefecture: Prefecture = .tokyo
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    TextField("表示名", text: $displayName)
                    TextField("自己紹介", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("今の気分", text: $emotionState)
                }
                
                Section("詳細情報") {
                    DatePicker("生年月日", selection: $birthDate, displayedComponents: .date)
                    
                    Picker("居住地", selection: $selectedPrefecture) {
                        ForEach(Prefecture.allCases, id: \.self) { prefecture in
                            Text(prefecture.displayName).tag(prefecture)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }
            .navigationTitle("プロフィール編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadCurrentProfile()
        }
    }
    
    private func loadCurrentProfile() {
        if let user = authManager.currentUser {
            displayName = user.displayName ?? ""
            bio = user.bio ?? ""
            emotionState = user.emotionState ?? ""
            
            if let birthDateString = user.birthDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                birthDate = formatter.date(from: birthDateString) ?? Date()
            }
            
            if let prefectureString = user.prefecture,
               let prefecture = Prefecture.allCases.first(where: { $0.rawValue == prefectureString }) {
                selectedPrefecture = prefecture
            }
        }
    }
    
    private func saveProfile() {
        // TODO: API連携で実際の保存処理を実装
        print("プロフィール保存: \(displayName), \(selectedPrefecture.displayName)")
        dismiss()
    }
}

#Preview {
    ProfileView()
} 