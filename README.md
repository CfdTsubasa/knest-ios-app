# Knest iOS App

## 📖 概要
Knestは趣味・興味関心に基づいたサークル発見・参加プラットフォームのiOSアプリケーションです。

## 🚀 技術スタック
- **Platform**: iOS 15.0+
- **Language**: Swift 5.7
- **UI Framework**: SwiftUI
- **Architecture**: MVVM
- **Network**: URLSession + Combine
- **Dependencies**: Native iOS frameworks

## 🎯 主要機能
- **認証**: JWT認証によるログイン・ログアウト
- **サークル発見**: 興味関心に基づいたサークル検索・推薦
- **リアルタイムチャット**: 美しいチャットUI、メッセージ履歴、リプライ機能
- **プロフィール管理**: ユーザー情報、興味関心設定
- **階層的興味選択**: 3階層（カテゴリ→サブカテゴリ→タグ）による詳細な興味設定
- **マッチングシステム**: ユーザー・サークル推薦機能

## 🛠️ セットアップ

### 前提条件
- Xcode 14.0+
- iOS 15.0+
- macOS 12.0+

### インストール
```bash
# リポジトリクローン
git clone https://github.com/your-username/knest-ios-app.git
cd knest-ios-app

# Xcodeでプロジェクトを開く
open KnestApp.xcodeproj
```

### バックエンドAPIサーバー
iOSアプリを動作させるには、バックエンドAPIサーバーが必要です：
```bash
# 別ターミナルでバックエンドサーバーを起動
git clone https://github.com/your-username/knest-backend.git
cd knest-backend
python manage.py runserver 8000
```

## 🏗️ アーキテクチャ

### ディレクトリ構成
```
KnestApp/
├── Views/                     # SwiftUI画面
│   ├── MainTabView.swift     # メインタブビュー
│   ├── CircleChatView.swift  # チャット画面
│   ├── CirclesView.swift     # サークル一覧
│   ├── SearchView.swift      # 検索・推薦画面
│   └── ProfileView.swift     # プロフィール画面
├── Managers/                  # データ管理
│   ├── NetworkManager.swift  # API通信
│   ├── AuthenticationManager.swift # 認証管理
│   ├── CircleManager.swift   # サークル管理
│   └── MatchingManager.swift # マッチング管理
├── Models/                    # データモデル
│   ├── User.swift
│   ├── Circle.swift
│   └── HierarchicalInterest.swift
└── Components/                # 再利用可能コンポーネント
    ├── ChatMessageRow.swift
    ├── CircleCard.swift
    └── InterestChip.swift
```

### 主要画面
1. **MainTabView**: タブベースナビゲーション
2. **CirclesView**: サークル一覧・検索
3. **CircleChatView**: リアルタイムチャット
4. **SearchView**: 3モード検索（能動・受動・創出）
5. **ProfileView**: ユーザープロフィール・興味設定

## 🎨 UI/UXの特徴

### デザインシステム
- **モダンカードベースデザイン**: 美しいカードレイアウト
- **スムーズアニメーション**: 0.3秒トランジション
- **直感的ナビゲーション**: タブベース + モーダル遷移
- **マッチング可視化**: プログレスバー、パーセンテージ表示

### チャット機能
- **リッチメッセージバブル**: ユーザーアバター、タイムスタンプ
- **リプライ機能**: インライン返信プレビュー
- **既読表示**: メッセージ既読状態
- **自動スクロール**: 新着メッセージ自動スクロール

## 📱 主要機能詳細

### 1. 認証システム
- JWT トークンベース認証
- 自動トークンリフレッシュ
- 永続化ログイン状態

### 2. サークル機能
- サークル作成・参加・退会
- 興味関心によるフィルタリング
- メンバー数・ステータス表示

### 3. チャット機能
- リアルタイムメッセージング
- メッセージ履歴ページネーション
- リプライ・メンション機能

### 4. 検索・推薦システム
- **能動モード**: キーワード検索、フィルター
- **受動モード**: AIベース推薦
- **創出モード**: 新サークル設立提案

## 🔧 開発・デバッグ

### ログ出力
アプリは詳細なデバッグログを出力します：
```
🚀 チャットAPIリクエスト開始
🎯 APIレスポンス受信：results数 = 8
✅ チャット取得成功：8件のメッセージ
📤 メッセージ送信開始：Hello
✅ メッセージ送信成功：Hello
```

### API接続設定
`NetworkManager.swift`でAPIベースURLを設定：
```swift
let baseURL = "http://127.0.0.1:8000/api"  // ローカル開発
// let baseURL = "https://api.knest.com/api"  // 本番環境
```

## 🧪 テスト

### 動作確認
1. **認証テスト**: ログイン・ログアウト
2. **サークル機能**: 一覧表示・参加・退会
3. **チャット機能**: メッセージ送受信・表示順序
4. **検索機能**: キーワード検索・フィルター

### テストユーザー
```
Username: testuser
Password: testpass123
```

## 🌐 関連リポジトリ
- **バックエンドAPI**: [knest-backend](https://github.com/your-username/knest-backend)
- **ドキュメント**: [knest-docs](https://github.com/your-username/knest-docs)

## 🤝 コントリビューション
プルリクエストやIssueの作成を歓迎します。

### 開発ガイドライン
- SwiftUIベストプラクティスに従う
- @MainActorを適切に使用
- Combineフレームワークで非同期処理
- デバッグログを適切に実装

## 📝 開発履歴
詳細な開発履歴は `docs/development_session_2025-01-27.md` を参照してください。

## 📄 ライセンス
このプロジェクトはMITライセンスの下で公開されています。 