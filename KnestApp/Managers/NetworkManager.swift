//
//  NetworkManager.swift
//  KnestApp
//
//  Created by t.i on 2025/06/07.
//

import Foundation
import Combine

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let baseURL = URL(string: "http://127.0.0.1:8000")!
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Private Helper Methods
    
    public func makeRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        token: String? = nil,
        responseType: T.Type
    ) -> AnyPublisher<T, Error> {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
            print("[ERROR] 無効なURL: \(baseURL)\(endpoint)")
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            print("[DEBUG] 認証トークン: \(token)")
        }
        
        if let body = body {
            request.httpBody = body
            // リクエストボディのデバッグログ
            if let jsonString = String(data: body, encoding: .utf8) {
                print("[DEBUG] リクエストボディ: \(jsonString)")
            }
        }
        
        // デバッグログ
        print("[HTTP] HTTP \(method.rawValue) \(url.absoluteString)")
        if token != nil { print("[AUTH] 認証ありリクエスト") }
        
        // JSONDecoderのセットアップ
        let decoder = JSONDecoder()
        
        // カスタム日付デコーディング戦略
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // 複数の日付フォーマットを試行
            let formatters: [DateFormatter] = [
                {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXX"
                    f.locale = Locale(identifier: "en_US_POSIX")
                    f.timeZone = TimeZone(secondsFromGMT: 0)
                    return f
                }(),
                {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"
                    f.locale = Locale(identifier: "en_US_POSIX")
                    f.timeZone = TimeZone(secondsFromGMT: 0)
                    return f
                }(),
                {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXX"
                    f.locale = Locale(identifier: "en_US_POSIX")
                    f.timeZone = TimeZone(secondsFromGMT: 0)
                    return f
                }(),
                {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    f.locale = Locale(identifier: "en_US_POSIX")
                    f.timeZone = TimeZone(secondsFromGMT: 0)
                    return f
                }()
            ]
            
            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    print("[SUCCESS] 日付デコード成功: \(dateString) -> \(date)")
                    return date
                }
            }
            
            print("[ERROR] 日付デコード失敗: \(dateString)")
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("[ERROR] 無効なレスポンス: \(response)")
                    throw NetworkError.invalidResponse
                }
                
                // レスポンスの詳細ログ
                print("[RESPONSE] レスポンス: \(httpResponse.statusCode) - \(url.absoluteString)")
                print("[STATS] データサイズ: \(data.count)バイト")
                
                // レスポンスボディのデバッグログ
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("[DEBUG] レスポンスボディ: \(jsonString)")
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    // エラーレスポンスの詳細を解析
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("[ERROR] エラーレスポンス: \(errorString)")
                        
                        // JSONエラーレスポンスから詳細メッセージを取得
                        if let errorData = errorString.data(using: .utf8),
                           let errorJSON = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any],
                           let detailMessage = errorJSON["detail"] as? String {
                            print("[ERROR] エラー詳細: \(detailMessage)")
                            throw NetworkError.serverError(detailMessage)
                        }
                    }
                    print("[ERROR] HTTPエラー: \(httpResponse.statusCode)")
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: responseType, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Authentication
    
    func login(username: String, password: String) -> AnyPublisher<LoginResponse, Error> {
        let loginRequest = LoginRequest(username: username, password: password)
        
        guard let body = try? JSONEncoder().encode(loginRequest) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/api/users/auth/token/",
            method: .POST,
            body: body,
            responseType: LoginResponse.self
        )
    }
    
    func register(request: RegisterRequest) -> AnyPublisher<LoginResponse, Error> {
        guard let body = try? JSONEncoder().encode(request) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/api/users/auth/register/",
            method: .POST,
            body: body,
            responseType: LoginResponse.self
        )
    }
    
    func refreshToken(refreshToken: String) -> AnyPublisher<TokenRefreshResponse, Error> {
        let request = TokenRefreshRequest(refresh: refreshToken)
        
        guard let body = try? JSONEncoder().encode(request) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/api/users/auth/token/refresh/",
            method: .POST,
            body: body,
            responseType: TokenRefreshResponse.self
        )
    }
    
    // MARK: - User Profile
    
    func getUserProfile(token: String) -> AnyPublisher<User, Error> {
        return makeRequest(
            endpoint: "/api/users/me/",
            token: token,
            responseType: User.self
        )
    }
    
    // MARK: - Circle API
    func getCircles(token: String, page: Int = 1, search: String? = nil, category: String? = nil) -> AnyPublisher<CircleResponse, Error> {
        var endpoint = "/api/circles/circles/?page=\(page)"
        
        if let search = search, !search.isEmpty {
            endpoint += "&search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        if let category = category, !category.isEmpty {
            endpoint += "&category=\(category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        return makeRequest(
            endpoint: endpoint,
            token: token,
            responseType: CircleResponse.self
        )
    }
    
    func getCircleDetail(token: String, circleId: String) -> AnyPublisher<KnestCircle, Error> {
        print("[INFO] NetworkManager.getCircleDetail 呼び出し")
        print("   サークルID: \(circleId)")
        print("   URL: /api/circles/circles/\(circleId)/")
        
        return makeRequest(
            endpoint: "/api/circles/circles/\(circleId)/",
            token: token,
            responseType: KnestCircle.self
        )
    }
    
    func joinCircle(token: String, circleId: String, request: JoinCircleRequest) -> AnyPublisher<JoinCircleResponse, Error> {
        print("[DEBUG] デバッグ - joinCircle開始")
        print("   circleId: '\(circleId)'")
        print("   baseURL: '\(baseURL)'")
        print("   request: \(request)")
        
        let endpoint = "/api/circles/circles/\(circleId)/join/"
        print("   endpoint: '\(endpoint)'")
        
        let fullURL = "\(baseURL)\(endpoint)"
        print("   fullURL: '\(fullURL)'")
        
        // URLの妥当性を確認
        guard let url = URL(string: fullURL) else {
            print("[ERROR] 無効なURL: '\(fullURL)'")
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        print("[SUCCESS] 有効なURL生成成功: '\(url.absoluteString)'")
        
        guard let body = try? JSONEncoder().encode(request) else {
            print("[ERROR] エンコーディングエラー")
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: endpoint,
            method: .POST,
            body: body,
            token: token,
            responseType: JoinCircleResponse.self
        )
        .handleEvents(
            receiveOutput: { response in
                print("[SUCCESS] NetworkManager.joinCircle 成功")
                print("   レスポンス: \(response)")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("[ERROR] NetworkManager.joinCircle 失敗")
                    print("   エラー: \(error)")
                    print("   詳細: \(error.localizedDescription)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    func getMyCircles(token: String) -> AnyPublisher<[KnestCircle], Error> {
        return makeRequest(
            endpoint: "/api/circles/circles/my/",
            token: token,
            responseType: CircleResponse.self
        )
        .map { $0.results }
        .eraseToAnyPublisher()
    }
    
    func getRecommendedCircles(token: String) -> AnyPublisher<[KnestCircle], Error> {
        return makeRequest(
            endpoint: "/api/circles/circles/recommended/",
            token: token,
            responseType: CircleResponse.self
        )
        .map { $0.results }
        .eraseToAnyPublisher()
    }
    
    func createCircle(token: String, request: CreateCircleRequest) -> AnyPublisher<KnestCircle, Error> {
        guard let body = try? JSONEncoder().encode(request) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/api/circles/circles/",
            method: .POST,
            body: body,
            token: token,
            responseType: KnestCircle.self
        )
    }
    
    func leaveCircle(token: String, circleId: String) -> AnyPublisher<EmptyResponse, Error> {
        return makeRequest(
            endpoint: "/api/circles/circles/\(circleId)/leave/",
            method: .POST,
            token: token,
            responseType: EmptyResponse.self
        )
    }
    
    func getCircleChats(token: String, circleId: String, page: Int = 1) -> AnyPublisher<PagedResponse<CircleChat>, Error> {
        return makeRequest(
            endpoint: "/api/circles/chats/?circle=\(circleId)&page=\(page)",
            token: token,
            responseType: PagedResponse<CircleChat>.self
        )
    }
    
    func getCircleMembers(token: String, circleId: String) -> AnyPublisher<[CircleMember], Error> {
        print("[INFO] NetworkManager.getCircleMembers 呼び出し")
        print("   サークルID: \(circleId)")
        print("   URL: /api/circles/circles/\(circleId)/members/")
        
        return makeRequest(
            endpoint: "/api/circles/circles/\(circleId)/members/",
            token: token,
            responseType: CircleMembersResponse.self
        )
        .map { response in
            print("[SUCCESS] メンバー取得成功: \(response.results.count)人")
            return response.results
        }
        .catch { error -> AnyPublisher<[CircleMember], Error> in
            print("[ERROR] メンバー取得失敗、ダミーデータを使用: \(error)")
            // エラー時はダミーデータを返す
            return Just(CircleMember.generateSampleMembers())
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    func sendCircleMessage(token: String, circleId: String, content: String) -> AnyPublisher<CircleChat, Error> {
        let messageRequest = SendMessageRequestWithCircle(content: content, circle: circleId)
        
        guard let body = try? JSONEncoder().encode(messageRequest) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        print("📤 メッセージ送信リクエスト詳細:")
        print("   URL: /api/circles/chats/")
        print("   Body: \(String(data: body, encoding: .utf8) ?? "nil")")
        
        return makeRequest(
            endpoint: "/api/circles/chats/",
            method: .POST,
            body: body,
            token: token,
            responseType: CircleChat.self
        )
        .handleEvents(
            receiveOutput: { response in
                print("[SUCCESS] sendCircleMessage 成功レスポンス:")
                print("   ID: \(response.id)")
                print("   Content: \(response.content)")
                print("   Sender: \(response.sender.username)")
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("[ERROR] sendCircleMessage 失敗:")
                    print("   エラー: \(error)")
                    print("   詳細: \(error.localizedDescription)")
                }
            }
        )
        .eraseToAnyPublisher()
    }
    
    // MARK: - Circle Posts
    
    func getCirclePosts(token: String, circleId: String, page: Int = 1) -> AnyPublisher<PagedResponse<CirclePost>, Error> {
        return makeRequest(
            endpoint: "/api/circles/posts/?circle=\(circleId)&page=\(page)",
            token: token,
            responseType: PagedResponse<CirclePost>.self
        )
    }
    
    func createCirclePost(token: String, circleId: String, content: String, mediaUrls: [String] = []) -> AnyPublisher<CirclePost, Error> {
        let postRequest = CreatePostRequestWithCircle(content: content, mediaUrls: mediaUrls, circle: circleId)
        
        guard let body = try? JSONEncoder().encode(postRequest) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/api/circles/posts/",
            method: .POST,
            body: body,
            token: token,
            responseType: CirclePost.self
        )
    }
    
    // MARK: - Circle Events
    
    func getCircleEvents(token: String, circleId: String) -> AnyPublisher<[CircleEvent], Error> {
        return makeRequest(
            endpoint: "/api/circles/events/?circle=\(circleId)",
            token: token,
            responseType: [CircleEvent].self
        )
    }
    
    func createCircleEvent(token: String, circleId: String, request: CreateEventRequest) -> AnyPublisher<CircleEvent, Error> {
        let eventRequest = CreateEventRequestWithCircle(
            title: request.title,
            description: request.description,
            startDatetime: request.startDatetime,
            endDatetime: request.endDatetime,
            location: request.location,
            circle: circleId
        )
        
        guard let body = try? JSONEncoder().encode(eventRequest) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/api/circles/events/",
            method: .POST,
            body: body,
            token: token,
            responseType: CircleEvent.self
        )
    }
    
    // MARK: - Next Generation Recommendations
    
    func getRecommendationsV2(
        token: String,
        algorithm: String = "smart",
        limit: Int = 10,
        diversityFactor: Double = 0.3,
        excludeCategories: [String] = [],
        includeNewCircles: Bool = true
    ) -> AnyPublisher<NextGenRecommendationResponse, Error> {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "algorithm", value: algorithm),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "diversity_factor", value: "\(diversityFactor)"),
            URLQueryItem(name: "include_new_circles", value: "\(includeNewCircles)")
        ]
        
        for category in excludeCategories {
            queryItems.append(URLQueryItem(name: "exclude_categories", value: category))
        }
        
        var urlComponents = URLComponents(string: "\(baseURL)/api/v2/recommendations/circles/")!
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        print("[DEBUG] 推薦APIリクエスト: \(url.absoluteString)")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                print("📊 推薦APIレスポンス: \(httpResponse.statusCode)")
                
                guard 200...299 ~= httpResponse.statusCode else {
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: NextGenRecommendationResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getUserPreferences(token: String) -> AnyPublisher<UserPreferences, Error> {
        return makeRequest(
            endpoint: "/api/v2/recommendations/user-preferences/",
            token: token,
            responseType: UserPreferences.self
        )
    }
    
    func sendRecommendationFeedback(token: String, feedback: RecommendationFeedback) -> AnyPublisher<EmptyResponse, Error> {
        guard let body = try? JSONEncoder().encode(feedback) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/api/v2/recommendations/feedback/",
            method: .POST,
            body: body,
            token: token,
            responseType: EmptyResponse.self
        )
    }
}

