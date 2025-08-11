//
//  GuestLoginView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI
import Amplify

struct GuestLoginView: View {
    @Binding var authStatus: AuthStatus
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            // App Logo
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .padding(.top, 40)
            
            // Welcome Text
            VStack(spacing: 12) {
                Text("Welcome to ScoreBoard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Track scores, compete with friends, and level up your game")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Guest Login Button
            VStack(spacing: 20) {
                Button(action: {
                    signInAsGuest()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 18, weight: .medium))
                        }
                        
                        Text(isLoading ? "Setting up guest account..." : "Continue as Guest")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading)
                
                // Guest Info
                VStack(spacing: 8) {
                    Text("Guest Mode Features:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Create and join games")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text("Track scores and play")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("Limited features - no cross-device sync")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Spacer()
            
            // Sign in options (for future implementation)
            VStack(spacing: 16) {
                Text("Coming Soon")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 20) {
                    Button("Sign in with Apple") {
                        // TODO: Implement Apple Sign In
                    }
                    .disabled(true)
                    .opacity(0.5)
                    
                    Button("Sign in with Google") {
                        // TODO: Implement Google Sign In
                    }
                    .disabled(true)
                    .opacity(0.5)
                }
            }
            .padding(.bottom, 30)
        }
        .padding()
        .alert("Guest Login Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func signInAsGuest() {
        isLoading = true
        
        Task {
            do {
                // Create guest user
                if let guestUser = await AmplifyService.signInAsGuest() {
                    // Create guest profile in database
                    if let guestProfile = await AmplifyService.createGuestProfile(identityId: guestUser.userId) {
                        await MainActor.run {
                            authStatus = .signedIn
                            isLoading = false
                        }
                    } else {
                        await MainActor.run {
                            errorMessage = "Failed to create guest profile. Please try again."
                            showError = true
                            isLoading = false
                        }
                    }
                } else {
                    await MainActor.run {
                        errorMessage = "Failed to sign in as guest. Please try again."
                        showError = true
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "An error occurred: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    GuestLoginView(authStatus: .constant(.signedOut))
}
