import Foundation
import SwiftUI
import Amplify

class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {}
    
    func loadUserAnalytics() async -> PlayerStats? {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            // Get current user ID using helper function that works for both guest and authenticated users
            guard let currentUserInfo = await getCurrentUser() else {
                print("🔍 DEBUG: Unable to get current user information")
                await MainActor.run {
                    self.isLoading = false
                    self.error = "Unable to get current user information"
                }
                return nil
            }
            
            let userId = currentUserInfo.userId
            let isGuest = currentUserInfo.isGuest
            
            print("🔍 DEBUG: Loading analytics for user: \(userId), isGuest: \(isGuest)")
            
            // Fetch all games where the user is a player
            let gamesResult = try await Amplify.API.query(request: .list(Game.self))
            
            switch gamesResult {
            case .success(let allGames):
                let userGames = allGames.filter { game in
                    // Check if user is the host
                    if game.hostUserID == userId {
                        return true
                    }
                    
                    // Check if user is a player using improved detection
                    return isUserInGame(userId: userId, playerIDs: game.playerIDs)
                }
                
                print("🔍 DEBUG: Found \(userGames.count) games for user")
                
                // Fetch scores for user's games only (server-side filtering)
                var allUserScores: [Score] = []
                
                // Fetch scores for each game individually to avoid fetching all scores
                for game in userGames {
                    let scoresQuery = Score.keys.gameID.eq(game.id)
                    let scoresResult = try await Amplify.API.query(request: .list(Score.self, where: scoresQuery))
                    
                    switch scoresResult {
                    case .success(let gameScores):
                        allUserScores.append(contentsOf: gameScores)
                    case .failure(let error):
                        print("🔍 DEBUG: Failed to fetch scores for game \(game.id): \(error)")
                    }
                }
                
                let userScores = allUserScores
                    
                print("🔍 DEBUG: Found \(userScores.count) scores for user's games")
                
                // Create real analytics from backend data
                let realStats = PlayerStats.from(games: userGames, scores: userScores, userId: userId)
                
                await MainActor.run {
                    self.isLoading = false
                }
                
                print("🔍 DEBUG: Created real analytics - Games: \(realStats.totalGames), Win Rate: \(Int(realStats.winRate * 100))%")
                
                return realStats
                
            case .failure(let error):
                print("🔍 DEBUG: Failed to fetch games: \(error)")
                await MainActor.run {
                    self.error = "Failed to load games: \(error.localizedDescription)"
                    self.isLoading = false
                }
                return nil
            }
            
        } catch {
            print("🔍 DEBUG: Error loading analytics: \(error)")
            await MainActor.run {
                self.error = "Failed to load analytics: \(error.localizedDescription)"
                self.isLoading = false
            }
            return nil
        }
    }
    
    /// Helper function to check if a user is in a game's player list
    /// This handles both registered users (direct user ID) and anonymous users (userID:displayName format)
    private func isUserInGame(userId: String, playerIDs: [String]) -> Bool {
        // Check for exact match (registered users)
        if playerIDs.contains(userId) {
            return true
        }
        
        // Check for prefix match (anonymous users with format "userID:displayName")
        let hasPrefixMatch = playerIDs.contains { playerID in
            playerID.hasPrefix(userId + ":")
        }
        
        if hasPrefixMatch {
            return true
        }
        
        // Additional check: look for any playerID that contains the user ID
        // This handles edge cases where the format might be different
        let hasContainedMatch = playerIDs.contains { playerID in
            playerID.contains(userId)
        }
        
        return hasContainedMatch
    }
}
