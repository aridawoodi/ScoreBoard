//
//  AuthenticationView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI
import Amplify
import Authenticator

struct AuthenticationView: View {
    @Binding var authStatus: AuthStatus
    @State private var showGuestLogin = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with app logo
            VStack(spacing: 20) {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .padding(.top, 40)
                
                Text("Welcome to ScoreBoard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Sign in to track scores, compete with friends, and level up your game")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.bottom, 30)
            
            // Main authentication area
            VStack(spacing: 20) {
                // Amplify Authenticator for email/password authentication
                Authenticator { state in
                    VStack {
                        Button("Sign out") {
                            Task {
                                await state.signOut()
                                authStatus = .signedOut
                            }
                        }
                    }
                    .onAppear {
                        if state is SignedInState {
                            authStatus = .signedIn
                        }
                    }
                }
                .frame(maxHeight: 400)
                
                // Divider
                HStack {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.secondary.opacity(0.3))
                    Text("OR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.secondary.opacity(0.3))
                }
                .padding(.horizontal)
                
                // Guest login option
                Button(action: {
                    showGuestLogin = true
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 18, weight: .medium))
                        
                        Text("Continue as Guest")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Guest info
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
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showGuestLogin) {
            GuestLoginView(authStatus: $authStatus)
        }
    }
}

#Preview {
    AuthenticationView(authStatus: .constant(.signedOut))
}
