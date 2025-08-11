//
//  GameModels.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation

// GameDetails Struct for Game Review
struct GameDetails {
    var rounds: [Round]
}

// Round Struct - Ensure 'id' is unique per round
struct Round: Identifiable {
    var id: Int  // Unique identifier for each round
    var number: Int  // Round number
    var scores: [PlayerScore]  // Use PlayerScore instead of Score to avoid ambiguity
}

// Make PlayerScore conform to Identifiable and Codable
struct PlayerScore: Identifiable, Codable {
    var id: String  // Unique identifier for each score
    var playerName: String
    var value: Int
}

// Player struct for game creation and editing
struct Player: Identifiable, Hashable {
    let id = UUID().uuidString
    var name: String
    var isRegistered: Bool
    var userId: String? // nil for anonymous players
    var email: String? // nil for anonymous players
}

// MARK: - Game Extensions
extension Game: Equatable {
    public static func == (lhs: Game, rhs: Game) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - User Extensions
extension User: Equatable, Hashable {
    public static func == (lhs: User, rhs: User) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
} 