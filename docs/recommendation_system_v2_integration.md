# 次世代推薦システム v2 - iOS統合ドキュメント

## 概要

iOS Swiftアプリで次世代推薦システム v2 を活用するための統合ガイドです。

## 主要コンポーネント

### 1. データモデル

#### NextGenRecommendationResponse
推薦APIレスポンスの完全な構造体

```swift
struct NextGenRecommendationResponse: Codable {
    let recommendations: [NextGenRecommendation]
    let algorithmUsed: String
    let algorithmWeights: AlgorithmWeights
    let count: Int
    let totalCandidates: Int
    let computationTimeMs: Double
    let sessionId: String
    let generatedAt: String
}
```

#### NextGenRecommendation  
個別推薦アイテム（推薦理由・信頼度含む）

```swift
struct NextGenRecommendation: Codable, Identifiable {
    let circle: KnestCircle
    let score: Double
    let reasons: [RecommendationReason]
    let confidence: Double
    let sessionId: String
}
```

#### フィードバック機能
```swift
enum FeedbackType: String, CaseIterable {
    case view, click, joinRequest, joinSuccess
    case dismiss, notInterested, bookmark, share
}
```

### 2. ネットワーク層

#### NetworkManager拡張

新しいv2 APIエンドポイント：

```swift
// 推薦取得
func getRecommendationsV2(
    token: String,
    algorithm: String = "smart",
    limit: Int = 10,
    diversityFactor: Double = 0.3,
    excludeCategories: [String] = [],
    includeNewCircles: Bool = true
) -> AnyPublisher<NextGenRecommendationResponse, Error>

// フィードバック送信
func sendRecommendationFeedback(
    token: String, 
    feedback: RecommendationFeedback
) -> AnyPublisher<EmptyResponse, Error>

// ユーザー設定取得
func getUserPreferences(token: String) -> AnyPublisher<UserPreferences, Error>
```

### 3. 推薦マネージャー

#### RecommendationManager
次世代推薦システム専用のマネージャークラス

```swift
class RecommendationManager: ObservableObject {
    static let shared = RecommendationManager()
    
    @Published var recommendations: [NextGenRecommendation] = []
    @Published var currentSession: NextGenRecommendationResponse?
    @Published var userPreferences: UserPreferences?
    
    // 設定
    @Published var selectedAlgorithm: String = "smart"
    @Published var recommendationLimit: Int = 10
    @Published var diversityFactor: Double = 0.3
}
```

### 4. UI コンポーネント

#### 新しい推薦表示
- `NextGenRecommendationsListView`: v2推薦リスト表示
- `NextGenRecommendationRowView`: 個別推薦アイテム（理由・スコア表示）
- `RecommendationSettingsView`: 推薦設定画面
- `RecommendationReasonsView`: 詳細理由表示

#### 従来との並行表示  
- `useNextGenEngine`フラグで新旧システム切り替え
- フォールバック機能で安全性確保

## 使用方法

### 1. 基本的な推薦取得

```swift
@StateObject private var recommendationManager = RecommendationManager.shared

// 推薦を取得
recommendationManager.loadRecommendations()

// 特定アルゴリズムで取得
recommendationManager.loadRecommendations(algorithm: "collaborative")

// カスタム設定で取得
recommendationManager.loadRecommendations(
    algorithm: "smart",
    limit: 15,
    diversityFactor: 0.5,
    excludeCategories: ["sports"]
)
```

### 2. フィードバック追跡

```swift
// サークル詳細表示時
recommendationManager.trackCircleView(for: circle)

// サークルクリック時
recommendationManager.trackCircleClick(for: circle)

// 参加申請時
recommendationManager.trackJoinRequest(for: circle)

// 参加成功時
recommendationManager.trackJoinSuccess(for: circle)

// 推薦却下時
recommendationManager.dismissRecommendation(for: circle)
```

### 3. ユーザー設定の取得・活用

```swift
// ユーザー設定を取得
recommendationManager.loadUserPreferences()

// 学習パターンを確認
if let preferences = recommendationManager.userPreferences {
    let isNewUser = preferences.userProfile.isNewUser
    let preferredCategories = preferences.learningPatterns.preferredCategories
    let algorithmWeights = preferences.algorithmWeights
}
```

### 4. 推薦設定のカスタマイズ

```swift
// アルゴリズム選択
recommendationManager.selectedAlgorithm = "behavioral"

// 表示件数調整  
recommendationManager.recommendationLimit = 20

// 多様性係数調整（0.0=類似性重視, 1.0=多様性重視）
recommendationManager.diversityFactor = 0.7

// 設定保存
recommendationManager.saveSettings()
```

