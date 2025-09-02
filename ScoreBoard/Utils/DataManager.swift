import Foundation
import Amplify
import Combine

// MARK: - Player Leaderboard Entry
struct PlayerLeaderboardEntry: Identifiable {
    let id = UUID()
    let nickname: String
    let playerID: String
    let totalWins: Int
    let totalGames: Int
    let winRate: Double
    let highestScoreWins: Int
    let lowestScoreWins: Int
    let gamesWon: [GameWinDetail]
}

// MARK: - Game Win Detail
struct GameWinDetail: Identifiable {
    let id = UUID()
    let gameID: String
    let gameName: String
    let winCondition: WinCondition
    let finalScore: Int
    let date: Date
    let totalPlayers: Int
}

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
        
        // Group games by completion status and calculate wins
        var playerStats: [String: PlayerStats] = [:]
        
        // Process completed games to determine winners
        for game in games where game.gameStatus == .completed {
            guard let winCondition = game.winCondition else { continue }
            
            // Get all scores for this game
            let gameScores = scores.filter { $0.gameID == game.id }
            guard !gameScores.isEmpty else { continue }
            
            // Determine winner based on win condition
            let winner: Score?
            switch winCondition {
            case .highestScore:
                winner = gameScores.max { $0.score < $1.score }
            case .lowestScore:
                winner = gameScores.min { $0.score < $1.score }
            }
            
            guard let winningScore = winner else { continue }
            let winnerPlayerID = winningScore.playerID
            
            // Initialize player stats if needed
            if playerStats[winnerPlayerID] == nil {
                playerStats[winnerPlayerID] = PlayerStats(playerID: winnerPlayerID)
            }
            
            // Update winner stats
            playerStats[winnerPlayerID]?.totalWins += 1
            playerStats[winnerPlayerID]?.gamesWon.append(GameWinDetail(
                gameID: game.id,
                gameName: game.gameName ?? "Untitled Game",
                winCondition: winCondition,
                finalScore: winningScore.score,
                date: game.createdAt.foundationDate ?? Date(),
                totalPlayers: game.playerIDs.count
            ))
            
            // Update win condition specific stats
            switch winCondition {
            case .highestScore:
                playerStats[winnerPlayerID]?.highestScoreWins += 1
            case .lowestScore:
                playerStats[winnerPlayerID]?.lowestScoreWins += 1
            }
        }
        
        // Calculate total games played for each player
        for score in scores {
            let playerID = score.playerID
            if playerStats[playerID] == nil {
                playerStats[playerID] = PlayerStats(playerID: playerID)
            }
            
            // Count unique games played
            if !playerStats[playerID]!.gamesPlayed.contains(score.gameID) {
                playerStats[playerID]!.gamesPlayed.insert(score.gameID)
            }
            

        }
        
        // Create leaderboard entries
        var leaderboardEntries: [PlayerLeaderboardEntry] = []
        
        for (playerID, stats) in playerStats {
            let totalGames = stats.gamesPlayed.count
            let winRate = totalGames > 0 ? Double(stats.totalWins) / Double(totalGames) : 0.0
            
            // Get player nickname
            let nickname: String
            if let user = users.first(where: { $0.id == playerID }) {
                nickname = user.username ?? "Unknown Player"
            } else {
                nickname = playerID.count <= 10 ? playerID : String(playerID.prefix(8))
            }
            
            leaderboardEntries.append(PlayerLeaderboardEntry(
                nickname: nickname,
                playerID: playerID,
                totalWins: stats.totalWins,
                totalGames: totalGames,
                winRate: winRate,
                highestScoreWins: stats.highestScoreWins,
                lowestScoreWins: stats.lowestScoreWins,
                gamesWon: stats.gamesWon
            ))
        }
        
        // Sort by total wins (descending), then by win rate (descending)
        leaderboardData = Array(leaderboardEntries
            .sorted { player1, player2 in
                if player1.totalWins != player2.totalWins {
                    return player1.totalWins > player2.totalWins
                }
                return player1.winRate > player2.winRate
            }
            .prefix(100)) // Limit to top 100 players
        
        isLoadingLeaderboard = false
    }
    
    // MARK: - Helper Struct for Leaderboard Calculation
    
    private struct PlayerStats {
        let playerID: String
        var totalWins: Int = 0
        var highestScoreWins: Int = 0
        var lowestScoreWins: Int = 0
        var gamesPlayed: Set<String> = []
        var gamesWon: [GameWinDetail] = []
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
