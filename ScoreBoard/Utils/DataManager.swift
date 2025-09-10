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
    let gamesPlayed: [GamePlayDetail]
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

// MARK: - Game Play Detail
struct GamePlayDetail: Identifiable {
    let id = UUID()
    let gameID: String
    let gameName: String
    let winCondition: WinCondition
    let finalScore: Int
    let date: Date
    let totalPlayers: Int
    let isWin: Bool
}

// MARK: - Data Manager for Cost-Efficient AWS Usage
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // Published properties for real-time updates across all views
    @Published var games: [Game] = []
    @Published var scores: [Score] = []
    @Published var users: [User] = []
    @Published var leaderboardData: [PlayerLeaderboardEntry] = []
    
    // User-specific leaderboard data (more efficient)
    @Published var userLeaderboardData: [PlayerLeaderboardEntry] = []
    private var currentUserId: String?
    
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
    
    // MARK: - User-Specific Leaderboard (Cost Efficient)
    
    @MainActor
    func loadUserLeaderboard(for userId: String) async {
        print("🔍 DEBUG: loadUserLeaderboard called for user: \(userId)")
        guard shouldFetchData(for: "userLeaderboard_\(userId)") else { 
            print("🔍 DEBUG: loadUserLeaderboard - using cached data for user: \(userId)")
            return 
        }
        
        print("🔍 DEBUG: loadUserLeaderboard - fetching fresh data for user: \(userId)")
        currentUserId = userId
        isLoadingLeaderboard = true
        
        do {
            // Step 1: Get all games where the user participated (more efficient than loading all games)
            let userGames = try await getUserGamesFromBackend(userId: userId)
            print("🔍 DEBUG: Found \(userGames.count) games where user \(userId) participated")
            
            // Step 2: Get scores only for those games
            let userScores = try await getScoresForGames(userGames)
            print("🔍 DEBUG: Found \(userScores.count) scores for user's games")
            
            // Step 3: Get all users (needed for usernames)
            let allUsers = try await getAllUsers()
            
            // Step 4: Calculate leaderboard from this focused data
            await calculateUserLeaderboard(games: userGames, scores: userScores, users: allUsers, currentUserId: userId)
            
            lastFetchTime["userLeaderboard_\(userId)"] = Date()
            lastError = nil
            
        } catch {
            lastError = "Failed to load user leaderboard: \(error.localizedDescription)"
            print("❌ Error loading user leaderboard: \(error)")
        }
        
        isLoadingLeaderboard = false
    }
    
    // MARK: - Backend Queries (Cost Optimized)
    
    private func getUserGamesFromBackend(userId: String) async throws -> [Game] {
        // Query games where user is host
        let hostGamesQuery = Game.keys.hostUserID.eq(userId)
        let hostGamesResult = try await Amplify.API.query(request: .list(Game.self, where: hostGamesQuery))
        
        var allUserGames: [Game] = []
        
        switch hostGamesResult {
        case .success(let games):
            allUserGames.append(contentsOf: games)
            print("🔍 DEBUG: Found \(games.count) games where user is host")
        case .failure(let error):
            print("❌ Error loading host games: \(error)")
        }
        
        // Query games where user is a player (this is more complex and might need multiple queries)
        // For now, we'll use a broader query and filter locally
        let allGamesResult = try await Amplify.API.query(request: .list(Game.self))
        
        switch allGamesResult {
        case .success(let allGames):
            let playerGames = allGames.filter { game in
                isUserInGame(userId: userId, playerIDs: game.playerIDs)
            }
            allUserGames.append(contentsOf: playerGames)
            print("🔍 DEBUG: Found \(playerGames.count) games where user is a player")
        case .failure(let error):
            print("❌ Error loading all games: \(error)")
        }
        
        // Remove duplicates and filter to completed games only
        let uniqueGames = Array(Set(allUserGames.map { $0.id }))
            .compactMap { gameId in allUserGames.first { $0.id == gameId } }
        
        // Debug: Print game statuses
        for game in uniqueGames {
            print("🔍 DEBUG: Game \(game.id) status: \(game.gameStatus)")
        }
        
        let completedGames = uniqueGames.filter { $0.gameStatus == .completed }
        print("🔍 DEBUG: Found \(completedGames.count) completed games where user \(userId) participated")
        
        // Temporary workaround: If no completed games found, check if there are games with scores
        // This handles cases where game status hasn't been updated yet
        if completedGames.isEmpty {
            print("🔍 DEBUG: No completed games found, checking for games with scores...")
            // For now, return all unique games and let the score filtering handle it
            return uniqueGames
        }
        
        return completedGames
    }
    
    private func getScoresForGames(_ games: [Game]) async throws -> [Score] {
        var allScores: [Score] = []
        
        // Query scores for each game individually to be more efficient
        for game in games {
            let scoresQuery = Score.keys.gameID.eq(game.id)
            let scoresResult = try await Amplify.API.query(request: .list(Score.self, where: scoresQuery))
            
            switch scoresResult {
            case .success(let gameScores):
                allScores.append(contentsOf: gameScores)
            case .failure(let error):
                print("❌ Error loading scores for game \(game.id): \(error)")
            }
        }
        
        return allScores
    }
    
    private func getAllUsers() async throws -> [User] {
        let result = try await Amplify.API.query(request: .list(User.self))
        switch result {
        case .success(let users):
            return Array(users)
        case .failure(let error):
            throw error
        }
    }
    
    private func calculateUserLeaderboard(games: [Game], scores: [Score], users: [User], currentUserId: String) async {
        var playerStats: [String: PlayerStats] = [:]
        
        print("🔍 DEBUG: calculateUserLeaderboard - Processing \(games.count) games with \(scores.count) scores")
        
        // Process completed games to determine winners and track all games played
        for game in games {
            guard let winCondition = game.winCondition else { 
                print("🔍 DEBUG: Game \(game.id) has no win condition, skipping")
                continue 
            }
            
            // Get all scores for this game
            let gameScores = scores.filter { $0.gameID == game.id }
            print("🔍 DEBUG: Game \(game.id) has \(gameScores.count) scores")
            guard !gameScores.isEmpty else { 
                print("🔍 DEBUG: Game \(game.id) has no scores, skipping")
                continue 
            }
            
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
            
            // Process all players in this game
            for score in gameScores {
                let playerID = score.playerID
                
                // Initialize player stats if needed
                if playerStats[playerID] == nil {
                    playerStats[playerID] = PlayerStats(playerID: playerID)
                }
                
                // Track all games played
                let isWin = playerID == winnerPlayerID
                playerStats[playerID]?.allGamesPlayed.append(GamePlayDetail(
                    gameID: game.id,
                    gameName: game.gameName ?? "Untitled Game",
                    winCondition: winCondition,
                    finalScore: score.score,
                    date: game.createdAt.foundationDate ?? Date(),
                    totalPlayers: game.playerIDs.count,
                    isWin: isWin
                ))
                
                // Update winner stats
                if isWin {
                    playerStats[playerID]?.totalWins += 1
                    playerStats[playerID]?.gamesWon.append(GameWinDetail(
                        gameID: game.id,
                        gameName: game.gameName ?? "Untitled Game",
                        winCondition: winCondition,
                        finalScore: score.score,
                        date: game.createdAt.foundationDate ?? Date(),
                        totalPlayers: game.playerIDs.count
                    ))
                    
                    // Update win condition specific stats
                    switch winCondition {
                    case .highestScore:
                        playerStats[playerID]?.highestScoreWins += 1
                    case .lowestScore:
                        playerStats[playerID]?.lowestScoreWins += 1
                    }
                }
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
                gamesWon: stats.gamesWon,
                gamesPlayed: stats.allGamesPlayed
            ))
        }
        
        // Sort by total wins (descending), then by win rate (descending)
        userLeaderboardData = Array(leaderboardEntries
            .sorted { player1, player2 in
                if player1.totalWins != player2.totalWins {
                    return player1.totalWins > player2.totalWins
                }
                return player1.winRate > player2.winRate
            }
            .prefix(100)) // Limit to top 100 players
    }
    
    // MARK: - Legacy Leaderboard Calculation (for backward compatibility)
    
    @MainActor
    func calculateLeaderboard() async {
        isLoadingLeaderboard = true
        
        // Group games by completion status and calculate wins
        var playerStats: [String: PlayerStats] = [:]
        
        // Process completed games to determine winners and track all games played
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
            
            // Process all players in this game
            for score in gameScores {
                let playerID = score.playerID
                
                // Initialize player stats if needed
                if playerStats[playerID] == nil {
                    playerStats[playerID] = PlayerStats(playerID: playerID)
                }
                
                // Track all games played
                let isWin = playerID == winnerPlayerID
                playerStats[playerID]?.allGamesPlayed.append(GamePlayDetail(
                    gameID: game.id,
                    gameName: game.gameName ?? "Untitled Game",
                    winCondition: winCondition,
                    finalScore: score.score,
                    date: game.createdAt.foundationDate ?? Date(),
                    totalPlayers: game.playerIDs.count,
                    isWin: isWin
                ))
                
                // Update winner stats
                if isWin {
                    playerStats[playerID]?.totalWins += 1
                    playerStats[playerID]?.gamesWon.append(GameWinDetail(
                        gameID: game.id,
                        gameName: game.gameName ?? "Untitled Game",
                        winCondition: winCondition,
                        finalScore: score.score,
                        date: game.createdAt.foundationDate ?? Date(),
                        totalPlayers: game.playerIDs.count
                    ))
                    
                    // Update win condition specific stats
                    switch winCondition {
                    case .highestScore:
                        playerStats[playerID]?.highestScoreWins += 1
                    case .lowestScore:
                        playerStats[playerID]?.lowestScoreWins += 1
                    }
                }
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
                gamesWon: stats.gamesWon,
                gamesPlayed: stats.allGamesPlayed
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
        var allGamesPlayed: [GamePlayDetail] = []
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