// MARK: - Supporting Types

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case encodingError
    case httpError(Int)
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .encodingError:
            return "エンコーディングエラーです"
        case .httpError(let code):
            return "HTTPエラー: \(code)"
        case .serverError(let message):
            return message
        }
    }
    
    var isCircleLimitError: Bool {
        if case .serverError(let message) = self {
            return message.contains("参加可能なサークル数の上限に達しています")
        }
        return false
    }
}

struct TokenRefreshRequest: Codable {
    let refresh: String
}

struct TokenRefreshResponse: Codable {
    let access: String
}

struct EmptyResponse: Codable {
    // 空のレスポンス用
}

struct SendMessageRequest: Codable {
    let content: String
}

struct CreatePostRequest: Codable {
    let content: String
    let mediaUrls: [String]
    
    enum CodingKeys: String, CodingKey {
        case content
        case mediaUrls = "media_urls"
    }
}

struct CreateEventRequest: Codable {
    let title: String
    let description: String
    let startDatetime: String
    let endDatetime: String
    let location: String?
    
    enum CodingKeys: String, CodingKey {
        case title, description, location
        case startDatetime = "start_datetime"
        case endDatetime = "end_datetime"
    }
}

struct SendMessageRequestWithCircle: Codable {
    let content: String
    let circle: String
}

struct CreatePostRequestWithCircle: Codable {
    let content: String
    let mediaUrls: [String]
    let circle: String
    
    enum CodingKeys: String, CodingKey {
        case content, circle
        case mediaUrls = "media_urls"
    }
}

struct CreateEventRequestWithCircle: Codable {
    let title: String
    let description: String
    let startDatetime: String
    let endDatetime: String
    let location: String?
    let circle: String
    
    enum CodingKeys: String, CodingKey {
        case title, description, location, circle
        case startDatetime = "start_datetime"
        case endDatetime = "end_datetime"
    }
} 