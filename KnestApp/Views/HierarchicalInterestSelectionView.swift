//
//  HierarchicalInterestSelectionView.swift
//  KnestApp
//
//  Created by Claude on 2025/06/08.
//

import SwiftUI

struct HierarchicalInterestSelectionView: View {
    @StateObject private var interestManager = HierarchicalInterestManager()
    @State private var selectedCategory: InterestCategory?
    @State private var selectedSubcategory: InterestSubcategory?
    @State private var selectedTag: InterestTag?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 進行状況インジケーター
                ProgressIndicator(
                    selectedCategory: selectedCategory,
                    selectedSubcategory: selectedSubcategory,
                    selectedTag: selectedTag
                )
                
                if interestManager.isLoading {
                    ProgressView("読み込み中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // 選択階層に応じた表示
                    if selectedTag != nil {
                        // タグ選択完了時は即座に保存
                        TagConfirmationView(
                            selectedCategory: selectedCategory,
                            selectedSubcategory: selectedSubcategory,
                            selectedTag: selectedTag
                        ) {
                            addInterest(level: 3)
                        } onBack: {
                            selectedTag = nil
                        }
                    } else if selectedSubcategory != nil {
                        VStack(spacing: 16) {
                            // サブカテゴリレベルで保存オプション
                            SaveAtLevelButton(
                                title: "「\(selectedSubcategory?.name ?? "")」として保存",
                                level: 2
                            ) {
                                addInterest(level: 2)
                            }
                            
                            Divider()
                            
                            // タグ選択で詳細化
                            TagSelectionView(
                                tags: filteredTags,
                                selectedTag: $selectedTag,
                                interestManager: interestManager,
                                onBack: { selectedSubcategory = nil }
                            )
                        }
                    } else if selectedCategory != nil {
                        VStack(spacing: 16) {
                            // カテゴリレベルで保存オプション
                            SaveAtLevelButton(
                                title: "「\(selectedCategory?.name ?? "")」として保存",
                                level: 1
                            ) {
                                addInterest(level: 1)
                            }
                            
                            Divider()
                            
                            // サブカテゴリ表示（周辺表示）
                            SubcategoryGridView(
                                subcategories: filteredSubcategories,
                                selectedSubcategory: $selectedSubcategory,
                                onBack: { selectedCategory = nil }
                            )
                        }
                    } else {
                        CategorySelectionView(
                            categories: interestManager.categories,
                            selectedCategory: $selectedCategory
                        )
                    }
                }
            }
            .navigationTitle("興味関心を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                if selectedCategory != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("戻る") {
                            resetSelection()
                        }
                    }
                }
            }
        }
        .onAppear {
            interestManager.loadCategories()
            interestManager.loadUserProfiles()
        }
        .onChange(of: selectedCategory) { oldValue, newValue in
            if let category = newValue {
                interestManager.loadSubcategories(for: category.id)
            }
        }
        .onChange(of: selectedSubcategory) { oldValue, newValue in
            if let subcategory = newValue {
                interestManager.loadTags(for: subcategory.id)
            }
        }
        .alert("エラー", isPresented: .constant(interestManager.error != nil)) {
            Button("OK") {
                interestManager.error = nil
            }
        } message: {
            if let error = interestManager.error {
                Text(error)
            }
        }
    }
    
    // MARK: - データフィルタリング
    
    private var filteredSubcategories: [InterestSubcategory] {
        guard let categoryId = selectedCategory?.id else { return [] }
        return interestManager.subcategories.filter { $0.category.id == categoryId }
    }
    
    private var filteredTags: [InterestTag] {
        guard let subcategoryId = selectedSubcategory?.id else { return [] }
        return interestManager.tags.filter { $0.subcategory.id == subcategoryId }
    }
    
    // MARK: - アクション
    
    private func addInterest(level: Int) {
        switch level {
        case 1: // カテゴリレベル
            guard let category = selectedCategory else { return }
            
            // 重複チェック
            if interestManager.isCategorySelected(category.id) {
                interestManager.error = "「\(category.name)」は既に選択されています"
                return
            }
            
            interestManager.addInterestAtCategoryLevel(categoryId: category.id)
        case 2: // サブカテゴリレベル
            guard let category = selectedCategory,
                  let subcategory = selectedSubcategory else { return }
            
            // 重複チェック
            if interestManager.isSubcategorySelected(subcategory.id) {
                interestManager.error = "「\(subcategory.name)」は既に選択されています"
                return
            }
            
            interestManager.addInterestAtSubcategoryLevel(
                categoryId: category.id,
                subcategoryId: subcategory.id
            )
        case 3: // タグレベル
            guard let tag = selectedTag else { return }
            
            // 重複チェック
            if interestManager.isTagSelected(tag.id) {
                interestManager.error = "「\(tag.name)」は既に選択されています"
                return
            }
            
            interestManager.addInterest(tagId: tag.id)
        default:
            return
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func resetSelection() {
        selectedTag = nil
        selectedSubcategory = nil
        selectedCategory = nil
    }
}

// MARK: - レベル保存ボタン

struct SaveAtLevelButton: View {
    let title: String
    let level: Int
    let action: () -> Void
    @State private var isPressed = false
    
    private var buttonColors: [Color] {
        switch level {
        case 1: return [.blue, .cyan]
        case 2: return [.green, .mint]
        default: return [.purple, .pink]
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 12) {
                // レベルアイコン
                ZStack {
                    SwiftUI.Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: level == 1 ? "bookmark.fill" : level == 2 ? "star.fill" : "heart.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("この階層で興味関心として保存")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: buttonColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: buttonColors[0].opacity(0.4),
                        radius: isPressed ? 4 : 12,
                        x: 0,
                        y: isPressed ? 2 : 6
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .padding(.horizontal, 20)
    }
}

// MARK: - サブカテゴリグリッド表示（周辺表示）

struct SubcategoryGridView: View {
    let subcategories: [InterestSubcategory]
    @Binding var selectedSubcategory: InterestSubcategory?
    let onBack: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ヘッダー
                VStack(spacing: 12) {
                    Text("さらに詳細に選択")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("より具体的な興味関心を選択できます（オプション）")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // サブカテゴリグリッド
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(subcategories) { subcategory in
                        ModernSubcategoryCard(subcategory: subcategory) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                selectedSubcategory = subcategory
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - モダンサブカテゴリカード

struct ModernSubcategoryCard: View {
    let subcategory: InterestSubcategory
    @State private var isPressed = false
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            VStack(spacing: 12) {
                // アイコンエリア
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.green.opacity(0.8), .mint.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.green.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 6) {
                    Text(subcategory.name)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(subcategory.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: .green.opacity(0.1),
                        radius: isPressed ? 2 : 8,
                        x: 0,
                        y: isPressed ? 1 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.green.opacity(0.3), .mint.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.15), value: isPressed)
    }
}

// MARK: - 進行状況インジケーター

struct ProgressIndicator: View {
    let selectedCategory: InterestCategory?
    let selectedSubcategory: InterestSubcategory?
    let selectedTag: InterestTag?
    
    var currentStep: Int {
        if selectedTag != nil { return 3 }
        if selectedSubcategory != nil { return 2 }
        if selectedCategory != nil { return 1 }
        return 0
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // ステップインジケーター
            HStack(spacing: 0) {
                ForEach(1...3, id: \.self) { step in
                    HStack(spacing: 0) {
                        // ステップサークル
                        ZStack {
                            SwiftUI.Circle()
                                .fill(
                                    step <= currentStep 
                                    ? LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.gray.opacity(0.2)],
                                        startPoint: .center,
                                        endPoint: .center
                                    )
                                )
                                .frame(width: 32, height: 32)
                                .shadow(
                                    color: step <= currentStep ? .blue.opacity(0.3) : .clear,
                                    radius: step <= currentStep ? 4 : 0,
                                    x: 0,
                                    y: 2
                                )
                            
                            // ステップアイコン
                            if step <= currentStep {
                                Image(systemName: step == currentStep ? stepIcon(for: step) : "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(step)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.gray)
                            }
                        }
                        .scaleEffect(step == currentStep ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                        
                        // 接続線
                        if step < 3 {
                            Rectangle()
                                .fill(
                                    step < currentStep 
                                    ? LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.gray.opacity(0.3)],
                                        startPoint: .center,
                                        endPoint: .center
                                    )
                                )
                                .frame(height: 3)
                                .frame(maxWidth: .infinity)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // ステップラベル
            HStack {
                VStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .font(.caption)
                        .foregroundColor(currentStep >= 1 ? .blue : .gray)
                    
                    Text("カテゴリ")
                        .font(.caption)
                        .fontWeight(currentStep >= 1 ? .semibold : .regular)
                        .foregroundColor(currentStep >= 1 ? .blue : .gray)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Image(systemName: "folder.badge.plus")
                        .font(.caption)
                        .foregroundColor(currentStep >= 2 ? .blue : .gray)
                    
                    Text("サブカテゴリ")
                        .font(.caption)
                        .fontWeight(currentStep >= 2 ? .semibold : .regular)
                        .foregroundColor(currentStep >= 2 ? .blue : .gray)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Image(systemName: "tag.fill")
                        .font(.caption)
                        .foregroundColor(currentStep >= 3 ? .blue : .gray)
                    
                    Text("タグ")
                        .font(.caption)
                        .fontWeight(currentStep >= 3 ? .semibold : .regular)
                        .foregroundColor(currentStep >= 3 ? .blue : .gray)
                }
            }
            .padding(.horizontal, 24)
            
            // 現在の選択状況 - よりエレガントに
            if let category = selectedCategory {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(.purple)
                    
                    Text("選択中:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            BreadcrumbChip(text: category.name, color: .blue)
                            
                            if let subcategory = selectedSubcategory {
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                BreadcrumbChip(text: subcategory.name, color: .green)
                                
                                if let tag = selectedTag {
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    
                                    BreadcrumbChip(text: tag.name, color: .purple)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.systemBackground),
                            Color(.systemGray6).opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
    }
    
    private func stepIcon(for step: Int) -> String {
        switch step {
        case 1: return "folder.fill"
        case 2: return "folder.badge.plus"
        case 3: return "tag.fill"
        default: return "circle.fill"
        }
    }
}

// MARK: - パンくずリストチップ
struct BreadcrumbChip: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color)
            )
            .shadow(color: color.opacity(0.3), radius: 2, x: 0, y: 1)
    }
}

// MARK: - カテゴリ選択画面

struct CategorySelectionView: View {
    let categories: [InterestCategory]
    @Binding var selectedCategory: InterestCategory?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ヘッダー
                VStack(spacing: 12) {
                    Text("どの分野に興味がありますか？")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("あなたに合ったサークルを見つけるお手伝いをします")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // カテゴリグリッド
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(categories) { category in
                        ModernCategoryCard(category: category) {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct ModernCategoryCard: View {
    let category: InterestCategory
    @State private var isPressed = false
    let onTap: () -> Void
    
    private var cardColors: [Color] {
        switch category.type {
        case "technical":
            return [Color.blue, Color.cyan]
        case "creative":
            return [Color.purple, Color.pink]
        case "health":
            return [Color.green, Color.mint]
        case "learning":
            return [Color.orange, Color.yellow]
        default:
            return [Color.gray, Color.secondary]
        }
    }
    
    var body: some View {
        Button(action: {
            // アニメーション付きでタップ処理
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            // 少し遅延してアクション実行
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            VStack(spacing: 16) {
                // アイコンエリア
                ZStack {
                    SwiftUI.Circle()
                        .fill(
                            LinearGradient(
                                colors: cardColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .shadow(color: cardColors[0].opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Text(categoryIcon(for: category.type))
                        .font(.system(size: 24))
                }
                
                VStack(spacing: 8) {
                    Text(category.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(category.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(
                        color: cardColors[0].opacity(0.1),
                        radius: isPressed ? 2 : 8,
                        x: 0,
                        y: isPressed ? 1 : 4
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: cardColors.map { $0.opacity(0.3) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    private func categoryIcon(for type: String) -> String {
        switch type {
        case "technical": return "💻"
        case "creative": return "🎨"
        case "health": return "💪"
        case "learning": return "📚"
        case "music": return "🎵"
        case "gaming": return "🎮"
        case "sports": return "⚽"
        case "food": return "🍳"
        default: return "⭐"
        }
    }
}

// MARK: - タグ選択画面

struct TagSelectionView: View {
    let tags: [InterestTag]
    @Binding var selectedTag: InterestTag?
    let interestManager: HierarchicalInterestManager
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 美しいヘッダー
            VStack(spacing: 16) {
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                            
                            Text("戻る")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    Text("具体的なタグを選択")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("どんなことに特に興味がありますか？")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // タグリスト
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(tags) { tag in
                        ModernTagCard(tag: tag, interestManager: interestManager) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTag = tag
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct ModernTagCard: View {
    let tag: InterestTag
    let interestManager: HierarchicalInterestManager
    @State private var isPressed = false
    let onTap: () -> Void
    
    // 選択済みかどうかを判定
    private var isAlreadySelected: Bool {
        interestManager.isTagSelected(tag.id)
    }
    
    var body: some View {
        Button(action: {
            // 既に選択済みの場合はタップを無効化
            guard !isAlreadySelected else { return }
            
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            HStack(spacing: 16) {
                // タグアイコン
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: isAlreadySelected ? 
                                    [.gray.opacity(0.4), .gray.opacity(0.6)] :
                                    [.purple.opacity(0.8), .pink.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(
                            color: isAlreadySelected ? .gray.opacity(0.2) : .purple.opacity(0.3), 
                            radius: 4, 
                            x: 0, 
                            y: 2
                        )
                    
                    Image(systemName: isAlreadySelected ? "checkmark" : "tag")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(tag.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(isAlreadySelected ? .secondary : .primary)
                        
                        if isAlreadySelected {
                            Text("選択済み")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text("\(tag.usageCount)人が使用中")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 選択インジケーター
                Image(systemName: isAlreadySelected ? "checkmark.circle.fill" : "arrow.right.circle")
                    .font(.title3)
                    .foregroundColor(isAlreadySelected ? .green : .purple)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isAlreadySelected ? Color(.systemGray6) : Color(.systemBackground))
                    .shadow(
                        color: isAlreadySelected ? .clear : .black.opacity(0.05), 
                        radius: isPressed ? 8 : 4, 
                        x: 0, 
                        y: isPressed ? 4 : 2
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isAlreadySelected ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isAlreadySelected) // 選択済みの場合はボタンを無効化
    }
}

// MARK: - タグ確認画面

struct TagConfirmationView: View {
    let selectedCategory: InterestCategory?
    let selectedSubcategory: InterestSubcategory?
    let selectedTag: InterestTag?
    let onSave: () -> Void
    let onBack: () -> Void
    @State private var showingAnimation = false
    
    var body: some View {
        VStack(spacing: 32) {
            // 成功アイコンとメッセージ
            VStack(spacing: 20) {
                ZStack {
                    SwiftUI.Circle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.green.opacity(0.3), radius: 12, x: 0, y: 6)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(showingAnimation ? 1.0 : 0.8)
                .animation(.easeInOut(duration: 0.5), value: showingAnimation)
                
                Text("選択を確認してください")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .secondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(.top, 40)
            
            // 選択項目の美しい表示
            VStack(spacing: 16) {
                if let category = selectedCategory {
                    ModernHierarchyRow(title: "カテゴリ", value: category.name, icon: "folder.fill", color: .blue)
                }
                
                if let subcategory = selectedSubcategory {
                    ModernHierarchyRow(title: "サブカテゴリ", value: subcategory.name, icon: "folder.badge.plus", color: .green)
                }
                
                if let tag = selectedTag {
                    ModernHierarchyRow(title: "タグ", value: tag.name, icon: "tag.fill", color: .purple)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.blue.opacity(0.2), .purple.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .padding(.horizontal, 20)
            
            Spacer()
            
            // アクションボタン
            VStack(spacing: 16) {
                // メイン保存ボタン
                Button(action: onSave) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                        
                        Text("興味関心に追加する")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // 戻るボタン
                Button("やり直す", action: onBack)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                showingAnimation = true
            }
        }
    }
}

// MARK: - モダンな階層行表示

struct ModernHierarchyRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // アイコン
            ZStack {
                SwiftUI.Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // 確認チェック
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(color)
        }
    }
}

#Preview {
    HierarchicalInterestSelectionView()
} 