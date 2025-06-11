//
//  CircleChatView.swift
//  KnestApp
//
//  Created by t.i on 2025/06/11.
//

import SwiftUI

struct CircleChatView: View {
    let circle: KnestCircle
    @ObservedObject private var circleManager: CircleManager
    @State private var messageText = ""
    @State private var showingEmojiPicker = false
    @FocusState private var isTextFieldFocused: Bool
    
    init(circle: KnestCircle, circleManager: CircleManager = CircleManager.shared) {
        self.circle = circle
        self.circleManager = circleManager
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // チャットヘッダー
            ChatHeaderView(circle: circle)
            
            // デバッグ情報表示
            if circleManager.circleChats.isEmpty {
                Text("チャットデータがありません（count: \(circleManager.circleChats.count)）")
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text("チャット数: \(circleManager.circleChats.count)")
                    .foregroundColor(.blue)
                    .padding(.vertical, 4)
            }
            
            // メッセージリスト
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(circleManager.circleChats) { chat in
                            ChatMessageRowView(
                                chat: chat,
                                isCurrentUser: chat.sender.id == getCurrentUserId()
                            )
                            .id(chat.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .onChange(of: circleManager.circleChats.count) { _ in
                    // 新しいメッセージが来たら自動スクロール
                    if let lastMessage = circleManager.circleChats.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // メッセージ入力エリア
            ChatInputView(
                messageText: $messageText,
                showingEmojiPicker: $showingEmojiPicker,
                isTextFieldFocused: $isTextFieldFocused,
                onSend: sendMessage
            )
        }
        .navigationTitle(circle.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadChats()
        }
        .onTapGesture {
            // 画面タップでキーボードを閉じる
            isTextFieldFocused = false
        }
    }
    
    private func loadChats() {
        // 既存のチャットデータをクリア
        circleManager.resetCircleChats()
        
        print("🔄 チャット読み込み開始：circle: \(circle.id)")
        circleManager.loadCircleChats(circleId: circle.id)
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        circleManager.sendMessage(circleId: circle.id, content: content)
        
        messageText = ""
        isTextFieldFocused = false
    }
    
    private func getCurrentUserId() -> String {
        // AuthenticationManagerから現在のユーザーIDを取得
        return AuthenticationManager.shared.getCurrentUserId() ?? "unknown_user_id"
    }
}

// MARK: - Chat Header View
struct ChatHeaderView: View {
    let circle: KnestCircle
    
    var body: some View {
        HStack(spacing: 12) {
            // サークルアイコン
            AsyncImage(url: URL(string: circle.iconUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .overlay(
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.blue)
                    )
            }
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(circle.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(circle.memberCount)人のメンバー")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // アクションボタン
            HStack(spacing: 16) {
                Button {
                    // メンバー一覧表示
                } label: {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                }
                
                Button {
                    // 設定メニュー
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

// MARK: - Chat Message Row View
struct ChatMessageRowView: View {
    let chat: CircleChat
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if !isCurrentUser {
                // 他のユーザーのアバター
                AsyncImage(url: URL(string: chat.sender.avatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(String(chat.sender.displayName.prefix(1)))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                if !isCurrentUser {
                    Text(chat.sender.displayName.isEmpty ? chat.sender.username : chat.sender.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // リプライ表示
                if let replyTo = chat.replyTo {
                    ReplyPreviewView(reply: replyTo)
                }
                
                // メッセージバブル
                HStack {
                    if isCurrentUser {
                        Spacer(minLength: 50)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(chat.content)
                            .font(.body)
                            .foregroundColor(isCurrentUser ? .white : .primary)
                            .multilineTextAlignment(.leading)
                        
                        // メディア表示
                        if !chat.mediaUrls.isEmpty {
                            MediaGridView(mediaUrls: chat.mediaUrls)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isCurrentUser ? Color.blue : Color.gray.opacity(0.1))
                    )
                    
                    if !isCurrentUser {
                        Spacer(minLength: 50)
                    }
                }
                
                // タイムスタンプと既読表示
                HStack(spacing: 4) {
                    Text(formatTime(chat.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if isCurrentUser && !chat.readBy.isEmpty {
                        Text("既読 \(chat.readBy.count)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    
                    if chat.isEdited {
                        Text("編集済み")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if isCurrentUser {
                // 自分のメッセージの時はアバターは右側（または非表示）
                Spacer()
            }
        }
    }
    
    private func formatTime(_ dateString: String) -> String {
        // ISO8601形式の日付文字列を時刻に変換
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else { return "" }
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        return timeFormatter.string(from: date)
    }
}

// MARK: - Reply Preview View
struct ReplyPreviewView: View {
    let reply: ChatReply
    
    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.blue)
                .frame(width: 3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(reply.sender.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Text(reply.content)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Media Grid View
struct MediaGridView: View {
    let mediaUrls: [String]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(Array(mediaUrls.enumerated()), id: \.offset) { index, url in
                AsyncImage(url: URL(string: url)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Chat Input View
struct ChatInputView: View {
    @Binding var messageText: String
    @Binding var showingEmojiPicker: Bool
    @FocusState.Binding var isTextFieldFocused: Bool
    let onSend: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5)
            
            HStack(spacing: 12) {
                // メディア追加ボタン
                Button {
                    // メディア選択機能
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                // テキスト入力フィールド
                HStack(spacing: 8) {
                    TextField("メッセージを入力...", text: $messageText, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .lineLimit(1...5)
                        .focused($isTextFieldFocused)
                    
                    Button {
                        showingEmojiPicker.toggle()
                    } label: {
                        Image(systemName: "face.smiling")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                
                // 送信ボタン
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemBackground))
        }
    }
}

#Preview {
    NavigationView {
        CircleChatView(circle: KnestCircle.sample())
    }
} 