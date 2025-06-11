//
//  LoginView.swift
//  KnestApp
//
//  Created by t.i on 2025/06/07.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var username = ""
    @State private var password = ""
    @State private var showingRegister = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "network")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Knest")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("つながりを育む場所")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("ユーザー名", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    SecureField("パスワード", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    if let errorMessage = authManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    Button(action: login) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("ログイン")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(authManager.isLoading || username.isEmpty || password.isEmpty)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Register Link
                VStack(spacing: 8) {
                    Text("アカウントをお持ちでないですか？")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Button("新規登録") {
                        showingRegister = true
                    }
                    .font(.footnote)
                    .foregroundColor(.blue)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView()
        }
    }
    
    private func login() {
        authManager.login(username: username, password: password)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationManager.shared)
} 