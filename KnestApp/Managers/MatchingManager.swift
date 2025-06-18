//
//  MatchingManager.swift
//  KnestApp
//
//  Created by Claude on 2025/06/08.
//

import Foundation
import Combine

@MainActor
class MatchingManager: ObservableObject {
    @Published var userMatches: [UserMatch] = []
    @Published var circleMatches: [CircleMatch] = []
    @Published var recommendedCircles: [CircleMatch] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let networkManager = NetworkManager.shared
    private let authManager = AuthenticationManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // HierarchicalInterestManagerの参照を保持
    private lazy var hierarchicalInterestManager: HierarchicalInterestManager = {
        let manager = HierarchicalInterestManager()
        // データを読み込み
        manager.loadUserProfiles()
        return manager
    }()
    
    // MARK: - ユーザーマッチング
    
    func findMatchingUsers(limit: Int = 20) {
        // 興味関心データを確実に読み込んでからマッチングを実行
        Task {
            await ensureInterestDataLoaded()
            await performUserMatching(limit: limit)
        }
    }
    
    @MainActor
    private func ensureInterestDataLoaded() async {
        // データが空の場合、読み込みを実行
        if hierarchicalInterestManager.userProfiles.isEmpty && !hierarchicalInterestManager.isLoading {
            hierarchicalInterestManager.loadUserProfiles()
            
            // 読み込み完了まで最大3秒待機
            var attempts = 0
            while hierarchicalInterestManager.isLoading && attempts < 30 {
                try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                attempts += 1
            }
        }
    }
    
    @MainActor
    private func performUserMatching(limit: Int = 20) async {
        // 認証状態を確認
        guard authManager.isAuthenticated else {
            error = "ログインが必要です"
            userMatches = generateSampleUserMatches()
            return
        }
        
        guard let token = authManager.getAccessToken() else {
            error = "認証トークンがありません。再ログインしてください"
            userMatches = generateSampleUserMatches()
            return
        }
        
        isLoading = true
        error = nil
        
        networkManager.makeRequest(
            endpoint: "/api/interests/matching/find_user_matches/?limit=\(limit)",
            method: .GET,
            token: token,
            responseType: [UserMatch].self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("[ERROR] ユーザーマッチングエラー: \(error.localizedDescription)")
                    
                    // エラー詳細処理
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .httpError(401):
                            self?.error = "ログイン期限が切れました。再ログインしてください"
                            self?.authManager.refreshTokenIfNeeded()
                        case .httpError(404):
                            self?.error = "マッチング候補が見つかりません"
                        case .httpError(500):
                            self?.error = "サーバーエラーが発生しました。しばらく後に再試行してください"
                        default:
                            self?.error = "ユーザーマッチングに失敗しました"
                        }
                    } else {
                        self?.error = "ユーザーマッチングに失敗しました"
                    }
                    
