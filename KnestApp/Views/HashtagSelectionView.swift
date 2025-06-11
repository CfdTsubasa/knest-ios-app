//
//  HashtagSelectionView.swift
//  KnestApp
//
//  Created by t.i on 2025/06/08.
//

import SwiftUI

struct HashtagSelectionView: View {
    @StateObject private var hashtagManager = HashtagManager.shared
    @State private var newTagText = ""
    @State private var isSearching = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ヘッダー
                VStack(spacing: 16) {
                    Text("あなたの興味を\nハッシュタグで表現しよう")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                    
                    Text("同じ興味を持つ人と繋がりやすくなります")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)
                .padding(.bottom)
                
                // 検索・入力バー
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("タグを入力（例: プログラミング）", text: $newTagText)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                addNewTag()
                            }
                            .onChange(of: newTagText) { _, newValue in
                                if newValue.isEmpty {
                                    hashtagManager.suggestedTags = []
                                    isSearching = false
                                } else {
                                    isSearching = true
                                    hashtagManager.searchTags(query: newValue)
                                }
                            }
                        
                        if !newTagText.isEmpty {
                            Button("追加") {
                                addNewTag()
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // エラーメッセージ
                    if let errorMessage = hashtagManager.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // ユーザーのタグ
                        if !hashtagManager.userTags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("あなたのタグ")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                HashtagFlowLayout(tags: hashtagManager.userTags.map { $0.tag }, isUserTags: true) { tag in
                                    // ユーザータグを削除
                                    if let userTag = hashtagManager.userTags.first(where: { $0.tag.id == tag.id }) {
                                        hashtagManager.removeTag(userTag)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // サジェスト結果
                        if isSearching && !hashtagManager.suggestedTags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("候補")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                HashtagFlowLayout(tags: hashtagManager.suggestedTags, isUserTags: false) { tag in
                                    addTag(tag)
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // 人気タグ
                        if !isSearching && !hashtagManager.popularTags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("人気のタグ")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                HashtagFlowLayout(tags: hashtagManager.popularTags, isUserTags: false) { tag in
                                    addTag(tag)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                
                Spacer()
            }
            .navigationTitle("ハッシュタグ")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                hashtagManager.loadUserTags()
                hashtagManager.loadPopularTags()
            }
            .onTapGesture {
                isTextFieldFocused = false
            }
        }
    }
    
    private func addNewTag() {
        guard !newTagText.isEmpty else { return }
        hashtagManager.addTag(name: newTagText)
        newTagText = ""
        isTextFieldFocused = false
    }
    
    private func addTag(_ tag: Tag) {
        hashtagManager.addTag(name: tag.name)
        newTagText = ""
        isTextFieldFocused = false
    }
}

// ハッシュタグのフローレイアウト
struct HashtagFlowLayout: View {
    let tags: [Tag]
    let isUserTags: Bool
    let onTagTap: (Tag) -> Void
    
    var body: some View {
        FlowLayout(alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.id) { tag in
                HashtagChip(
                    tag: tag,
                    isUserTag: isUserTags,
                    onTap: { onTagTap(tag) }
                )
            }
        }
    }
}

// ハッシュタグチップ
struct HashtagChip: View {
    let tag: Tag
    let isUserTag: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text("#\(tag.name)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                if isUserTag {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                } else {
                    Image(systemName: "plus")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isUserTag ? Color.blue : Color(.systemGray5))
            .foregroundColor(isUserTag ? .white : .primary)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// フローレイアウト（タグを行でラップ）
struct FlowLayout: Layout {
    let alignment: HorizontalAlignment
    let spacing: CGFloat
    
    init(alignment: HorizontalAlignment = .center, spacing: CGFloat = 8) {
        self.alignment = alignment
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions(),
            subviews: subviews,
            alignment: alignment,
            spacing: spacing
        )
        return result.bounds
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions(),
            subviews: subviews,
            alignment: alignment,
            spacing: spacing
        )
        for index in subviews.indices {
            subviews[index].place(at: result.placements[index], proposal: .unspecified)
        }
    }
}

struct FlowResult {
    var bounds = CGSize.zero
    var placements: [CGPoint] = []
    
    init(in bounds: CGSize, subviews: LayoutSubviews, alignment: HorizontalAlignment, spacing: CGFloat) {
        var point = CGPoint.zero
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if point.x + subviewSize.width > bounds.width {
                point.x = 0
                point.y += lineHeight + spacing
                lineHeight = 0
            }
            
            placements.append(point)
            point.x += subviewSize.width + spacing
            lineHeight = max(lineHeight, subviewSize.height)
            maxX = max(maxX, point.x - spacing)
        }
        
        self.bounds = CGSize(width: maxX, height: point.y + lineHeight)
    }
}

#Preview {
    HashtagSelectionView()
} 