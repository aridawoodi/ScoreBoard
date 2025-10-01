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
    @State private var isProcessingJoin = false
    @State private var foundGame: Game?
    @State private var showNameInput = false
    @State private var playerName = ""
    @State private var pendingGame: Game?
    @State private var showJoinOptions = false
    @State private var joinMode: JoinMode = .player
    @State private var showHierarchySelection = false
    @State private var selectedParentPlayer: String?
    @State private var pendingUserId: String?
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
                        .foregroundColor(Color("LightGreen"))
                    
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
                    
                    TextField("", text: $gameCode)
                        .modifier(AppTextFieldStyle(placeholder: "Enter 6-character code", text: $gameCode))
                        .font(.title2)
                        .textInputAutocapitalization(.characters)
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
                Button("OK") { 
                    // Reset processing state when alert is dismissed
                    isProcessingJoin = false
                }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showNameInput) {
                NameInputView(
                    playerName: $playerName,
                    onConfirm: {
                        if let game = pendingGame {
                            if showJoinOptions {
                                // If join options should show, just set the flag
                                showJoinOptions = true
                            } else {
                                // Otherwise, directly join
                                joinGameWithName(game: game, playerName: playerName)
                            }
                        }
                    }
                )
            }
            .sheet(isPresented: $showJoinOptions) {
                if let game = pendingGame {
                    JoinOptionsView(
                        playerName: playerName,
                        game: game,
                        joinMode: $joinMode
                    ) {
                        if joinMode == .player {
                            if playerName.isEmpty {
                                showNameInput = true
                            } else {
                                joinGameWithName(game: game, playerName: playerName)
                            }
                        } else {
                            foundGame = game
                            onGameJoined(game)
                            showJoinGame = false
                        }
                    }
                } else {
                    Text("Error: Game not found")
                        .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showHierarchySelection) {
                if let game = pendingGame, let userId = pendingUserId {
                    HierarchySelectionView(
                        game: game,
                        userId: userId,
                        playerName: playerName,
                        onParentSelected: { parentPlayerId in
                            joinAsChildPlayer(
                                game: game,
                                userId: userId,
                                playerName: playerName,
                                parentPlayerId: parentPlayerId
                            )
                        }
                    )
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
        
        // Prevent multiple simultaneous join attempts
        guard !isProcessingJoin else { return }
        isProcessingJoin = true
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
                    isProcessingJoin = false
                    
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
                        isProcessingJoin = false
                    }
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    isProcessingJoin = false
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
                if isUserAlreadyInGame(userId: userId, playerIDs: playerIDs) {
                    // User already in game - navigate to scoreboard immediately
                    await MainActor.run {
                        // Navigate to scoreboard immediately
                        foundGame = game
                        onGameJoined(game)
                        // Dismiss the join game sheet
                        showJoinGame = false
                        isProcessingJoin = false
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
                print("🔍 DEBUG: Error in joinGameWithName: \(error)")
                await MainActor.run {
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                    isProcessingJoin = false
                }
            }
        }
        print("🔍 DEBUG: ===== JOIN GAME WITH NAME END =====")
    }
    
    func joinGameWithName(game: Game, playerName: String) {
        print("🔍 DEBUG: ===== JOIN GAME WITH NAME START =====")
        print("🔍 DEBUG: Game ID: \(game.id)")
        print("🔍 DEBUG: Player Name: \(playerName)")
        print("🔍 DEBUG: Current isProcessingJoin: \(isProcessingJoin)")
        
        // Prevent multiple simultaneous join attempts
        guard !isProcessingJoin else { 
            print("🔍 DEBUG: Already processing join, returning early")
            return 
        }
        isProcessingJoin = true
        print("🔍 DEBUG: Set isProcessingJoin to true")
        
        Task {
            do {
                // Get current user info using helper function
                guard let currentUserInfo = await getCurrentUser() else {
                    print("🔍 DEBUG: Failed to get current user info")
                    await MainActor.run {
                        alertMessage = "Unable to get current user information."
                        showAlert = true
                        isProcessingJoin = false
                    }
                    return
                }
                
                let userId = currentUserInfo.userId
                let isGuest = currentUserInfo.isGuest
                
                print("🔍 DEBUG: Current user ID: \(userId)")
                print("🔍 DEBUG: Is guest: \(isGuest)")
                print("🔍 DEBUG: Game playerIDs: \(game.playerIDs ?? [])")
                
                // Check if user is already in the game using improved detection
                let playerIDs = game.playerIDs
                if isUserAlreadyInGame(userId: userId, playerIDs: playerIDs) {
                    print("🔍 DEBUG: User \(userId) is already in game with playerIDs: \(playerIDs)")
                    // User already in game - navigate to scoreboard immediately
                    await MainActor.run {
                        // Navigate to scoreboard immediately
                        foundGame = game
                        onGameJoined(game)
                        // Dismiss the join game sheet
                        showJoinGame = false
                        isProcessingJoin = false
                    }
                    return
                }
                
                // For anonymous users, we need to store both the user ID and the display name
                // We'll use a format like "userID:displayName" to maintain uniqueness
                let playerIdentifier = "\(userId):\(playerName)"
                
                // Check if this specific user ID is already in the game (for anonymous users)
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
                                foundGame = updatedGame
                                onGameJoined(updatedGame)
                                // Dismiss the join game sheet immediately
                                showJoinGame = false
                                isProcessingJoin = false
                            }
                        case .failure(let error):
                            await MainActor.run {
                                alertMessage = "Failed to update display name: \(error.localizedDescription)"
                                showAlert = true
                                isProcessingJoin = false
                            }
                        }
                    } else {
                        // Same display name - just navigate to scoreboard
                        await MainActor.run {
                            foundGame = game
                            onGameJoined(game)
                            // Dismiss the join game sheet immediately
                            showJoinGame = false
                            isProcessingJoin = false
                        }
                    }
                    return
                }
                
                // User not in game - check if this is a hierarchy game
                print("🔍 DEBUG: User \(userId) is NOT in game (anonymous), adding them with identifier: \(playerIdentifier). Current playerIDs: \(game.playerIDs ?? [])")
                
                // Check if game has player hierarchy
                if game.hasPlayerHierarchy {
                    print("🔍 DEBUG: Game has player hierarchy, showing parent player selection")
                    await MainActor.run {
                        pendingUserId = userId
                        pendingGame = game
                        showHierarchySelection = true
                        isProcessingJoin = false
                    }
                    return
                }
                
                // Regular game - add player normally
                var updatedGame = game
                updatedGame.playerIDs = (game.playerIDs ?? []) + [playerIdentifier]
                
                print("🔍 DEBUG: Updated game playerIDs: \(updatedGame.playerIDs ?? [])")
                
                // Update the game in the backend
                print("🔍 DEBUG: Updating game in backend...")
                let updateResult = try await Amplify.API.mutate(request: .update(updatedGame))
                switch updateResult {
                case .success(let updatedGame):
                    print("🔍 DEBUG: Successfully updated game in backend")
                    await MainActor.run {
                        foundGame = updatedGame
                        onGameJoined(updatedGame)
                        // Dismiss the join game sheet
                        showJoinGame = false
                        isProcessingJoin = false
                    }
                case .failure(let error):
                    print("🔍 DEBUG: Failed to update game in backend: \(error)")
                    await MainActor.run {
                        alertMessage = "Failed to join game: \(error.localizedDescription)"
                        showAlert = true
                        isProcessingJoin = false
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
    
    // MARK: - Helper Functions
    
    /// Improved function to check if a user is already in a game
    /// This handles both registered users (direct user ID) and anonymous users (userID:displayName format)
    private func isUserAlreadyInGame(userId: String, playerIDs: [String]) -> Bool {
        // Check for exact match (registered users)
        if playerIDs.contains(userId) {
            print("🔍 DEBUG: Found exact user ID match: \(userId)")
            return true
        }
        
        // Check for prefix match (anonymous users with format "userID:displayName")
        let hasPrefixMatch = playerIDs.contains { playerID in
            playerID.hasPrefix(userId + ":")
        }
        
        if hasPrefixMatch {
            print("🔍 DEBUG: Found prefix match for user ID: \(userId)")
            return true
        }
        
        // Additional check: look for any playerID that contains the user ID
        // This handles edge cases where the format might be different
        let hasContainedMatch = playerIDs.contains { playerID in
            playerID.contains(userId)
        }
        
        if hasContainedMatch {
            print("🔍 DEBUG: Found contained match for user ID: \(userId)")
            return true
        }
        
        print("🔍 DEBUG: No match found for user ID: \(userId)")
        return false
    }
    
    func joinAsChildPlayer(game: Game, userId: String, playerName: String, parentPlayerId: String) {
        print("🔍 DEBUG: ===== JOIN AS CHILD PLAYER START =====")
        print("🔍 DEBUG: Game ID: \(game.id)")
        print("🔍 DEBUG: User ID: \(userId)")
        print("🔍 DEBUG: Player Name: \(playerName)")
        print("🔍 DEBUG: Parent Player ID: \(parentPlayerId)")
        
        isProcessingJoin = true
        
        Task {
            do {
                // Add user as child player to the selected parent
                var updatedGame = game.addChildPlayer(userId, to: parentPlayerId)
                
                // Update the game in the backend
                let updateResult = try await Amplify.API.mutate(request: .update(updatedGame))
                switch updateResult {
                case .success(let savedGame):
                    print("🔍 DEBUG: Successfully added child player to hierarchy")
                    await MainActor.run {
                        foundGame = savedGame
                        onGameJoined(savedGame)
                        showJoinGame = false
                        showHierarchySelection = false
                        isProcessingJoin = false
                    }
                case .failure(let error):
                    print("🔍 DEBUG: Failed to add child player: \(error)")
                    await MainActor.run {
                        alertMessage = "Failed to join as child player: \(error.localizedDescription)"
                        showAlert = true
                        showHierarchySelection = false
                        isProcessingJoin = false
                    }
                }
            } catch {
                print("🔍 DEBUG: Error in joinAsChildPlayer: \(error)")
                await MainActor.run {
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                    showHierarchySelection = false
                    isProcessingJoin = false
                }
            }
        }
    }
} 