## UI統合例

### 推薦リスト表示

```swift
struct RecommendedCirclesView: View {
    @EnvironmentObject var recommendationManager: RecommendationManager
    
    var body: some View {
        List(recommendationManager.recommendations) { recommendation in
            NavigationLink(
                destination: CircleDetailView(circle: recommendation.circle)
                    .onAppear {
                        recommendationManager.trackCircleView(for: recommendation.circle)
                    }
            ) {
                NextGenRecommendationRowView(recommendation: recommendation)
            }
            .onTapGesture {
                recommendationManager.trackCircleClick(for: recommendation.circle)
            }
        }
        .onAppear {
            recommendationManager.loadRecommendations()
        }
        .refreshable {
            recommendationManager.loadRecommendations()
        }
    }
}
```

### 推薦アイテム表示

```swift
struct NextGenRecommendationRowView: View {
    let recommendation: NextGenRecommendation
    
    var body: some View {
        VStack(alignment: .leading) {
            // サークル基本情報
            HStack {
                Text(recommendation.circle.name)
                    .font(.headline)
                
                Spacer()
                
                // スコア表示
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                    Text(String(format: "%.1f", recommendation.score))
                        .fontWeight(.medium)
                }
            }
            
            // 推薦理由（最大2つ）
            ForEach(Array(recommendation.reasons.prefix(2)), id: \.type) { reason in
                HStack {
                    Image(systemName: reasonIcon(for: reason.type))
                        .foregroundColor(.blue)
                    
                    Text(reason.detail)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(String(format: "%.0f%%", reason.weight * 100))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // 信頼度表示
            Text("信頼度: \(Int(recommendation.confidence * 100))%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
```

## パフォーマンス最適化

### 1. キャッシング活用
```swift
// NetworkManagerで自動キャッシング実装済み
// - ユーザー類似度: 30分キャッシュ
// - 推薦結果: 1時間キャッシュ
```

### 2. 非同期処理
```swift
// フィードバック送信は非同期で実行
// UIをブロックしない設計
```

### 3. 設定永続化
```swift
// UserDefaultsで設定自動保存
recommendationManager.saveSettings()
recommendationManager.loadSettings()
```

## エラーハンドリング

### 1. ネットワークエラー
```swift
@Published var errorMessage: String?

// エラーメッセージを表示
if let error = recommendationManager.errorMessage {
    Text("エラー: \(error)")
        .foregroundColor(.red)
}
```

### 2. フォールバック機能  
```swift
// v2 APIエラー時は従来システムに自動切り替え
if useNextGenEngine && recommendationManager.recommendations.isEmpty {
    LegacyRecommendationsView(circleManager: circleManager)
}
```

## モニタリング・デバッグ

### 1. ログ出力
```swift
// 推薦取得成功
print("✅ 推薦取得成功: \(response.recommendations.count)件")
print("📊 アルゴリズム: \(response.algorithmUsed)")
print("⏱️ 計算時間: \(response.computationTimeMs)ms")

// フィードバック送信
print("✅ フィードバック送信成功: \(feedbackType.displayName)")
```

### 2. セッション統計
```swift
if let stats = recommendationManager.getSessionStats() {
    print("📈 セッション統計:")
    print("  閲覧: \(stats.viewed)件")
    print("  クリック: \(stats.clicked)件") 
    print("  却下: \(stats.dismissed)件")
}
```

## ベストプラクティス

### 1. フィードバック追跡
- すべてのユーザーアクションを確実に追跡
- `onAppear`, `onTapGesture`を活用
- 推薦外のサークルは追跡しない（推薦との関連チェック）

### 2. UI/UX配慮
- 推薦理由を可視化して透明性確保
- ローディング状態を適切に表示
- エラー時のフォールバック表示

### 3. 設定管理
- ユーザー設定をローカルに永続化
- アプリ起動時に自動読み込み
- 設定変更時は即座に反映

### 4. 学習データ活用
- ユーザープロファイルに基づくUI調整
- 学習パターンの可視化
- アルゴリズム重みの表示

## 今後の拡張計画

### 1. リアルタイム推薦
- WebSocket経由での即座推薦更新
- ユーザー行動に基づく動的調整

### 2. 高度なUI
- 推薦理由のビジュアル化
- インタラクティブな設定画面
- A/Bテスト結果の表示

### 3. オフライン対応
- 推薦結果のローカルキャッシュ
- オフライン時のフォールバック表示 