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
    
    private let baseURL = "http://127.0.0.1:8000/api"
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
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = body
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: responseType, decoder: JSONDecoder())
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
            endpoint: "/users/auth/token/",
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
            endpoint: "/users/auth/register/",
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
            endpoint: "/users/auth/token/refresh/",
            method: .POST,
            body: body,
            responseType: TokenRefreshResponse.self
        )
    }
    
    // MARK: - User Profile
    
    func getUserProfile(token: String) -> AnyPublisher<User, Error> {
        return makeRequest(
            endpoint: "/users/me/",
            token: token,
            responseType: User.self
        )
    }
    
    // MARK: - Interests
    
    func getInterests() -> AnyPublisher<[Interest], Error> {
        guard let token = getAuthToken() else {
            return Fail(error: NetworkError.invalidResponse)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/interests/",
            token: token,
            responseType: [Interest].self
        )
    }
    
    func getUserInterests() -> AnyPublisher<[UserInterest], Error> {
        guard let token = getAuthToken() else {
            return Fail(error: NetworkError.invalidResponse)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/user-interests/",
            token: token,
            responseType: [UserInterest].self
        )
    }
    
    func createUserInterest(request: CreateUserInterestRequest) -> AnyPublisher<UserInterest, Error> {
        guard let token = getAuthToken() else {
            return Fail(error: NetworkError.invalidResponse)
                .eraseToAnyPublisher()
        }
        
        guard let body = try? JSONEncoder().encode(request) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/user-interests/",
            method: .POST,
            body: body,
            token: token,
            responseType: UserInterest.self
        )
    }
    
    func deleteUserInterest(id: String) -> AnyPublisher<EmptyResponse, Error> {
        guard let token = getAuthToken() else {
            return Fail(error: NetworkError.invalidResponse)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/user-interests/\(id)/",
            method: .DELETE,
            token: token,
            responseType: EmptyResponse.self
        )
    }
    
    // MARK: - Hashtags
    
    func getTags(search: String? = nil) -> AnyPublisher<[Tag], Error> {
        var endpoint = "/interests/tags/"
        if let search = search, !search.isEmpty {
            endpoint += "?search=\(search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }
        
        return makeRequest(
            endpoint: endpoint,
            responseType: [Tag].self
        )
    }
    
    func getPopularTags() -> AnyPublisher<[Tag], Error> {
        return makeRequest(
            endpoint: "/interests/tags/popular/",
            responseType: [Tag].self
        )
    }
    
    func getUserTags() -> AnyPublisher<[UserTag], Error> {
        // トークンがあれば送信（認証済みユーザー）、なければ送信しない（testuser使用）
        let token = getAuthToken()
        return makeRequest(
            endpoint: "/interests/user-tags/",
            token: token,
            responseType: [UserTag].self
        )
    }
    
    func createUserTag(request: CreateUserTagRequest) -> AnyPublisher<UserTag, Error> {
        // トークンがあれば送信（認証済みユーザー）、なければ送信しない（testuser使用）
        let token = getAuthToken()
        
        guard let body = try? JSONEncoder().encode(request) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/interests/user-tags/",
            method: .POST,
            body: body,
            token: token,
            responseType: UserTag.self
        )
    }
    
    func deleteUserTag(id: Int) -> AnyPublisher<EmptyResponse, Error> {
        // トークンがあれば送信（認証済みユーザー）、なければ送信しない（testuser使用）
        let token = getAuthToken()
        return makeRequest(
            endpoint: "/interests/user-tags/\(id)/",
            method: .DELETE,
            token: token,
            responseType: EmptyResponse.self
        )
    }
    
    func getAuthToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "access_token",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess,
              let data = item as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
    
    // MARK: - Circles
    
    func getCircles(
        token: String,
        page: Int = 1,
        search: String? = nil,
        category: String? = nil
    ) -> AnyPublisher<CircleListResponse, Error> {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "\(page)")
        ]
        
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        
        if let category = category, !category.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        
        var urlComponents = URLComponents(string: "\(baseURL)/circles/")!
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: CircleListResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func getMyCircles(token: String) -> AnyPublisher<[KnestCircle], Error> {
        return makeRequest(
            endpoint: "/circles/circles/my/",
            token: token,
            responseType: CircleListResponse.self
        )
        .map { $0.results }
        .eraseToAnyPublisher()
    }
    
    func getRecommendedCircles(token: String) -> AnyPublisher<[CircleRecommendation], Error> {
        return makeRequest(
            endpoint: "/circles/recommended/",
            token: token,
            responseType: [CircleRecommendation].self
        )
    }
    
    func getCircleDetail(token: String, circleId: String) -> AnyPublisher<KnestCircle, Error> {
        return makeRequest(
            endpoint: "/circles/\(circleId)/",
            token: token,
            responseType: KnestCircle.self
        )
    }
    
    func createCircle(token: String, request: CreateCircleRequest) -> AnyPublisher<KnestCircle, Error> {
        guard let body = try? JSONEncoder().encode(request) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/circles/",
            method: .POST,
            body: body,
            token: token,
            responseType: KnestCircle.self
        )
    }
    
    func joinCircle(token: String, circleId: String, request: JoinCircleRequest) -> AnyPublisher<CircleMembership, Error> {
        guard let body = try? JSONEncoder().encode(request) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/circles/\(circleId)/join/",
            method: .POST,
            body: body,
            token: token,
            responseType: CircleMembership.self
        )
    }
    
    func leaveCircle(token: String, circleId: String) -> AnyPublisher<EmptyResponse, Error> {
        return makeRequest(
            endpoint: "/circles/\(circleId)/leave/",
            method: .DELETE,
            token: token,
            responseType: EmptyResponse.self
        )
    }
    
    func getCircleChats(token: String, circleId: String, page: Int = 1) -> AnyPublisher<[CircleChat], Error> {
        let endpoint = "/circles/chats/?circle=\(circleId)&page=\(page)"
        print("🌐 チャットAPI呼び出し: \(baseURL + endpoint)")
        print("🔗 サークルID: \(circleId), ページ: \(page)")
        
        return makeRequest(
            endpoint: endpoint,
            token: token,
            responseType: PagedResponse<CircleChat>.self
        )
        .handleEvents(
            receiveSubscription: { _ in
                print("🚀 チャットAPIリクエスト開始")
            },
            receiveOutput: { response in
                print("🎯 APIレスポンス受信：results数 = \(response.results.count)")
                print("📄 ページ情報：next = \(response.next ?? "nil"), previous = \(response.previous ?? "nil")")
                for (index, chat) in response.results.enumerated() {
                    print("  💬 API[\(index)]: \"\(chat.content)\" from \(chat.sender.displayName)")
                }
            },
            receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("💥 チャットAPI失敗：\(error)")
                }
            }
        )
        .map { response in
            print("🔄 APIレスポンスをArrayに変換中...")
            return response.results
        }
        .eraseToAnyPublisher()
    }
    
    func sendCircleMessage(token: String, circleId: String, content: String) -> AnyPublisher<CircleChat, Error> {
        let messageRequest = SendMessageRequestWithCircle(content: content, circle: circleId)
        
        guard let body = try? JSONEncoder().encode(messageRequest) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/circles/chats/",
            method: .POST,
            body: body,
            token: token,
            responseType: CircleChat.self
        )
    }
    
    // MARK: - Circle Posts
    
    func getCirclePosts(token: String, circleId: String, page: Int = 1) -> AnyPublisher<PagedResponse<CirclePost>, Error> {
        return makeRequest(
            endpoint: "/circles/\(circleId)/posts/?page=\(page)",
            token: token,
            responseType: PagedResponse<CirclePost>.self
        )
    }
    
    func createCirclePost(token: String, circleId: String, content: String, mediaUrls: [String] = []) -> AnyPublisher<CirclePost, Error> {
        let postRequest = CreatePostRequest(content: content, mediaUrls: mediaUrls)
        
        guard let body = try? JSONEncoder().encode(postRequest) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/circles/\(circleId)/posts/",
            method: .POST,
            body: body,
            token: token,
            responseType: CirclePost.self
        )
    }
    
    // MARK: - Circle Events
    
    func getCircleEvents(token: String, circleId: String) -> AnyPublisher<[CircleEvent], Error> {
        return makeRequest(
            endpoint: "/circles/\(circleId)/events/",
            token: token,
            responseType: [CircleEvent].self
        )
    }
    
    func createCircleEvent(token: String, circleId: String, request: CreateEventRequest) -> AnyPublisher<CircleEvent, Error> {
        guard let body = try? JSONEncoder().encode(request) else {
            return Fail(error: NetworkError.encodingError)
                .eraseToAnyPublisher()
        }
        
        return makeRequest(
            endpoint: "/circles/\(circleId)/events/",
            method: .POST,
            body: body,
            token: token,
            responseType: CircleEvent.self
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
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "無効なURLです"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .encodingError:
            return "データのエンコードに失敗しました"
        case .httpError(let code):
            return "HTTPエラー: \(code)"
        }
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