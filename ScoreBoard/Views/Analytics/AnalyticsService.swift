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
            
            // Fetch all games where the user is actually a player (not just the host)
            let gamesResult = try await Amplify.API.query(request: .list(Game.self))
            
            switch gamesResult {
            case .success(let allGames):
                let userGames = allGames.filter { game in
                    // Only include games where the user is actually a player (not just the host)
                    return isUserInGame(userId: userId, playerIDs: game.playerIDs)
                }
                
                print("🔍 DEBUG: Found \(userGames.count) games where user is a player")
                
                // Fetch scores for user's games only (server-side filtering)
                var allUserScores: [Score] = []
                
                // Fetch scores for each game individually to avoid fetching all scores
                for game in userGames {
                    let scoresQuery = Score.keys.gameID.eq(game.id)
                    let scoresResult = try await Amplify.API.query(request: .list(Score.self, where: scoresQuery))
                    
                    switch scoresResult {
                    case .success(let gameScores):
                        // Filter to only include scores for the current user
                        let userGameScores = gameScores.filter { score in
                            score.playerID == userId
                        }
                        allUserScores.append(contentsOf: userGameScores)
                    case .failure(let error):
                        print("🔍 DEBUG: Failed to fetch scores for game \(game.id): \(error)")
                    }
                }
                
                let userScores = allUserScores
                    
                print("🔍 DEBUG: Found \(userScores.count) scores for user's games")
                print("🔍 DEBUG: User scores details: \(userScores.map { "Player: \($0.playerID), Score: \($0.score), Round: \($0.roundNumber)" })")
                
                // Create real analytics from backend data
                print("🔍 DEBUG: AnalyticsService - About to create PlayerStats from \(userGames.count) games and \(userScores.count) scores for user \(userId)")
                
                // Debug: Print game details
                for game in userGames {
                    print("🔍 DEBUG: AnalyticsService - Game \(game.id): status=\(game.gameStatus), winCondition=\(game.winCondition?.rawValue ?? "nil"), playerIDs=\(game.playerIDs)")
                }
                
                // Debug: Print score details
                for score in userScores {
                    print("🔍 DEBUG: AnalyticsService - Score: gameID=\(score.gameID), playerID=\(score.playerID), score=\(score.score), round=\(score.roundNumber)")
                }
                
                guard let realStats = PlayerStats.from(games: userGames, scores: userScores, userId: userId) else {
                    // No data available, return nil to show sample analytics
                    print("🔍 DEBUG: AnalyticsService - No games/scores found - returning nil for sample analytics")
                    await MainActor.run {
                        self.isLoading = false
                    }
                    return nil
                }
                
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
