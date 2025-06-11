//
//  CreateCircleView.swift
//  KnestApp
//
//  Created by t.i on 2025/06/07.
//

import SwiftUI

struct CreateCircleView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var circleManager = CircleManager()
    
    @State private var name = ""
    @State private var description = ""
    @State private var circleType: CircleType = .public
    @State private var memberLimit: Int? = nil
    @State private var hasMemberLimit = false
    @State private var rules = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    TextField("サークル名", text: $name)
                    TextField("説明", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("設定") {
                    Picker("公開設定", selection: $circleType) {
                        ForEach(CircleType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    
                    Toggle("メンバー数制限", isOn: $hasMemberLimit)
                    
                    if hasMemberLimit {
                        Stepper("定員: \(memberLimit ?? 10)人", value: Binding(
                            get: { memberLimit ?? 10 },
                            set: { memberLimit = $0 }
                        ), in: 2...50)
                    }
                }
                
                Section("規約") {
                    TextField("サークル規約（任意）", text: $rules, axis: .vertical)
                        .lineLimit(3...8)
                }
                
                Section("タグ") {
                    if !tags.isEmpty {
                        TagListView(tags: tags) { tag in
                            tags.removeAll { $0 == tag }
                        }
                    }
                    
                    HStack {
                        TextField("タグを追加", text: $newTag)
                            .onSubmit {
                                addTag()
                            }
                        
                        Button("追加") {
                            addTag()
                        }
                        .disabled(newTag.isEmpty)
                    }
                }
            }
            .navigationTitle("サークル作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("作成") {
                        createCircle()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !description.isEmpty
    }
    
    private func addTag() {
        let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTag.isEmpty && !tags.contains(trimmedTag) && tags.count < 10 {
            tags.append(trimmedTag)
            newTag = ""
        }
    }
    
    private func createCircle() {
        let request = CreateCircleRequest(
            name: name,
            description: description,
            isPremium: nil, // プレミアム機能は現在未実装
            memberLimit: hasMemberLimit ? memberLimit : nil,
            isPrivate: circleType == .private,
            interests: [] // TODO: 興味選択機能実装時に対応
        )
        
        circleManager.createCircle(request: request)
        
        // TODO: 作成完了後の処理
        dismiss()
    }
}

struct TagListView: View {
    let tags: [String]
    let onRemove: (String) -> Void
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80))
        ], spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                HStack(spacing: 4) {
                    Text(tag)
                        .font(.caption)
                    
                    Button {
                        onRemove(tag)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    CreateCircleView()
} 