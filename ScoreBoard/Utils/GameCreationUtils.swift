//
//  GameCreationUtils.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation
import SwiftUI
import Amplify

// MARK: - Game Creation Utilities
class GameCreationUtils {
    
    // MARK: - Shared User ID Handling
    static func getCurrentUserId() async throws -> String {
        let isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
        
        if isGuestUser {
            let guestUserId = UserDefaults.standard.string(forKey: "current_guest_user_id") ?? ""
            print("🔍 DEBUG: GameCreationUtils - Guest user ID: \(guestUserId)")
            return guestUserId
        } else {
            let user = try await Amplify.Auth.getCurrentUser()
            print("🔍 DEBUG: GameCreationUtils - Current user ID: \(user.userId)")
            return user.userId
        }
    }
    
    // MARK: - Standardized Game Creation Callback
    static func handleGameCreated(
        game: Game,
        navigationState: NavigationState,
        selectedTab: Binding<Int>? = nil
    ) {
        print("🔍 DEBUG: ===== STANDARDIZED GAME CREATED CALLBACK =====")
        print("🔍 DEBUG: Game created with ID: \(game.id)")
        print("🔍 DEBUG: Setting selectedGame to: \(game.id)")
        
        // Set the selected game
        navigationState.selectedGame = game
        
        // Add the new game to userGames immediately to ensure UI consistency
        if !navigationState.userGames.contains(where: { $0.id == game.id }) {
            print("🔍 DEBUG: Adding new game to userGames immediately")
            navigationState.userGames.append(game)
        }
        
        // Switch to Your Board tab if provided
        if let selectedTab = selectedTab {
            print("🔍 DEBUG: Setting selectedTab to: 2 (Your Board)")
            selectedTab.wrappedValue = 2
            print("🔍 DEBUG: Current selectedTab value: \(selectedTab.wrappedValue)")
        }
        
        print("🔍 DEBUG: Current navigationState.selectedGame: \(navigationState.selectedGame?.id ?? "nil")")
        print("🔍 DEBUG: Current userGames count: \(navigationState.userGames.count)")
        
        // Force navigation state to refresh all views
        navigationState.objectWillChange.send()
        
        // Delay the database refresh to allow for eventual consistency
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🔍 DEBUG: Delayed loadUserGames() call to refresh from database")
            // Note: This will be handled by ContentView's onAppear when switching tabs
        }
        
        print("🔍 DEBUG: ===== STANDARDIZED GAME CREATED CALLBACK END =====")
    }
    
    // MARK: - Game Creation Validation
    static func validateGameCreation(
        playerCount: Int,
        hostJoinAsPlayer: Bool = true
    ) -> (isValid: Bool, message: String?) {
        let totalPlayers = playerCount + (hostJoinAsPlayer ? 1 : 0)
        
        guard totalPlayers >= 2 else {
            return (false, "Please add at least two players to the game.")
        }
        
        return (true, nil)
    }
    
    // MARK: - Common Game Object Creation
    static func createGameObject(
        gameName: String?,
        hostUserID: String,
        playerIDs: [String],
        customRules: String? = nil,
        winCondition: WinCondition? = nil,
        maxScore: Int? = nil,
        maxRounds: Int? = nil
    ) -> Game {
        // Use provided values or fall back to defaults
        let finalWinCondition = winCondition ?? .highestScore
        let finalMaxScore = maxScore ?? 100
        let finalMaxRounds = maxRounds ?? 8
        
        return Game(
            gameName: gameName?.isEmpty == true ? nil : gameName,
            hostUserID: hostUserID,
            playerIDs: playerIDs,
            rounds: 1, // Start with 1 round for dynamic rounds
            customRules: customRules,
            finalScores: [],
            gameStatus: .active,
            winCondition: finalWinCondition,
            maxScore: finalMaxScore,
            maxRounds: finalMaxRounds,
            createdAt: Temporal.DateTime.now(),
            updatedAt: Temporal.DateTime.now()
        )
    }
    
    // MARK: - Database Game Creation
    static func saveGameToDatabase(_ game: Game) async throws -> Game {
        print("🔍 DEBUG: GameCreationUtils - Creating game with data: hostUserID=\(game.hostUserID), playerIDs=\(game.playerIDs), rounds=\(game.rounds)")
        
        let result = try await Amplify.API.mutate(request: .create(game))
        
        switch result {
        case .success(let createdGame):
            print("🔍 DEBUG: GameCreationUtils - Game created successfully with ID: \(createdGame.id)")
            return createdGame
        case .failure(let error):
            print("🔍 DEBUG: GameCreationUtils - Game creation failed with error: \(error)")
            throw error
        }
    }
}
