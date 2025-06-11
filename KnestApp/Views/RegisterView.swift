//
//  RegisterView.swift
//  KnestApp
//
//  Created by t.i on 2025/06/07.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var email = ""
    @State private var displayName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("新規登録")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Knestでつながりを始めよう")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 32)
                    
                    // Registration Form
                    VStack(spacing: 16) {
                        TextField("ユーザー名", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        TextField("メールアドレス", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .disableAutocorrection(true)
                        
                        TextField("表示名（任意）", text: $displayName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        SecureField("パスワード", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        SecureField("パスワード確認", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        if !passwordsMatch && !confirmPassword.isEmpty {
                            Text("パスワードが一致しません")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        if let errorMessage = authManager.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
                        Button(action: register) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                Text("登録")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isFormValid ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!isFormValid || authManager.isLoading)
                    }
                    .padding(.horizontal, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var passwordsMatch: Bool {
        password == confirmPassword
    }
    
    private var isFormValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        passwordsMatch &&
        password.count >= 6
    }
    
    private func register() {
        let finalDisplayName = displayName.isEmpty ? nil : displayName
        authManager.register(
            username: username,
            email: email,
            password: password,
            password2: confirmPassword,
            displayName: finalDisplayName
        )
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthenticationManager.shared)
} 