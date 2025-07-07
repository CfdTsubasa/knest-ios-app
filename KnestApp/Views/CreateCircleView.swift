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
    @StateObject private var hierarchicalInterestManager = HierarchicalInterestManager()
    
    @State private var name = ""
    @State private var description = ""
    @State private var circleType: CircleType = .public
    @State private var memberLimit: Int? = nil
    @State private var hasMemberLimit = false
    @State private var rules = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var showingInterestSelection = false
    @State private var selectedInterests: [InterestTag] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section("基本情報") {
                    TextField("サークル名", text: $name)
                    TextField("説明", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("興味・関心") {
                    if selectedInterests.isEmpty {
                        Button("興味・関心を選択") {
                            showingInterestSelection = true
                        }
                    } else {
                        ForEach(selectedInterests) { interest in
                            HStack {
                                Text(interest.name)
                                Spacer()
                                Button {
                                    selectedInterests.removeAll { $0.id == interest.id }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        Button("興味・関心を追加") {
                            showingInterestSelection = true
                        }
                    }
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
            .sheet(isPresented: $showingInterestSelection) {
                HierarchicalInterestSelectionView()
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !description.isEmpty && !selectedInterests.isEmpty
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
            isPrivate: circleType == .private,
            interests: selectedInterests.map { $0.id }
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