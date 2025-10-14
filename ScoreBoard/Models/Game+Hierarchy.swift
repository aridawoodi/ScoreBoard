//
//  Game+Hierarchy.swift
//  ScoreBoard
//
//  Created by AI Assistant on 12/19/25.
//

import Foundation
import Amplify

// MARK: - Game Extensions for Player Hierarchy
extension Game {
    
    /// Get player hierarchy as a dictionary mapping parent player to child players
    func getPlayerHierarchy() -> [String: [String]] {
        guard let data = playerHierarchy?.data(using: .utf8) else { return [:] }
        return (try? JSONDecoder().decode([String: [String]].self, from: data)) ?? [:]
    }
    
    /// Set player hierarchy from a dictionary
    func setPlayerHierarchy(_ hierarchy: [String: [String]]) -> Game {
        var updatedGame = self
        if let data = try? JSONEncoder().encode(hierarchy) {
            updatedGame.playerHierarchy = String(data: data, encoding: .utf8)
        }
        return updatedGame
    }
    
    /// Check if this game uses player hierarchy
    var hasPlayerHierarchy: Bool {
        return !getPlayerHierarchy().isEmpty
    }
    
    /// Check if a player is a parent player in the hierarchy
    func isParentPlayer(_ playerID: String) -> Bool {
        return getPlayerHierarchy().keys.contains(playerID)
    }
    
    /// Get all child players for a given parent player
    func getChildPlayers(for parentPlayer: String) -> [String] {
        return getPlayerHierarchy()[parentPlayer] ?? []
    }
    
    /// Add a child player to a parent player
    func addChildPlayer(_ childPlayer: String, to parentPlayer: String) -> Game {
        var hierarchy = getPlayerHierarchy()
        if hierarchy[parentPlayer] == nil {
            hierarchy[parentPlayer] = []
        }
        if !hierarchy[parentPlayer]!.contains(childPlayer) {
            hierarchy[parentPlayer]!.append(childPlayer)
        }
        return setPlayerHierarchy(hierarchy)
    }
    
    /// Remove a child player from a parent player
    func removeChildPlayer(_ childPlayer: String, from parentPlayer: String) -> Game {
        var hierarchy = getPlayerHierarchy()
        hierarchy[parentPlayer]?.removeAll { $0 == childPlayer }
        return setPlayerHierarchy(hierarchy)
    }
    
    /// Get all child players across all parent players
    func getAllChildPlayers() -> [String] {
        return getPlayerHierarchy().values.flatMap { $0 }
    }
    
    /// Get parent player for a given child player
    /// Handles both "userId:username" format and plain userId/name formats
    func getParentPlayer(for childPlayer: String) -> String? {
        let hierarchy = getPlayerHierarchy()
        // Extract userId for comparison (handle "userId:username" format)
        let searchUserId = childPlayer.components(separatedBy: ":").first ?? childPlayer
        
        for (parent, children) in hierarchy {
            // Check for exact match or userId match
            for child in children {
                let childUserId = child.components(separatedBy: ":").first ?? child
                if childUserId == searchUserId {
                    return parent
                }
            }
        }
        return nil
    }
    
    /// Get parent player for a given child player (alias for compatibility)
    func getParentPlayer(forChild childPlayer: String) -> String? {
        return getParentPlayer(for: childPlayer)
    }
    
    /// Check if a user is a child player in this game
    /// Handles both "userId:username" format and plain userId/name formats
    func isChildPlayer(_ userId: String) -> Bool {
        return getParentPlayer(for: userId) != nil
    }
    
    /// Get display name for a player (parent name with child count if applicable)
    func getPlayerDisplayName(_ playerId: String) -> String {
        if hasPlayerHierarchy {
            let childCount = getChildPlayers(for: playerId).count
            if childCount > 0 {
                return "\(playerId) (\(childCount) players)"
            }
        }
        return playerId
    }
    
    /// Get all players that can edit scores (parent players only)
    func getScoreEditablePlayers() -> [String] {
        if hasPlayerHierarchy {
            return Array(getPlayerHierarchy().keys)
        }
        return playerIDs
    }
}

// MARK: - Player Hierarchy Models
struct PlayerHierarchy {
    let parentPlayer: String
    let childPlayers: [String]
    
    var displayName: String {
        if childPlayers.isEmpty {
            return parentPlayer
        }
        return "\(parentPlayer) (\(childPlayers.count) players)"
    }
    
    var totalPlayers: Int {
        return 1 + childPlayers.count // parent + children
    }
}

// MARK: - Helper functions for player hierarchy
extension Game {
    
    /// Convert player hierarchy to PlayerHierarchy objects
    func getPlayerHierarchyObjects() -> [PlayerHierarchy] {
        let hierarchy = getPlayerHierarchy()
        return hierarchy.map { parent, children in
            PlayerHierarchy(parentPlayer: parent, childPlayers: children)
        }.sorted { $0.parentPlayer < $1.parentPlayer }
    }
    
    /// Check if a user can edit scores for a specific player
    func canUserEditScores(for playerId: String, userId: String) -> Bool {
        if hasPlayerHierarchy {
            // User can edit if they are the parent player or a child of that parent
            return playerId == userId || getChildPlayers(for: playerId).contains(userId)
        }
        // For non-hierarchy games, user can only edit their own scores
        return playerId == userId
    }
    
    /// Get all users that can participate in this game
    func getAllParticipatingUsers() -> [String] {
        if hasPlayerHierarchy {
            return playerIDs + getAllChildPlayers()
        }
        return playerIDs
    }
}