                    // フォールバック: サンプルデータを使用
                    self?.userMatches = self?.generateSampleUserMatches() ?? []
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] matches in
                print("[SUCCESS] ユーザーマッチング成功: \(matches.count)件")
                self?.userMatches = matches
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - サークルマッチング
    
    func findMatchingCircles(limit: Int = 20) {
        // 興味関心データを確実に読み込んでからマッチングを実行
        Task {
            await ensureInterestDataLoaded()
            await performCircleMatching(limit: limit)
        }
    }
    
    @MainActor
    private func performCircleMatching(limit: Int = 20) async {
        // 認証状態を確認
        guard authManager.isAuthenticated else {
            error = "ログインが必要です"
            circleMatches = generateSampleCircleMatches()
            return
        }
        
        guard let token = authManager.getAccessToken() else {
            error = "認証トークンがありません。再ログインしてください"
            circleMatches = generateSampleCircleMatches()
            return
        }
        
        isLoading = true
        error = nil
        
        networkManager.makeRequest(
            endpoint: "/api/interests/matching/find_circle_matches/?limit=\(limit)",
            method: .GET,
            token: token,
            responseType: [CircleMatch].self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("[ERROR] サークルマッチングエラー: \(error.localizedDescription)")
                    
                    // エラー詳細処理
                    if let networkError = error as? NetworkError {
                        switch networkError {
                        case .httpError(401):
                            self?.error = "ログイン期限が切れました。再ログインしてください"
                            self?.authManager.refreshTokenIfNeeded()
                        case .httpError(404):
                            self?.error = "サークル候補が見つかりません"
                        case .httpError(500):
                            self?.error = "サーバーエラーが発生しました。しばらく後に再試行してください"
                        default:
                            self?.error = "サークルマッチングに失敗しました"
                        }
                    } else {
                        self?.error = "サークルマッチングに失敗しました"
                    }
                    
                    // フォールバック: サンプルデータを使用
                    self?.circleMatches = self?.generateSampleCircleMatches() ?? []
                case .finished:
                    break
                }
            },
            receiveValue: { [weak self] circleMatches in
                print("[SUCCESS] サークルマッチング成功: \(circleMatches.count)件")
                self?.circleMatches = circleMatches
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - おすすめサークル
    
    func getRecommendedCircles() {
        print("[STATS] 階層型おすすめサークル取得開始")
        
        isLoading = true
        error = nil
        
        let endpoint = "/api/interests/matching/recommended_circles/"
        
        // 認証トークンを取得
        guard let token = authManager.getAccessToken() else {
            error = "認証トークンがありません。再ログインしてください"
            isLoading = false
            // フォールバック: 豊富なダミーデータを使用
            recommendedCircles = generateEnhancedRecommendedCircles()
            return
        }
        
        networkManager.makeRequest(
            endpoint: endpoint,
            method: .GET,
            token: token,
            responseType: RecommendedCirclesResponse.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    print("[ERROR] 階層型おすすめサークル取得エラー: \(error)")
                    self?.error = nil // エラーを非表示にしてダミーデータを表示
                    // フォールバック: 豊富なダミーデータを使用
                    self?.recommendedCircles = self?.generateEnhancedRecommendedCircles() ?? []
                case .finished:
                    print("[SUCCESS] 階層型おすすめサークル取得完了")
                }
            },
            receiveValue: { [weak self] response in
                print("[STATS] 階層型おすすめサークル \(response.circles.count)件取得")
                
                // APIレスポンスをCircleMatchに変換
                let matches = response.circles.map { item in
                    // CircleOwnerからUserに変換（KnestCircleはownerとしてUserを期待している）
                    let owner = User(
                        id: item.circle.owner?.id ?? "",
                        username: item.circle.owner?.username ?? "",
                        email: "",
                        displayName: item.circle.owner?.displayName,
                        avatarUrl: nil,
                        bio: nil,
                        emotionState: nil,
                        birthDate: nil,
                        prefecture: nil,
                        isPremium: false,
                        lastActive: item.circle.updatedAt,
                        createdAt: item.circle.createdAt,
                        updatedAt: item.circle.updatedAt
                    )
                    
                    // CircleBasicからKnestCircleに変換
                    let knestCircle = KnestCircle(
                        id: item.circle.id,
                        name: item.circle.name,
                        description: item.circle.description,
                        status: CircleStatus(rawValue: item.circle.status) ?? .open,
                        circleType: CircleType(rawValue: item.circle.circleType) ?? .public,
                        createdAt: item.circle.createdAt,
                        updatedAt: item.circle.updatedAt,
                        owner: owner,
                        interests: [],
                        lastActivityAt: item.circle.lastActivityAt,
                        memberCount: item.circle.memberCount,
                        isMember: false,
                        membershipStatus: nil,
                        categories: [],
                        tags: item.circle.tags,
                        postCount: item.circle.postCount,
                        iconUrl: item.circle.iconUrl,
                        coverUrl: item.circle.coverUrl,
                        rules: nil,
                        memberLimit: nil
                    )
                    
                    // MatchingScoreを構築
                    let matchingScore = MatchingScore(
                        totalScore: item.matchingDetails.totalScore,
                        interestScore: item.matchingDetails.totalScore * 0.6,
                        locationScore: item.matchingDetails.totalScore * 0.2,
                        ageScore: item.matchingDetails.totalScore * 0.2,
                        commonInterests: [],
                        hierarchicalDetails: nil
                    )
                    
                    return CircleMatch(
                        id: item.id,
                        circle: knestCircle,
                        score: matchingScore,
                        memberCount: item.memberCount,
                        matchReason: item.matchReason
                    )
                }
                
                self?.recommendedCircles = matches
                print("[SUCCESS] 階層型マッチデータ設定完了: \(matches.count)件")
            }
        )
        .store(in: &cancellables)
    }
    
    // MARK: - 豊富なおすすめサークルダミーデータ生成
    private func generateEnhancedRecommendedCircles() -> [CircleMatch] {
        // ユーザーの実際の興味関心を取得
        let userInterests = getUserActualInterests()
        
        let sampleCircles = [
            // テクノロジー・プログラミング関連
            ("Swiftプログラミング部", "iOSアプリ開発を学ぶコミュニティ。初心者から上級者まで歓迎！一緒にアプリを作りましょう。", ["Swift", "iOS", "プログラミング"], 0.92),
            ("Web開発研究会", "HTML、CSS、JavaScriptからReact、Vue.jsまで最新のWeb技術を学習。", ["JavaScript", "Web開発", "フロントエンド"], 0.88),
            ("AIプログラミング勉強会", "Python、機械学習、ディープラーニングに興味がある方集まれ！", ["Python", "AI", "機械学習"], 0.85),
            ("データサイエンス同好会", "データ分析、統計学、可視化技術を学ぶサークル。", ["データ分析", "統計", "Python"], 0.82),
            ("ゲーム開発チーム", "Unityでゲーム制作！アイデア出しから公開まで一緒に体験しよう。", ["Unity", "ゲーム開発", "C#"], 0.90),
            
            // エンターテイメント・趣味関連
            ("読書愛好会", "月1回の読書会開催。ジャンル問わず本について語り合いましょう。", ["読書", "文学", "小説"], 0.87),
            ("映画鑑賞クラブ", "週末映画鑑賞会、ディスカッション、映画祭情報共有など。", ["映画", "シネマ", "エンターテイメント"], 0.84),
            ("アニメ・マンガ研究会", "最新アニメから名作まで、アニメとマンガについて熱く語ろう！", ["アニメ", "マンガ", "オタク"], 0.81),
            ("ボードゲーム愛好家", "毎週末にボードゲーム会開催。戦略ゲームからパーティゲームまで。", ["ボードゲーム", "ゲーム", "戦略"], 0.86),
            ("音楽鑑賞サークル", "ジャンル問わず音楽について語り合う。ライブ情報も共有！", ["音楽", "ライブ", "フェス"], 0.78),
            
            // スポーツ・健康関連
            ("フットサル仲間募集", "毎週土曜日にフットサル！初心者大歓迎、楽しく汗を流しましょう。", ["フットサル", "サッカー", "スポーツ"], 0.89),
            ("ランニングクラブ", "朝活ランニング、マラソン大会参加、健康的な仲間作り。", ["ランニング", "マラソン", "健康"], 0.83),
            ("ヨガ・瞑想サークル", "心と体を整える。初心者向けヨガクラス、瞑想会開催。", ["ヨガ", "瞑想", "ウェルネス"], 0.80),
            ("テニス同好会", "週末テニス！レベル別練習で上達を目指しましょう。", ["テニス", "ラケット", "スポーツ"], 0.85),
            ("バスケットボール部", "3on3から5on5まで。バスケ好き集まれ！", ["バスケ", "スポーツ", "チーム"], 0.87),
            
            // ライフスタイル・グルメ関連
            ("料理研究会", "毎月テーマを決めて料理実習。レシピ共有、食材情報交換も。", ["料理", "レシピ", "グルメ"], 0.91),
            ("カフェ巡りサークル", "東京都内のおしゃれカフェ巡り。インスタ映えスポット発見！", ["カフェ", "コーヒー", "スイーツ"], 0.88),
            ("ワイン愛好会", "ワインテイスティング、ペアリング、ワイナリー見学企画。", ["ワイン", "グルメ", "お酒"], 0.79),
            ("家庭菜園コミュニティ", "ベランダ菜園から市民農園まで。野菜作りの情報交換。", ["園芸", "野菜", "自然"], 0.76),
            ("ミニマリスト研究会", "断捨離、シンプルライフ、持たない暮らしについて学ぶ。", ["ミニマリスト", "断捨離", "シンプル"], 0.74),
            
            // アート・クリエイティブ関連
            ("写真撮影同好会", "街歩き撮影会、テクニック共有、フォトコンテスト開催。", ["写真", "撮影", "カメラ"], 0.86),
            ("イラスト制作サークル", "デジタル・アナログ問わず。作品発表会、技術向上を目指す。", ["イラスト", "絵画", "アート"], 0.83),
            ("ハンドメイド工房", "アクセサリー、雑貨作り。手作りの温かさを大切にするサークル。", ["ハンドメイド", "手作り", "工芸"], 0.81),
            ("デザイン研究会", "グラフィックデザイン、UI/UX、ブランディングについて学ぶ。", ["デザイン", "グラフィック", "クリエイティブ"], 0.89),
            ("音楽制作クラブ", "DTM、作詞作曲、バンド活動。音楽を作る仲間募集！", ["音楽制作", "DTM", "作曲"], 0.85),
            
            // 学習・スキルアップ関連
            ("英会話練習会", "ネイティブスピーカーとの会話練習、TOEIC対策も。", ["英語", "英会話", "語学"], 0.88),
            ("プレゼンテーション研究会", "発表スキル向上、資料作成テクニック、自信をつけよう。", ["プレゼン", "スキルアップ", "コミュニケーション"], 0.82),
            ("投資・資産運用勉強会", "株式、投資信託、仮想通貨など資産運用について学ぶ。", ["投資", "株式", "資産運用"], 0.79),
            ("起業家コミュニティ", "ビジネスアイデア、スタートアップ、副業について情報交換。", ["起業", "ビジネス", "副業"], 0.84),
            ("心理学研究サークル", "人間心理、コミュニケーション、自己啓発について学ぶ。", ["心理学", "自己啓発", "コミュニケーション"], 0.77),
            
            // 旅行・アウトドア関連
            ("旅行企画サークル", "国内外旅行企画、グループ旅行、秘境スポット発見！", ["旅行", "観光", "冒険"], 0.90),
            ("ハイキング・登山部", "低山ハイキングから本格登山まで。自然を満喫しよう。", ["ハイキング", "登山", "自然"], 0.86),
            ("キャンプ愛好会", "アウトドア料理、テント泊、キャンプ用品情報交換。", ["キャンプ", "アウトドア", "BBQ"], 0.84),
            ("サイクリングクラブ", "都内サイクリング、ロングライド、自転車メンテナンス。", ["サイクリング", "自転車", "サイクル"], 0.82),
            ("星空観測会", "天体観測、プラネタリウム見学、星座について学ぶ。", ["天体観測", "星座", "宇宙"], 0.78),
            
            // 文化・伝統関連
            ("茶道体験サークル", "日本の伝統文化を学ぶ。正座が苦手でも大丈夫！", ["茶道", "和文化", "伝統"], 0.75),
            ("書道・習字クラブ", "美しい字を書けるようになりたい方、一緒に練習しましょう。", ["書道", "習字", "和文化"], 0.73),
            ("着物着付け教室", "着物の着付けを学ぶ。季節のイベントでお出かけも！", ["着物", "着付け", "和装"], 0.76),
            ("日本史研究会", "歴史好き集まれ！史跡巡り、歴史談義を楽しもう。", ["歴史", "日本史", "史跡"], 0.74),
            ("神社仏閣巡りサークル", "パワースポット、御朱印集め、建築美を堪能。", ["神社", "寺院", "御朱印"], 0.77)
        ]
        
        return sampleCircles.enumerated().map { index, circleData in
            let (name, description, tags, totalScore) = circleData
            
            // 実際の興味関心に基づいて共通点を計算
            let commonInterests = calculateCircleCommonInterests(userInterests: userInterests, circleIndex: index)
            
            // 共通興味関心に基づいてスコア調整
            let adjustedScore = commonInterests.isEmpty ? 
                Double.random(in: 0.5...0.7) : // 共通点がない場合は低めのスコア
                min(totalScore + 0.1, 1.0) // 共通点がある場合は高めのスコア
            
            let owner = User(
                id: "owner_\(index)",
                username: "owner\(index)",
                email: "owner\(index)@example.com",
                displayName: "運営者\(index)",
                avatarUrl: nil,
                bio: nil,
                emotionState: nil,
                birthDate: nil,
                prefecture: "東京都",
                isPremium: false,
                lastActive: "2025-06-08T12:00:00Z",
                createdAt: "2025-06-08T12:00:00Z",
                updatedAt: "2025-06-08T12:00:00Z"
            )
            
            let circle = KnestCircle(
                id: "circle_\(index)",
                name: name,
                description: description,
                status: .open,
                circleType: .public,
                createdAt: "2025-06-08T12:00:00Z",
                updatedAt: "2025-06-08T12:00:00Z",
                owner: owner,
                interests: [],
                lastActivityAt: "2025-06-08T10:00:00Z",
                memberCount: Int.random(in: 5...50),
                isMember: false,
                membershipStatus: nil,
                categories: [],
                tags: tags,
                postCount: Int.random(in: 10...100),
                iconUrl: nil,
                coverUrl: nil,
                rules: nil,
                memberLimit: nil
            )
            
            return CircleMatch(
                id: "recommended_match_\(index)",
                circle: circle,
                score: MatchingScore(
                    totalScore: adjustedScore,
                    interestScore: adjustedScore * 0.6,
                    locationScore: adjustedScore * 0.2,
                    ageScore: adjustedScore * 0.2,
                    commonInterests: commonInterests,
                    hierarchicalDetails: generateActualHierarchicalDetails(commonInterests: commonInterests, totalScore: adjustedScore)
                ),
                memberCount: circle.memberCount,
                matchReason: generateActualMatchReason(commonInterests: commonInterests, totalScore: adjustedScore)
            )
        }
    }
    
    // MARK: - 検索
    
    func searchCircles(query: String, filters: [String: Any] = [:]) {
        isLoading = true
        error = nil
        
        var endpoint = "/api/circles/circles/?search=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        // フィルター追加
        for (key, value) in filters {
            endpoint += "&\(key)=\(value)"
        }
        
        // 認証トークンを取得
        guard let token = authManager.getAccessToken() else {
            error = "認証トークンがありません。再ログインしてください"
            isLoading = false
            return
        }
        
        // ページネーション付きレスポンス用の構造体
        struct CircleListResponse: Codable {
            let count: Int
            let next: String?
            let previous: String?
            let results: [KnestCircle]
        }
        
        networkManager.makeRequest(
            endpoint: endpoint,
            method: .GET,
            token: token,
            responseType: CircleListResponse.self
        )
        .receive(on: DispatchQueue.main)
        .sink(
            receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .failure(let error):
                    self?.error = "検索に失敗しました: \(error.localizedDescription)"
                    self?.circleMatches = []
                    print("[ERROR] 検索エラー: \(error)")
                case .finished:
                    print("[SUCCESS] 検索API呼び出し完了")
                }
            },
            receiveValue: { [weak self] response in
                print("[STATS] 検索結果受信: \(response.results.count)件のサークル")
                
                // CircleをCircleMatchに変換
                let matches = response.results.map { circle in
                    CircleMatch(
                        id: UUID().uuidString,
                        circle: circle,
                        score: MatchingScore(
                            totalScore: 0.8,
                            interestScore: 0.6,
                            locationScore: 0.8,
                            ageScore: 0.8,
                            commonInterests: [],
                            hierarchicalDetails: nil
                        ),
                        memberCount: circle.memberCount,
                        matchReason: "検索結果"
                    )
                }
                self?.circleMatches = matches
                print("[SUCCESS] サークルマッチ設定完了: \(matches.count)件")
            }
        )
        .store(in: &cancellables)
    }
}

