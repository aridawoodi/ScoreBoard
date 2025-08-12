//
//  ScoreBoardApp.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/3/24.
//

import Amplify
import AWSCognitoAuthPlugin
import AWSAPIPlugin
import SwiftUI

@main
struct ScoreBoardApp: App {
    @State private var showSplash = true
    
    init() {
        configureAmplify()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .preferredColorScheme(.none) // Allow system to choose light/dark mode
                    .onAppear {
                        // App startup logic can be added here if needed
                    }
                
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                        .onAppear {
                            // Hide splash after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showSplash = false
                                }
                            }
                        }
                }
            }
        }
    }

    func configureAmplify() {
        do {
            // Add plugins first
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSAPIPlugin())
            
            // Configure Amplify using the default configuration
            // This will automatically look for amplify_outputs.json in the bundle
            try Amplify.configure()
            
            print("Amplify configured successfully")
            
            // API is configured to use API key authentication by default
            // This allows guest users to access the API
        } catch {
            print("Failed to configure Amplify: \(error)")
        }
    }
}



