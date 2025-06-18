//
//  AuthenticationManager.swift
//  KnestApp
//
//  Created by t.i on 2025/06/07.
//

import Foundation
import Combine

class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var accessToken: String?
    private var refreshToken: String?
    private var cancellables = Set<AnyCancellable>()
    
    private let networkManager = NetworkManager.shared
    
    private init() {
        loadStoredTokens()
    }
    
    // MARK: - Public Methods
    
    func login(username: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        networkManager.login(username: username, password: password)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.handleLoginResponse(response)
                }
            )
            .store(in: &cancellables)
    }
    
    func register(username: String, email: String, password: String, password2: String, displayName: String?) {
        isLoading = true
        errorMessage = nil
        
        let request = RegisterRequest(
            username: username,
            email: email,
            password: password,
            password2: password2,
            displayName: displayName,
            birthDate: nil,      // 登録時は未設定
            prefecture: nil      // 登録時は未設定
        )
        
        networkManager.register(request: request)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] response in
                    self?.handleLoginResponse(response)
                }
            )
            .store(in: &cancellables)
    }
    
    func logout() {
        accessToken = nil
        refreshToken = nil
        currentUser = nil
        isAuthenticated = false
        
        // トークンをKeychainから削除
        deleteTokenFromKeychain(key: "access_token")
        deleteTokenFromKeychain(key: "refresh_token")
    }
    
    func refreshTokenIfNeeded() {
        guard let refreshToken = refreshToken else { return }
        
        networkManager.refreshToken(refreshToken: refreshToken)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        // リフレッシュトークンが無効な場合はログアウト
                        DispatchQueue.main.async {
                            self.logout()
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    self?.accessToken = response.access
                    self?.saveTokenToKeychain(token: response.access, key: "access_token")
                }
            )
            .store(in: &cancellables)
    }
    
    func checkAuthenticationStatus() {
        // 既に認証状態をチェック済みの場合は何もしない
        if accessToken != nil && isAuthenticated {
            return
        }
        
        // 保存されたトークンを再読み込み
        loadStoredTokens()
    }
    
    func loadUserProfile() {
        guard let token = accessToken else { return }
        
        networkManager.getUserProfile(token: token)
            .sink(
                receiveCompletion: { completion in
                    if case .failure = completion {
                        // プロフィール取得失敗時はトークンをリフレッシュ
                        self.refreshTokenIfNeeded()
                    }
                },
                receiveValue: { [weak self] user in
                    self?.currentUser = user
                }
            )
            .store(in: &cancellables)
    }
    
    func getCurrentUserId() -> String? {
        return currentUser?.id
    }
    
    // MARK: - Token Access
    
    func getAccessToken() -> String? {
        return accessToken
    }
    
    // MARK: - Test User Creation
    
    func createTestUser() {
        isLoading = true
        errorMessage = nil
        
        // ランダムなテストユーザー情報を生成
        let randomNumber = Int.random(in: 1000...9999)
        let testUsername = "testuser\(randomNumber)"
        let testEmail = "test\(randomNumber)@example.com"
        let testPassword = "testpass123"
        let testDisplayName = "テストユーザー\(randomNumber)"
        
        let request = RegisterRequest(
            username: testUsername,
            email: testEmail,
            password: testPassword,
            password2: testPassword,
            displayName: testDisplayName,
            birthDate: nil,
            prefecture: nil
        )
        
        networkManager.register(request: request)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = "テストユーザーの作成に失敗しました: \(error.localizedDescription)"
                    }
                },
                receiveValue: { [weak self] response in
                    self?.handleLoginResponse(response)
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    private func handleLoginResponse(_ response: LoginResponse) {
        accessToken = response.access
        refreshToken = response.refresh
        currentUser = response.user
        isAuthenticated = true
        
        // トークンをKeychainに保存
        saveTokenToKeychain(token: response.access, key: "access_token")
        saveTokenToKeychain(token: response.refresh, key: "refresh_token")
    }
    
    private func loadStoredTokens() {
        accessToken = loadTokenFromKeychain(key: "access_token")
        refreshToken = loadTokenFromKeychain(key: "refresh_token")
        
        if accessToken != nil {
            isAuthenticated = true
            loadUserProfile()
        }
    }
    
    // MARK: - Keychain Methods
    
    private func saveTokenToKeychain(token: String, key: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func loadTokenFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
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
    
    private func deleteTokenFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
} 