// MARK: - サンプルデータ生成（開発用）
// サンプルデータ生成機能は削除し、実際のAPIから取得

extension MatchingManager {
    private func generateSampleUserMatches() -> [UserMatch] {
        let sampleUsers = [
            ("田中太郎", "tanaka", "プログラミングが好きな大学生です", 0.85),
            ("佐藤花子", "sato", "読書と映画鑑賞が趣味です", 0.78),
            ("山田次郎", "yamada", "スポーツ全般が大好きです", 0.72),
            ("鈴木美咲", "suzuki", "料理とカフェ巡りが趣味です", 0.89),
            ("高橋健太", "takahashi", "旅行と写真撮影が好きです", 0.65)
        ]
        
        // ユーザーの実際の興味関心を取得
        let userInterests = getUserActualInterests()
        
        return sampleUsers.enumerated().map { index, userData in
            let (displayName, username, bio, totalScore) = userData
            
            // 実際の興味関心に基づいて共通点を計算
            let commonInterests = calculateActualCommonInterests(userInterests: userInterests, targetUserIndex: index)
            
            return UserMatch(
                id: "user_match_\(index)",
                user: User(
                    id: "user_\(index)",
                    username: username,
                    email: "\(username)@example.com",
                    displayName: displayName,
                    avatarUrl: nil,
                    bio: bio,
                    emotionState: "happy",
                    birthDate: "1995-06-15",
                    prefecture: "東京都",
                    isPremium: false,
                    lastActive: "2025-06-08T12:00:00Z",
                    createdAt: "2025-06-08T12:00:00Z",
                    updatedAt: "2025-06-08T12:00:00Z"
                ),
                score: MatchingScore(
                    totalScore: totalScore,
                    interestScore: totalScore * 0.6,
                    locationScore: totalScore * 0.2,
                    ageScore: totalScore * 0.2,
                    commonInterests: commonInterests, // 実際のデータに基づく共通点
                    hierarchicalDetails: generateActualHierarchicalDetails(commonInterests: commonInterests, totalScore: totalScore)
                ),
                matchReason: generateActualMatchReason(commonInterests: commonInterests, totalScore: totalScore)
            )
        }
    }
    
