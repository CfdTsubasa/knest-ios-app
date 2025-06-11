//
//  InterestSelectionView.swift
//  KnestApp
//
//  Created by t.i on 2025/06/08.
//

import SwiftUI

struct InterestSelectionView: View {
    @StateObject private var interestManager = InterestManager()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCategory: LegacyInterestCategory = .gaming
    @State private var showingErrorAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // カテゴリ選択
                categorySelector
                
                // 興味一覧
                interestsList
            }
            .navigationTitle("興味・関心を選択")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            print("📱 興味選択画面が表示されました")
            print("📱 興味データの読み込みを開始...")
            interestManager.loadInterests()
            print("📱 ユーザー興味データの読み込みを開始...")
            interestManager.loadUserInterests()
        }
        .overlay {
            if interestManager.isLoading {
                ProgressView("読み込み中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
            }
        }
        .alert("エラー", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(interestManager.errorMessage ?? "不明なエラーが発生しました")
        }
        .onChange(of: interestManager.errorMessage) { _, errorMessage in
            showingErrorAlert = errorMessage != nil
        }
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(LegacyInterestCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemGray6))
    }
    
    private var interestsList: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(interestManager.getInterestsByCategory(selectedCategory)) { interest in
                    InterestCard(
                        interest: interest,
                        isSelected: interestManager.isUserInterestedIn(interest.id)
                    ) {
                        if interestManager.isUserInterestedIn(interest.id) {
                            // 既に選択済みの場合は削除
                            if let userInterest = interestManager.userInterests.first(where: { $0.interest.id == interest.id }) {
                                interestManager.removeUserInterest(userInterestId: userInterest.id)
                            }
                        } else {
                            // 新規選択
                            interestManager.addUserInterest(interestId: interest.id)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct CategoryChip: View {
    let category: LegacyInterestCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                Text(category.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.blue : Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InterestCard: View {
    let interest: Interest
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(interest.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        if let description = interest.description, !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                    Spacer()
                    
                    // 選択インジケーターを分離
                    selectionIndicator
                }
                
                Spacer(minLength: 0)
                
                // ボトム情報を分離
                bottomInfo
            }
            .padding(12)
            .frame(height: 100)
            .background(cardBackground)
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 選択インジケーターを分離
    private var selectionIndicator: some View {
        ZStack {
            SwiftUI.Circle()
                .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .frame(width: 24, height: 24)
            
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .scaleEffect(isSelected ? 1.0 : 0.8)
                    .animation(.spring(response: 0.3), value: isSelected)
            }
        }
    }
    
    // ボトム情報を分離
    private var bottomInfo: some View {
        HStack {
            if interest.isOfficial {
                Image(systemName: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text("\(interest.usageCount)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // 背景スタイルを分離
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? Color.blue.opacity(0.1) : Color.white)
            .stroke(
                isSelected ? Color.blue : Color.gray.opacity(0.3),
                lineWidth: isSelected ? 2 : 1
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    InterestSelectionView()
} 