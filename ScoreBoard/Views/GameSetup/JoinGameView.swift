//
//  JoinGameView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/5/24.
//

import Foundation
import SwiftUI
import Amplify

enum JoinMode {
    case player
    case spectator
}

struct JoinGameView: View {
    @State private var gameCode: String = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var foundGame: Game?
    @State private var showNameInput = false
    @State private var playerName = ""
    @State private var pendingGame: Game?
    @State private var showJoinOptions = false
    @State private var joinMode: JoinMode = .player
    @Environment(\.dismiss) private var dismiss
    @Binding var showJoinGame: Bool
    let onGameJoined: (Game) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Join a Game")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Enter the 6-character game code shared by the host")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Game Code Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Game Code")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    ZStack(alignment: .leading) {
                        if gameCode.isEmpty {
                            Text("Enter 6-character code")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.title2)
                                .padding(.leading, 16)
                        }
                        TextField("", text: $gameCode)
                            .accentColor(.white)
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .textInputAutocapitalization(.characters)
                    }
                        .onChange(of: gameCode) { newValue in
                            gameCode = newValue.uppercased()
                        }
                        .onSubmit {
                            joinGame()
                        }
                }
                .padding(.horizontal)
                
                // Join Button
                Button(action: {
                    joinGame()
                }) {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Joining...")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("Join Game")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
                .disabled(isLoading || gameCode.count != 6)
                .padding(.horizontal)
                
                Spacer()
            }
            .gradientBackground()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Join Game", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: showAlert) { newValue in
                if newValue && alertMessage.contains("already in this game") {
                    // Add haptic feedback for duplicate join
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            }
            .sheet(isPresented: $showNameInput) {
                NameInputView(playerName: $playerName) {
                    // User confirmed their name, now show join options
                    if let game = pendingGame {
                        showJoinOptions = true
                    }
                }
            }
            .sheet(isPresented: $showJoinOptions) {
                JoinOptionsView(
                    playerName: playerName,
                    joinMode: $joinMode
                ) {
                    // User confirmed join mode
                    if let game = pendingGame {
                        if joinMode == .player {
                            if playerName.isEmpty {
                                // This shouldn't happen, but fallback
                                showNameInput = true
                            } else {
                                joinGameWithName(game: game, playerName: playerName)
                            }
                        } else {
                            // Spectator mode - just navigate to scoreboard
                            print("🔍 DEBUG: Joining as spectator for game: \(game.id)")
                            foundGame = game
                            onGameJoined(game)
                            // Dismiss the join game sheet
                            showJoinGame = false
                        }
                    }
                }
            }
        }
    }
    
    func joinGame() {
        guard gameCode.count == 6 else {
            alertMessage = "Please enter a 6-character game code."
            showAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // ✅ EFFICIENT: Query only games that match the code prefix
                // This uses GraphQL filtering to reduce data transfer and costs
                let filter = Game.keys.id.beginsWith(gameCode.lowercased()) || 
                            Game.keys.id.beginsWith(gameCode.uppercased())
                
                let result = try await Amplify.API.query(
                    request: .list(Game.self, where: filter)
                )
                
                await MainActor.run {
                    isLoading = false
                    
                    switch result {
                    case .success(let games):
                        // Since we filtered at the database level, we should get exactly what we need
                        if let game = games.first {
                            print("🔍 DEBUG: Found game efficiently with ID: \(game.id)")
                            
                            // Get current user using helper function that works for both guest and authenticated users
                            Task {
                                if let currentUserInfo = await getCurrentUser() {
                                    let userId = currentUserInfo.userId
                                    let isGuest = currentUserInfo.isGuest
                                    
                                    print("🔍 DEBUG: Current user ID: \(userId), isGuest: \(isGuest)")
                                    
                                    // Check if user has a profile
                                    let profileResult = try await Amplify.API.query(request: .get(User.self, byId: userId))
                                    
                                    await MainActor.run {
                                        switch profileResult {
                                        case .success(let userProfile):
                                            // User has a profile, show join options
                                            if let profile = userProfile {
                                                pendingGame = game
                                                playerName = profile.username
                                                showJoinOptions = true
                                            } else {
                                                // Profile is nil, ask for name
                                                pendingGame = game
                                                showNameInput = true
                                            }
                                        case .failure:
                                            // User doesn't have a profile, ask for name
                                            pendingGame = game
                                            showNameInput = true
                                        }
                                    }
                                } else {
                                    await MainActor.run {
                                        // If we can't get current user, still allow joining as anonymous
                                        pendingGame = game
                                        showNameInput = true
                                    }
                                }
                            }
                        } else {
                            alertMessage = "Game not found. Please check the game code and try again.\n\nIf you're sure the code is correct, the game may have been deleted or you may not have permission to access it."
                            showAlert = true
                        }
                        
                    case .failure(let error):
                        // Check if it's an authentication error
                        if error.localizedDescription.contains("Unauthorized") || 
                           error.localizedDescription.contains("Not Authorized") ||
                           error.localizedDescription.contains("access denied") {
                            alertMessage = "Access denied. This usually means the game owner needs to update their privacy settings. Please contact the game host."
                        } else {
                            alertMessage = "Error joining game: \(error.localizedDescription)"
                        }
                        showAlert = true
                    }
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    func joinGameWithProfile(game: Game, user: AuthUser, username: String) {
        Task {
            do {
                // Get current user info using helper function
                guard let currentUserInfo = await getCurrentUser() else {
                    await MainActor.run {
                        alertMessage = "Unable to get current user information."
                        showAlert = true
                    }
                    return
                }
                
                let userId = currentUserInfo.userId
                let isGuest = currentUserInfo.isGuest
                
                // Check if user is already in the game
                let playerIDs = game.playerIDs
                if playerIDs.contains(userId) {
                    // User already in game - just navigate to scoreboard
                    await MainActor.run {
                        alertMessage = "You are already in this game!"
                        showAlert = true
                        // Still navigate to scoreboard since they're already a player
                        foundGame = game
                        onGameJoined(game)
                    }
                    return
                }
                
                // User not in game - add them
                print("🔍 DEBUG: User \(userId) is NOT in game, adding them. Current playerIDs: \(game.playerIDs)")
                var updatedGame = game
                updatedGame.playerIDs = game.playerIDs + [userId]
                
                // Update the game in the backend
                let updateResult = try await Amplify.API.mutate(request: .update(updatedGame))
                switch updateResult {
                case .success(let updatedGame):
                    await MainActor.run {
                        foundGame = updatedGame
                        onGameJoined(updatedGame)
                    }
                case .failure(let error):
                    await MainActor.run {
                        alertMessage = "Failed to join game: \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    func joinGameWithName(game: Game, playerName: String) {
        Task {
            do {
                // Get current user info using helper function
                guard let currentUserInfo = await getCurrentUser() else {
                    await MainActor.run {
                        alertMessage = "Unable to get current user information."
                        showAlert = true
                    }
                    return
                }
                
                let userId = currentUserInfo.userId
                let isGuest = currentUserInfo.isGuest
                
                // Check if user is already in the game (by user ID)
                let playerIDs = game.playerIDs
                if playerIDs.contains(userId) {
                    print("🔍 DEBUG: User \(userId) is already in game with playerIDs: \(playerIDs)")
                    // User already in game - show alert and navigate
                    await MainActor.run {
                        alertMessage = "You are already in this game! Taking you to the scoreboard..."
                        showAlert = true
                        // Navigate to scoreboard after a short delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            foundGame = game
                            onGameJoined(game)
                            // Dismiss the join game sheet
                            showJoinGame = false
                        }
                    }
                    return
                }
                
                // For anonymous users, we need to store both the user ID and the display name
                // We'll use a format like "userID:displayName" to maintain uniqueness
                let playerIdentifier = "\(userId):\(playerName)"
                
                // Check if this specific user ID is already in the game
                if let existingPlayerID = playerIDs.first(where: { $0.hasPrefix(userId) }) {
                    print("🔍 DEBUG: User \(userId) is already in game (anonymous) with playerIDs: \(playerIDs)")
                    
                    // Check if the display name is different
                    let existingComponents = existingPlayerID.split(separator: ":", maxSplits: 1)
                    let existingDisplayName = existingComponents.count == 2 ? String(existingComponents[1]) : ""
                    
                    if existingDisplayName != playerName {
                        // User wants to change their display name - update it
                        print("🔍 DEBUG: Updating display name from '\(existingDisplayName)' to '\(playerName)'")
                        var updatedGame = game
                        let newPlayerIdentifier = "\(userId):\(playerName)"
                        updatedGame.playerIDs = playerIDs.map { $0 == existingPlayerID ? newPlayerIdentifier : $0 }
                        
                        // Update the game in the backend
                        let updateResult = try await Amplify.API.mutate(request: .update(updatedGame))
                        switch updateResult {
                        case .success(let updatedGame):
                            await MainActor.run {
                                alertMessage = "Display name updated to '\(playerName)'! Taking you to the scoreboard..."
                                showAlert = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    foundGame = updatedGame
                                    onGameJoined(updatedGame)
                                    // Dismiss the join game sheet
                                    showJoinGame = false
                                }
                            }
                        case .failure(let error):
                            await MainActor.run {
                                alertMessage = "Failed to update display name: \(error.localizedDescription)"
                                showAlert = true
                            }
                        }
                    } else {
                        // Same display name - just navigate to scoreboard
                        await MainActor.run {
                            alertMessage = "You are already in this game! Taking you to the scoreboard..."
                            showAlert = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                foundGame = game
                                onGameJoined(game)
                                // Dismiss the join game sheet
                                showJoinGame = false
                            }
                        }
                    }
                    return
                }
                
                // User not in game - add them with their chosen name
                print("🔍 DEBUG: User \(userId) is NOT in game (anonymous), adding them with identifier: \(playerIdentifier). Current playerIDs: \(game.playerIDs ?? [])")
                var updatedGame = game
                updatedGame.playerIDs = (game.playerIDs ?? []) + [playerIdentifier]
                
                // Update the game in the backend
                let updateResult = try await Amplify.API.mutate(request: .update(updatedGame))
                switch updateResult {
                case .success(let updatedGame):
                    await MainActor.run {
                        foundGame = updatedGame
                        onGameJoined(updatedGame)
                        // Dismiss the join game sheet
                        showJoinGame = false
                    }
                case .failure(let error):
                    await MainActor.run {
                        alertMessage = "Failed to join game: \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
} 