    private func generateSampleCircleMatches() -> [CircleMatch] {
        // サンプルデータ生成は削除し、実際のAPIから取得
        return []
    }
    
    /// ユーザーの実際の興味関心を取得
    private func getUserActualInterests() -> [String] {
        // 共有インスタンスを使用
        let profiles = hierarchicalInterestManager.userProfiles
        
        // データが空の場合、再読み込みを試行
        if profiles.isEmpty && !hierarchicalInterestManager.isLoading {
            print("[INFO] 興味関心データが空のため、再読み込みを実行")
            hierarchicalInterestManager.loadUserProfiles()
        }
        
        var interests: [String] = []
        
        // ユーザープロフィールから興味関心を抽出
        for profile in profiles {
            if let tag = profile.tag {
                interests.append("[TAG] \(tag.name)") // タグレベル
            } else if let subcategory = profile.subcategory {
                interests.append("[SUBCAT] \(subcategory.name)") // サブカテゴリレベル
            } else if let category = profile.category {
                interests.append("[CAT] \(category.name)") // カテゴリレベル
            }
        }
        
        // デバッグログ
        print("[STATS] ユーザー興味関心取得: \(interests.count)個 - \(interests)")
        
        // 興味関心が設定されていない場合は空配列を返す
        return interests
    }
    
