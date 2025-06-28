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
    @State private var showingErrorAlert = false
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedTab: Int
    
    init(circle: KnestCircle, circleManager: CircleManager = CircleManager.shared, selectedTab: Binding<Int> = .constant(0)) {
        self.circle = circle
        self.circleManager = circleManager
        self._selectedTab = selectedTab
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            headerView
            
            // メッセージリスト
            messageListView
            
            // 入力エリア
            inputView
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.all) // フルスクリーン
        .onAppear {
            circleManager.loadCircleChats(circleId: circle.id)
        }
        .alert("エラー", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(circleManager.errorMessage ?? "不明なエラーが発生しました")
        }
        .sheet(isPresented: $showingEmojiPicker) {
            Text("絵文字ピッカー（未実装）")
                .presentationDetents([.medium])
        }
    }
    
    private var headerView: some View {
        HStack {
            Button("戻る") {
                dismiss()
            }
            
            Spacer()
            
            VStack {
                Text(circle.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("\(circle.memberCount)人のメンバー")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                // 検索画面に戻る
                selectedTab = 1
                dismiss()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.top, 50) // ステータスバー分のパディング
        .padding(.bottom, 12)
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // ページネーション用のローディングインジケーター
                    if circleManager.isLoadingMoreChats {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("読み込み中...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                    }
                    
                    // メッセージリスト
                    ForEach(circleManager.circleChats) { chat in
                        ChatMessageRow(
                            chat: chat,
                            isCurrentUser: chat.sender.username == AuthenticationManager.shared.currentUser?.username
                        )
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .id(chat.id) // IDを追加してスクロール対象にする
                        .onAppear {
                            // 最初のメッセージが表示されたら次のページを読み込み
                            if chat.id == circleManager.circleChats.first?.id {
                                loadMoreMessages()
                            }
                        }
                    }
                }
            }
            .onChange(of: circleManager.circleChats.count) {
                // 新しいメッセージが追加されたら最下部にスクロール
                if let lastMessage = circleManager.circleChats.last {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    private var inputView: some View {
        ChatInputView(
            messageText: $messageText,
            showingEmojiPicker: $showingEmojiPicker,
            isTextFieldFocused: $isTextFieldFocused,
            onSend: sendMessage
        )
    }
    
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // メッセージを送信
        circleManager.sendMessage(circleId: circle.id, content: content)
        
        // 入力フィールドをクリア
        messageText = ""
        isTextFieldFocused = false
        
        print("📤 メッセージ送信処理完了: \(content)")
    }
    
    private func loadMoreMessages() {
        // CircleManagerのページネーション機能を使用
        circleManager.loadMoreCircleChats(circleId: circle.id)
        print("📄 次のページを読み込み中...")
    }
    
    private func getCurrentUserId() -> String {
        // AuthenticationManagerから現在のユーザーIDを取得
        return AuthenticationManager.shared.getCurrentUserId() ?? "unknown_user_id"
    }
}

// MARK: - Chat Message Row View
struct ChatMessageRow: View {
    let chat: CircleChat
    let isCurrentUser: Bool
    
    // 自分以外の既読者数を計算
    private var othersReadCount: Int {
        guard let currentUser = AuthenticationManager.shared.currentUser else {
            return chat.readBy.count
        }
        return chat.readBy.filter { $0.username != currentUser.username }.count
    }
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(chat.content)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    
                    HStack(spacing: 4) {
                        Text(formatTime(chat.createdAt))
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        // 自分以外の既読者がいる場合のみ表示
                        if othersReadCount > 0 {
                            Text("既読 \(othersReadCount)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        AsyncImage(url: URL(string: chat.sender.avatarUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            SwiftUI.Circle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(SwiftUI.Circle())
                        
                        Text(chat.sender.displayName ?? chat.sender.username)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Text(chat.content)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                    
                    Text(formatTime(chat.createdAt))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
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
                Text(reply.sender.displayName ?? "Unknown")
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
            .padding(.bottom, 83) // タブバー分のパディングを増加（34 + 49 = 83）
            .background(Color(UIColor.systemBackground))
        }
    }
}

#Preview {
    NavigationView {
        CircleChatView(circle: KnestCircle.sample())
    }
} 