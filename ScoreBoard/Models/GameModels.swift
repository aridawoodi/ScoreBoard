//
//  GameModels.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation

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