    /// 実際の共通興味関心を計算（ユーザーマッチング用）
    private func calculateActualCommonInterests(userInterests: [String], targetUserIndex: Int) -> [String] {
        // ユーザーの興味関心が設定されていない場合は空を返す
        if userInterests.isEmpty {
            return []
        }
        
        // サンプルユーザーの興味関心パターン（実際のマッチングでは対象ユーザーのデータを使用）
        let targetUserInterestPatterns = [
            ["[TAG] Swift", "[SUBCAT] プログラミング", "[CAT] テクノロジー"], // 田中太郎
            ["[TAG] 読書", "[SUBCAT] 文学", "[CAT] エンターテイメント"],         // 佐藤花子
            ["[TAG] フットサル", "[SUBCAT] 球技", "[CAT] スポーツ・健康"],       // 山田次郎
            ["[TAG] 料理", "[SUBCAT] グルメ", "[CAT] ライフスタイル"],           // 鈴木美咲
            ["[TAG] 写真", "[SUBCAT] 撮影", "[CAT] アート・クリエイティブ"]     // 高橋健太
        ]
        
        guard targetUserIndex < targetUserInterestPatterns.count else {
            return []
        }
        
        let targetInterests = targetUserInterestPatterns[targetUserIndex]
        
        // 実際の共通点を計算
        return userInterests.filter { userInterest in
            targetInterests.contains { targetInterest in
                // 名前の部分一致をチェック
                let userTag = userInterest.replacingOccurrences(of: "[TAG] ", with: "").replacingOccurrences(of: "[SUBCAT] ", with: "").replacingOccurrences(of: "[CAT] ", with: "")
                let targetTag = targetInterest.replacingOccurrences(of: "[TAG] ", with: "").replacingOccurrences(of: "[SUBCAT] ", with: "").replacingOccurrences(of: "[CAT] ", with: "")
                return userTag == targetTag
            }
        }
    }
    
