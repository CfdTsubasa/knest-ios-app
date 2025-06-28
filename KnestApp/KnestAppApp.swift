//
//  KnestAppApp.swift
//  KnestApp
//
//  Created by t.i on 2025/06/07.
//



import SwiftUI

@main
struct KnestAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AuthenticationManager.shared)
                .environmentObject(RecommendationManager.shared)
                .environmentObject(CircleManager.shared)
        }
    }
} 
