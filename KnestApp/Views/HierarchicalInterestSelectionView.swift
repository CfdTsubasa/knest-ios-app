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
    @State private var intensity: Int = 3
    @State private var showingIntensityPicker = false
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
                        IntensitySelectionView(intensity: $intensity) {
                            addInterest()
                        }
                    } else if selectedSubcategory != nil {
                        TagSelectionView(
                            tags: filteredTags,
                            selectedTag: $selectedTag,
                            onBack: { selectedSubcategory = nil }
                        )
                    } else if selectedCategory != nil {
                        SubcategorySelectionView(
                            subcategories: filteredSubcategories,
                            selectedSubcategory: $selectedSubcategory,
                            onBack: { selectedCategory = nil }
                        )
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
        }
        .onChange(of: selectedCategory) { category in
            if let category = category {
                interestManager.loadSubcategories(for: category.id)
            }
        }
        .onChange(of: selectedSubcategory) { subcategory in
            if let subcategory = subcategory {
                interestManager.loadTags(for: subcategory.id)
            }
        }
    }
    
    // MARK: - データフィルタリング
    
    private var filteredSubcategories: [InterestSubcategory] {
        guard let categoryId = selectedCategory?.id else { return [] }
        return interestManager.subcategories.filter { $0.category == categoryId }
    }
    
    private var filteredTags: [InterestTag] {
        guard let subcategoryId = selectedSubcategory?.id else { return [] }
        return interestManager.tags.filter { $0.subcategory == subcategoryId }
    }
    
    // MARK: - アクション
    
    private func addInterest() {
        guard let category = selectedCategory,
              let subcategory = selectedSubcategory,
              let tag = selectedTag else {
            return
        }
        
        interestManager.addInterest(
            tagId: tag.id,
            intensity: intensity
        )
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func resetSelection() {
        selectedTag = nil
        selectedSubcategory = nil
        selectedCategory = nil
    }
}

// MARK: - 進行状況インジケーター

struct ProgressIndicator: View {
    let selectedCategory: InterestCategory?
    let selectedSubcategory: InterestSubcategory?
    let selectedTag: InterestTag?
    
    var currentStep: Int {
        if selectedTag != nil { return 4 }
        if selectedSubcategory != nil { return 3 }
        if selectedCategory != nil { return 2 }
        return 1
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // ステップインジケーター
            HStack {
                ForEach(1...4, id: \.self) { step in
                    HStack {
                        Circle()
                            .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("\(step)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(step <= currentStep ? .white : .gray)
                            )
                        
                        if step < 4 {
                            Rectangle()
                                .fill(step < currentStep ? Color.blue : Color.gray.opacity(0.3))
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // ステップラベル
            HStack {
                Text("カテゴリ")
                    .font(.caption)
                    .foregroundColor(currentStep >= 1 ? .blue : .gray)
                
                Spacer()
                
                Text("サブカテゴリ")
                    .font(.caption)
                    .foregroundColor(currentStep >= 2 ? .blue : .gray)
                
                Spacer()
                
                Text("タグ")
                    .font(.caption)
                    .foregroundColor(currentStep >= 3 ? .blue : .gray)
                
                Spacer()
                
                Text("強度")
                    .font(.caption)
                    .foregroundColor(currentStep >= 4 ? .blue : .gray)
            }
            .padding(.horizontal)
            
            // 現在の選択状況
            if let category = selectedCategory {
                HStack {
                    Text("選択中:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(category.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    if let subcategory = selectedSubcategory {
                        Text("→ \(subcategory.name)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                        
                        if let tag = selectedTag {
                            Text("→ \(tag.name)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(UIColor.systemGray6))
    }
}

// MARK: - カテゴリ選択画面

struct CategorySelectionView: View {
    let categories: [InterestCategory]
    @Binding var selectedCategory: InterestCategory?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                Text("どの分野に興味がありますか？")
                    .font(.title3)
                    .fontWeight(.medium)
                    .padding()
                
                ForEach(categories) { category in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedCategory = category
                        }
                    }) {
                        CategoryCard(category: category)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

struct CategoryCard: View {
    let category: InterestCategory
    
    var body: some View {
        HStack(spacing: 16) {
            // カテゴリアイコン
            Text(categoryIcon(for: category.type))
                .font(.system(size: 40))
                .frame(width: 60, height: 60)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(category.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func categoryIcon(for type: String) -> String {
        switch type {
        case "music": return "🎵"
        case "gaming": return "🎮"
        case "learning": return "📚"
        case "sports": return "🏃‍♂️"
        case "food": return "🍳"
        case "creative": return "🎨"
        default: return "⭐"
        }
    }
}

// MARK: - サブカテゴリ選択画面

struct SubcategorySelectionView: View {
    let subcategories: [InterestSubcategory]
    @Binding var selectedSubcategory: InterestSubcategory?
    let onBack: () -> Void
    
    var body: some View {
        VStack {
            // 戻るボタン
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("カテゴリに戻る")
                    }
                    .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding()
            
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(subcategories) { subcategory in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedSubcategory = subcategory
                            }
                        }) {
                            SubcategoryCard(subcategory: subcategory)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct SubcategoryCard: View {
    let subcategory: InterestSubcategory
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text(subcategory.name)
                .font(.headline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(subcategory.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - タグ選択画面

struct TagSelectionView: View {
    let tags: [InterestTag]
    @Binding var selectedTag: InterestTag?
    let onBack: () -> Void
    
    var body: some View {
        VStack {
            // 戻るボタン
            HStack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("サブカテゴリに戻る")
                    }
                    .foregroundColor(.blue)
                }
                Spacer()
            }
            .padding()
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    Text("具体的にどんなことに興味がありますか？")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding()
                    
                    ForEach(tags) { tag in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTag = tag
                            }
                        }) {
                            TagCard(tag: tag)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct TagCard: View {
    let tag: InterestTag
    
    var body: some View {
        HStack {
            Text("#\(tag.name)")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(tag.usageCount)人が使用")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - 強度選択画面

struct IntensitySelectionView: View {
    @Binding var intensity: Int
    let onComplete: () -> Void
    
    private let intensityLabels = [
        1: "少し興味がある",
        2: "興味がある", 
        3: "とても興味がある",
        4: "大好き",
        5: "熱中している"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            Text("どのくらい興味がありますか？")
                .font(.title3)
                .fontWeight(.medium)
                .padding()
            
            VStack(spacing: 20) {
                ForEach(1...5, id: \.self) { level in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            intensity = level
                        }
                    }) {
                        IntensityCard(
                            level: level,
                            label: intensityLabels[level] ?? "",
                            isSelected: intensity == level
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: onComplete) {
                Text("追加する")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
}

struct IntensityCard: View {
    let level: Int
    let label: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            // 強度レベルの視覚表現
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { index in
                    Circle()
                        .fill(index <= level ? Color.blue : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("レベル \(level)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    HierarchicalInterestSelectionView()
} 