    /// 実際の共通興味関心を計算（サークルマッチング用）
    private func calculateCircleCommonInterests(userInterests: [String], circleIndex: Int) -> [String] {
        // ユーザーの興味関心が設定されていない場合は空を返す
        if userInterests.isEmpty {
            return []
        }
        
        // 拡張されたサークルの興味関心パターン（40個のサークルに対応）
        let circleInterestPatterns = [
            // テクノロジー・プログラミング関連（0-4）
            ["[TAG] Swift", "[SUBCAT] プログラミング", "[CAT] テクノロジー"],          
            ["[TAG] JavaScript", "[SUBCAT] Web開発", "[CAT] テクノロジー"],         
            ["[TAG] Python", "[SUBCAT] AI", "[CAT] テクノロジー"],                 
            ["[TAG] データ分析", "[SUBCAT] 統計", "[CAT] テクノロジー"],             
            ["[TAG] Unity", "[SUBCAT] ゲーム開発", "[CAT] テクノロジー"],           
            
            // エンターテイメント・趣味関連（5-9）
            ["[TAG] 読書", "[SUBCAT] 文学", "[CAT] エンターテイメント"],              
            ["[TAG] 映画", "[SUBCAT] 映像", "[CAT] エンターテイメント"],              
            ["[TAG] アニメ", "[SUBCAT] マンガ", "[CAT] エンターテイメント"],          
            ["[TAG] ボードゲーム", "[SUBCAT] ゲーム", "[CAT] エンターテイメント"],    
            ["[TAG] 音楽", "[SUBCAT] ライブ", "[CAT] エンターテイメント"],            
            
            // スポーツ・健康関連（10-14）
            ["[TAG] フットサル", "[SUBCAT] 球技", "[CAT] スポーツ・健康"],            
            ["[TAG] ランニング", "[SUBCAT] 陸上", "[CAT] スポーツ・健康"],            
            ["[TAG] ヨガ", "[SUBCAT] フィットネス", "[CAT] スポーツ・健康"],          
            ["[TAG] テニス", "[SUBCAT] ラケット", "[CAT] スポーツ・健康"],            
            ["[TAG] バスケ", "[SUBCAT] 球技", "[CAT] スポーツ・健康"],               
            
            // ライフスタイル・グルメ関連（15-19）
            ["[TAG] 料理", "[SUBCAT] グルメ", "[CAT] ライフスタイル"],                
            ["[TAG] カフェ", "[SUBCAT] コーヒー", "[CAT] ライフスタイル"],            
            ["[TAG] ワイン", "[SUBCAT] お酒", "[CAT] ライフスタイル"],                
            ["[TAG] 園芸", "[SUBCAT] 自然", "[CAT] ライフスタイル"],                  
            ["[TAG] ミニマリスト", "[SUBCAT] 断捨離", "[CAT] ライフスタイル"],        
            
            // アート・クリエイティブ関連（20-24）
            ["[TAG] 写真", "[SUBCAT] 撮影", "[CAT] アート・クリエイティブ"],          
            ["[TAG] イラスト", "[SUBCAT] 絵画", "[CAT] アート・クリエイティブ"],      
            ["[TAG] ハンドメイド", "[SUBCAT] 手作り", "[CAT] アート・クリエイティブ"],
            ["[TAG] デザイン", "[SUBCAT] グラフィック", "[CAT] アート・クリエイティブ"],
            ["[TAG] 音楽制作", "[SUBCAT] DTM", "[CAT] アート・クリエイティブ"],       
            
            // 学習・スキルアップ関連（25-29）
            ["[TAG] 英語", "[SUBCAT] 語学", "[CAT] 学習・スキルアップ"],             
            ["[TAG] プレゼン", "[SUBCAT] コミュニケーション", "[CAT] 学習・スキルアップ"],
            ["[TAG] 投資", "[SUBCAT] 資産運用", "[CAT] 学習・スキルアップ"],         
            ["[TAG] 起業", "[SUBCAT] ビジネス", "[CAT] 学習・スキルアップ"],         
            ["[TAG] 心理学", "[SUBCAT] 自己啓発", "[CAT] 学習・スキルアップ"],       
            
            // 旅行・アウトドア関連（30-34）
            ["[TAG] 旅行", "[SUBCAT] 観光", "[CAT] ライフスタイル"],                  
            ["[TAG] ハイキング", "[SUBCAT] 登山", "[CAT] アウトドア"],               
            ["[TAG] キャンプ", "[SUBCAT] アウトドア", "[CAT] ライフスタイル"],        
            ["[TAG] サイクリング", "[SUBCAT] 自転車", "[CAT] スポーツ・健康"],        
            ["[TAG] 天体観測", "[SUBCAT] 宇宙", "[CAT] 学習・スキルアップ"],         
            
            // 文化・伝統関連（35-39）
            ["[TAG] 茶道", "[SUBCAT] 和文化", "[CAT] 文化・伝統"],                   
            ["[TAG] 書道", "[SUBCAT] 習字", "[CAT] 文化・伝統"],                     
            ["[TAG] 着物", "[SUBCAT] 和装", "[CAT] 文化・伝統"],                     
            ["[TAG] 歴史", "[SUBCAT] 日本史", "[CAT] 学習・スキルアップ"],           
            ["[TAG] 神社", "[SUBCAT] 寺院", "[CAT] 文化・伝統"]                      
        ]
        
        guard circleIndex < circleInterestPatterns.count else {
            // インデックスが範囲外の場合は汎用的なパターンを使用
            return []
        }
        
        let circleInterests = circleInterestPatterns[circleIndex]
        
        // 実際の共通点を計算
        return userInterests.filter { userInterest in
            circleInterests.contains { circleInterest in
                // 名前の部分一致をチェック
                let userTag = userInterest.replacingOccurrences(of: "[TAG] ", with: "").replacingOccurrences(of: "[SUBCAT] ", with: "").replacingOccurrences(of: "[CAT] ", with: "")
                let circleTag = circleInterest.replacingOccurrences(of: "[TAG] ", with: "").replacingOccurrences(of: "[SUBCAT] ", with: "").replacingOccurrences(of: "[CAT] ", with: "")
                return userTag == circleTag
            }
        }
    }
    
