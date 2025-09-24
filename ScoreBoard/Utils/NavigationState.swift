//
//  NavigationState.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation
import Amplify

// MARK: - Navigation State Management
class NavigationState: ObservableObject {
    @Published var selectedGame: Game?
    @Published var userGames: [Game] = []
    @Published var isLoading = false
    @Published var shouldShowMainBoard = false
    @Published var isKeyboardActive = false
    @Published var showReadOnlyGameSheet = false
    @Published var selectedGameForReadOnly: Game?
    
    func clear() {
        selectedGame = nil
        userGames = []
        isLoading = false
        shouldShowMainBoard = false
        isKeyboardActive = false
        showReadOnlyGameSheet = false
        selectedGameForReadOnly = nil
    }
    
    var hasGames: Bool {
        !userGames.isEmpty
    }
    
    var gameCount: Int {
        userGames.count
    }
    
    var latestGame: Game? {
        let sortedGames = userGames.sorted {
            let lhs = $0.updatedAt ?? $0.createdAt ?? Temporal.DateTime.now()
            let rhs = $1.updatedAt ?? $1.createdAt ?? Temporal.DateTime.now()
            return lhs > rhs
        }
        let latest = sortedGames.first
        print("🔍 DEBUG: latestGame computed - found: \(latest?.id ?? "nil")")
        return latest
    }
    
    func refreshUserGames() async {
        await DataManager.shared.refreshGames()
        // Get updated games from DataManager using helper function
        if let currentUserInfo = await getCurrentUser() {
            let userId = currentUserInfo.userId
            let updatedGames = DataManager.shared.getGamesForUser(userId)
            await MainActor.run {
                self.userGames = updatedGames
            }
        }
    }
} 