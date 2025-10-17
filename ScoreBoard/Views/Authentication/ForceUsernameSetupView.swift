//
//  ForceUsernameSetupView.swift
//  ScoreBoard
//
//  Force username setup view for first-time users
//  Beautiful UI with real-time validation and smart suggestions
//

import SwiftUI

struct ForceUsernameSetupView: View {
    // Callbacks
    let onComplete: (String) -> Void
    let onSkip: () -> Void
    
    // State
    @State private var username: String = ""
    @State private var isUsernameValid: Bool = false
    
    // Computed properties
    private var canContinue: Bool {
        return isUsernameValid
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("GradientBackground"),
                    Color.black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Main content
            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)
                    
                    // Header section
                    VStack(spacing: 16) {
                        // App logo
                        Image("logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                        
                        // Welcome text
                        Text("Welcome to ScoreBoard!")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Choose a unique username to get started")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // Username input section
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Username")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ValidatedUsernameField(
                                username: $username,
                                isValid: $isUsernameValid,
                                showHelperText: true,
                                showSuggestions: true,
                                showCharacterCount: true,
                                placeholder: "Enter username"
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        // Continue button
                        Button(action: handleContinue) {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    canContinue ?
                                        Color("LightGreen") :
                                        Color.gray.opacity(0.5)
                                )
                                .cornerRadius(12)
                        }
                        .disabled(!canContinue)
                        .animation(.easeInOut(duration: 0.2), value: canContinue)
                        
                        // Skip button
                        Button(action: handleSkip) {
                            Text("Skip for now")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .underline()
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleContinue() {
        print("🔍 DEBUG: ForceUsernameSetupView - Continue button tapped")
        print("🔍 DEBUG: ForceUsernameSetupView - Final username: '\(username)'")
        
        guard canContinue else {
            print("🔍 DEBUG: ForceUsernameSetupView - Cannot continue, validation not passed")
            return
        }
        
        // Call completion handler with validated username
        onComplete(username)
    }
    
    private func handleSkip() {
        print("🔍 DEBUG: ForceUsernameSetupView - Skip button tapped")
        
        // Call skip handler
        onSkip()
    }
}

// MARK: - Preview

#Preview {
    ForceUsernameSetupView(
        onComplete: { username in
            print("✅ Completed with username: \(username)")
        },
        onSkip: {
            print("⏭️ Skipped")
        }
    )
}