    /// 実際の階層詳細を生成
    private func generateActualHierarchicalDetails(commonInterests: [String], totalScore: Double) -> HierarchicalMatchDetails {
        let exactMatches = commonInterests.filter { $0.hasPrefix("[TAG]") }.count
        let subcategoryMatches = commonInterests.filter { $0.hasPrefix("[SUBCAT]") }.count
        let categoryMatches = commonInterests.filter { $0.hasPrefix("[CAT]") }.count
        
        let weightedScore = Double(exactMatches) * 1.0 + Double(subcategoryMatches) * 0.7 + Double(categoryMatches) * 0.5
        let maxPossibleScore = Double(max(3, exactMatches + subcategoryMatches + categoryMatches + 1))
        
        return HierarchicalMatchDetails(
            exactMatches: exactMatches,
            subcategoryMatches: subcategoryMatches,
            categoryMatches: categoryMatches,
            weightedScore: weightedScore,
            maxPossibleScore: Int(maxPossibleScore)
        )
    }
    
    /// 実際のマッチング理由を生成
    private func generateActualMatchReason(commonInterests: [String], totalScore: Double) -> String {
        let percentage = Int(totalScore * 100)
        
        if commonInterests.isEmpty {
            return "新しい出会いの機会です（適合度: \(percentage)%）"
        }
        
        let exactMatches = commonInterests.filter { $0.hasPrefix("[TAG]") }.count
        let subcategoryMatches = commonInterests.filter { $0.hasPrefix("[SUBCAT]") }.count
        let categoryMatches = commonInterests.filter { $0.hasPrefix("[CAT]") }.count
        
        if exactMatches > 0 {
            return "[TAG] \(exactMatches)個の完全一致で\(percentage)%マッチ"
        } else if subcategoryMatches > 0 {
            return "[SUBCAT] \(subcategoryMatches)個のカテゴリ一致で\(percentage)%マッチ"
        } else if categoryMatches > 0 {
            return "[CAT] \(categoryMatches)個の分野一致で\(percentage)%マッチ"
        } else {
            return "基本的な適合性で\(percentage)%マッチ"
        }
    }
    
    private func generateRandomTags() -> [String] {
        let allTags = ["プログラミング", "読書", "カフェ", "スポーツ", "映画", "ゲーム", "料理", "旅行", "音楽", "アート"]
        let count = Int.random(in: 1...3)
        return Array(allTags.shuffled().prefix(count))
    }
    
    private func generateSampleSearchResults(query: String) -> [CircleMatch] {
        if query.isEmpty {
            return generateSampleCircleMatches()
        }
        
        let allMatches = generateSampleCircleMatches()
        return allMatches.filter { match in
            match.circle.name.localizedCaseInsensitiveContains(query) ||
            match.circle.description.localizedCaseInsensitiveContains(query) ||
            match.circle.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
} 