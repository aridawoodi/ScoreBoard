import Foundation
import Amplify
import Combine

// MARK: - Data Manager for Cost-Efficient AWS Usage
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // Published properties for real-time updates across all views
    @Published var games: [Game] = []
    @Published var scores: [Score] = []
    @Published var users: [User] = []
    @Published var leaderboardData: [PlayerLeaderboardEntry] = []
    
    // Cache management
    private var lastFetchTime: [String: Date] = [:]
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
    // Loading states
    @Published var isLoadingGames = false
    @Published var isLoadingScores = false
    @Published var isLoadingUsers = false
    @Published var isLoadingLeaderboard = false
    
    // Error handling
    @Published var lastError: String?
    
    private init() {
        // Load initial data
        Task {
            await loadAllData()
        }
    }
    
    // MARK: - Unified Data Loading
    
    /// Loads all data efficiently with minimal API calls
    @MainActor
    func loadAllData() async {
        await withTaskGroup(of: Void.self) { group in
            // Load games, scores, and users in parallel
            group.addTask { await self.loadGames() }
            group.addTask { await self.loadScores() }
            group.addTask { await self.loadUsers() }
        }
        
        // Calculate leaderboard after all data is loaded
        await calculateLeaderboard()
    }
    
    // MARK: - Individual Data Loading with Caching
    
    @MainActor
    func loadGames() async {
        guard shouldFetchData(for: "games") else { return }
        
        isLoadingGames = true
        do {
            let result = try await Amplify.API.query(request: .list(Game.self))
            switch result {
            case .success(let gamesList):
                games = Array(gamesList)
                lastFetchTime["games"] = Date()
                lastError = nil
            case .failure(let error):
                lastError = "Failed to load games: \(error.localizedDescription)"
                print("❌ Error loading games: \(error)")
            }
        } catch {
            lastError = "Failed to load games: \(error.localizedDescription)"
            print("❌ Error loading games: \(error)")
        }
        isLoadingGames = false
    }
    
    @MainActor
    func loadScores() async {
        guard shouldFetchData(for: "scores") else { return }
        
        isLoadingScores = true
        do {
            let result = try await Amplify.API.query(request: .list(Score.self))
            switch result {
            case .success(let scoresList):
                scores = Array(scoresList)
                lastFetchTime["scores"] = Date()
                lastError = nil
            case .failure(let error):
                lastError = "Failed to load scores: \(error.localizedDescription)"
                print("❌ Error loading scores: \(error)")
            }
        } catch {
            lastError = "Failed to load scores: \(error.localizedDescription)"
            print("❌ Error loading scores: \(error)")
        }
        isLoadingScores = false
    }
    
    @MainActor
    func loadUsers() async {
        guard shouldFetchData(for: "users") else { return }
        
        isLoadingUsers = true
        do {
            let result = try await Amplify.API.query(request: .list(User.self))
            switch result {
            case .success(let usersList):
                users = Array(usersList)
                lastFetchTime["users"] = Date()
                lastError = nil
            case .failure(let error):
                lastError = "Failed to load users: \(error.localizedDescription)"
                print("❌ Error loading users: \(error)")
            }
        } catch {
            lastError = "Failed to load users: \(error.localizedDescription)"
            print("❌ Error loading users: \(error)")
        }
        isLoadingUsers = false
    }
    
    // MARK: - Leaderboard Calculation
    
    @MainActor
    func calculateLeaderboard() async {
        isLoadingLeaderboard = true
        
        // Calculate total points for each player and track their games
        var playerPoints: [String: Int] = [:]
        var playerGames: [String: Set<String>] = [:]
        
        // Group scores by player and sum them, also track games
        for score in scores {
            let playerId = score.playerID
            playerPoints[playerId, default: 0] += score.score
            
            // Track games for this player
            if playerGames[playerId] == nil {
                playerGames[playerId] = Set<String>()
            }
            playerGames[playerId]?.insert(score.gameID)
        }
        
        // Create leaderboard entries with user information and game details
        var leaderboardEntries: [PlayerLeaderboardEntry] = []
        
        for (playerId, totalPoints) in playerPoints {
            // Get game names for this player
            let gameIds = playerGames[playerId] ?? Set<String>()
            let gameNames = gameIds.compactMap { gameId in
                games.first { $0.id == gameId }?.gameName ?? "None"
            }
            
            // Find user information
            if let user = users.first(where: { $0.id == playerId }) {
                leaderboardEntries.append(PlayerLeaderboardEntry(
                    nickname: user.username ?? "Unknown Player",
                    points: totalPoints,
                    games: gameNames
                ))
            } else {
                // Handle anonymous players
                let anonymousName = playerId.count <= 10 ? playerId : String(playerId.prefix(8))
                leaderboardEntries.append(PlayerLeaderboardEntry(
                    nickname: anonymousName,
                    points: totalPoints,
                    games: gameNames
                ))
            }
        }
        
        // Sort by points (descending) and take top players
        leaderboardData = Array(leaderboardEntries
            .sorted { $0.points > $1.points }
            .prefix(100)) // Limit to top 100 players
        
        isLoadingLeaderboard = false
    }
    
    // MARK: - Cache Management
    
    private func shouldFetchData(for key: String) -> Bool {
        guard let lastFetch = lastFetchTime[key] else { return true }
        return Date().timeIntervalSince(lastFetch) > cacheExpirationTime
    }
    
    func invalidateCache() {
        lastFetchTime.removeAll()
    }
    
    func invalidateCache(for key: String) {
        lastFetchTime.removeValue(forKey: key)
    }
    
    // MARK: - Data Access Methods
    
    func getGamesForUser(_ userId: String) -> [Game] {
        return games.filter { game in
            // Check if user is the host
            if game.hostUserID == userId {
                return true
            }
            
            // Check if user is a player using improved detection
            return isUserInGame(userId: userId, playerIDs: game.playerIDs)
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
    
    func getScoresForGame(_ gameId: String) -> [Score] {
        return scores.filter { $0.gameID == gameId }
    }
    
    func getScoresForPlayer(_ playerId: String) -> [Score] {
        return scores.filter { $0.playerID == playerId }
    }
    
    func getUser(_ userId: String) -> User? {
        return users.first { $0.id == userId }
    }
    
    func getPlayerName(_ playerId: String) -> String {
        if let user = getUser(playerId) {
            return user.username ?? "Unknown Player"
        }
        let anonymousName = playerId.count <= 10 ? playerId : String(playerId.prefix(8))
        return anonymousName
    }
    
    // MARK: - Real-time Updates
    
    func refreshData() async {
        invalidateCache()
        await loadAllData()
    }
    
    func refreshGames() async {
        invalidateCache(for: "games")
        await loadGames()
    }
    
    func refreshScores() async {
        invalidateCache(for: "scores")
        await loadScores()
        await calculateLeaderboard()
    }
    
    func refreshUsers() async {
        invalidateCache(for: "users")
        await loadUsers()
        await calculateLeaderboard()
    }
}

// MARK: - Player Leaderboard Entry
struct PlayerLeaderboardEntry: Identifiable {
    let id = UUID()
    let nickname: String
    let points: Int
    let games: [String]
} 
