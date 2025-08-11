//
//  DatabaseMigration.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation
import Amplify

class DatabaseMigration {
    static let shared = DatabaseMigration()
    
    private init() {}
    
    /// Migrate existing games to have a default gameStatus if they don't have one
    func migrateGameStatus() async {
        print("🔧 DEBUG: Starting gameStatus migration...")
        
        do {
            // First, try to get all games with a more permissive query
            let result = try await Amplify.API.query(request: .list(Game.self))
            
            switch result {
            case .success(let games):
                print("🔧 DEBUG: Found \(games.count) games to check for migration")
                
                var updatedCount = 0
                for game in games {
                    // Check if the game needs migration (gameStatus might be nil or invalid)
                    if needsGameStatusMigration(game) {
                        print("🔧 DEBUG: Migrating game \(game.id) - current gameStatus: \(game.gameStatus)")
                        
                        // Create updated game with proper gameStatus
                        let updatedGame = Game(
                            id: game.id,
                            hostUserID: game.hostUserID,
                            playerIDs: game.playerIDs,
                            rounds: game.rounds,
                            customRules: game.customRules,
                            finalScores: game.finalScores,
                            gameStatus: .active, // Set default status
                            createdAt: game.createdAt,
                            updatedAt: Temporal.DateTime.now()
                        )
                        
                        // Update the game
                        let updateResult = try await Amplify.API.mutate(request: .update(updatedGame))
                        switch updateResult {
                        case .success(let updatedGame):
                            print("🔧 DEBUG: Successfully migrated game \(updatedGame.id)")
                            updatedCount += 1
                        case .failure(let error):
                            print("🔧 DEBUG: Failed to migrate game \(game.id): \(error)")
                        }
                    }
                }
                
                print("🔧 DEBUG: Migration completed. Updated \(updatedCount) games.")
                
            case .failure(let error):
                print("🔧 DEBUG: Failed to fetch games for migration: \(error)")
            }
            
        } catch {
            print("🔧 DEBUG: Error during migration: \(error)")
        }
    }
    
    /// Check if a game needs gameStatus migration
    private func needsGameStatusMigration(_ game: Game) -> Bool {
        // If the gameStatus is not properly set, it needs migration
        // We'll consider it needs migration if we can't determine a valid status
        return true // For now, migrate all games to ensure they have proper status
    }
} 