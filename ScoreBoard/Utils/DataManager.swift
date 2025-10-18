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
    @Published var currentUserId: String?
    
    // Reactive leaderboard calculation - automatically updates when games/scores change
    @Published var reactiveLeaderboardData: [PlayerLeaderboardEntry] = []
    
    // Reactive analytics data - automatically updates when games/scores change
    @Published var reactiveAnalyticsData: Any?
    
    private var cancellables = Set<AnyCancellable>()
    
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
        // Setup reactive leaderboard calculation
        setupReactiveLeaderboard()
        
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
        print("🔍 DEBUG: DataManager.loadGames() called")
        print("🔍 DEBUG: shouldFetchData(for: 'games'): \(shouldFetchData(for: "games"))")
        
        guard shouldFetchData(for: "games") else { 
            print("🔍 DEBUG: Skipping games fetch due to cache")
            return 
        }
        
        print("🔍 DEBUG: Fetching games from backend...")
        isLoadingGames = true
        do {
            let result = try await Amplify.API.query(request: .list(Game.self))
            switch result {
            case .success(let gamesList):
                games = Array(gamesList)
                lastFetchTime["games"] = Date()
                lastError = nil
                print("🔍 DEBUG: Successfully loaded \(games.count) games from backend")
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
        print("🔍 DEBUG: DataManager.loadScores() called")
        print("🔍 DEBUG: shouldFetchData(for: 'scores'): \(shouldFetchData(for: "scores"))")
        
        guard shouldFetchData(for: "scores") else { 
            print("🔍 DEBUG: Skipping scores fetch due to cache")
            return 
        }
        
        print("🔍 DEBUG: Fetching scores from backend...")
        isLoadingScores = true
        do {
            let result = try await Amplify.API.query(request: .list(Score.self))
            switch result {
            case .success(let scoresList):
                scores = Array(scoresList)
                lastFetchTime["scores"] = Date()
                lastError = nil
                print("🔍 DEBUG: Successfully loaded \(scores.count) scores from backend")
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
        print("🔍 DEBUG: DataManager.loadUsers() called")
        print("🔍 DEBUG: shouldFetchData(for: 'users'): \(shouldFetchData(for: "users"))")
        
        guard shouldFetchData(for: "users") else { 
            print("🔍 DEBUG: Skipping users fetch due to cache")
            return 
        }
        
        print("🔍 DEBUG: Fetching users from backend...")
        isLoadingUsers = true
        do {
            let result = try await Amplify.API.query(request: .list(User.self))
            switch result {
            case .success(let usersList):
                users = Array(usersList)
                lastFetchTime["users"] = Date()
                lastError = nil
                print("🔍 DEBUG: Successfully loaded \(users.count) users from backend")
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
                isUserInGame(userId: userId, playerIDs: game.playerIDs, game: game)
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
            
            // Calculate total scores for each player in this game (sum across all rounds)
            var playerTotalScoresInGame: [String: Int] = [:]
            for score in gameScores {
                playerTotalScoresInGame[score.playerID, default: 0] += score.score
            }
            
            // Get unique player IDs in this game
            let uniquePlayerIDs = Set(gameScores.map { $0.playerID })
            
            // Process all players in this game (once per player, not per score)
            for playerID in uniquePlayerIDs {
                // Initialize player stats if needed
                if playerStats[playerID] == nil {
                    playerStats[playerID] = PlayerStats(playerID: playerID)
                }
                
                // Track all games played
                let isWin = playerID == winnerPlayerID
                let playerTotalScore = playerTotalScoresInGame[playerID] ?? 0
                
                playerStats[playerID]?.allGamesPlayed.append(GamePlayDetail(
                    gameID: game.id,
                    gameName: game.gameName ?? "Untitled Game",
                    winCondition: winCondition,
                    finalScore: playerTotalScore,  // Total score across all rounds
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
                        finalScore: playerTotalScore,  // Total score across all rounds
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
            
            // Calculate total scores for each player in this game (sum across all rounds)
            var playerTotalScoresInGame: [String: Int] = [:]
            for score in gameScores {
                playerTotalScoresInGame[score.playerID, default: 0] += score.score
            }
            
            // Get unique player IDs in this game
            let uniquePlayerIDs = Set(gameScores.map { $0.playerID })
            
            // Process all players in this game (once per player, not per score)
            for playerID in uniquePlayerIDs {
                // Initialize player stats if needed
                if playerStats[playerID] == nil {
                    playerStats[playerID] = PlayerStats(playerID: playerID)
                }
                
                // Track all games played
                let isWin = playerID == winnerPlayerID
                let playerTotalScore = playerTotalScoresInGame[playerID] ?? 0
                
                playerStats[playerID]?.allGamesPlayed.append(GamePlayDetail(
                    gameID: game.id,
                    gameName: game.gameName ?? "Untitled Game",
                    winCondition: winCondition,
                    finalScore: playerTotalScore,  // Total score across all rounds
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
                        finalScore: playerTotalScore,  // Total score across all rounds
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
        print("🔍 DEBUG: getGamesForUser called for user: \(userId)")
        print("🔍 DEBUG: Total games available: \(games.count)")
        
        let userGames = games.filter { game in
            print("🔍 DEBUG: Checking game \(game.id) - hostUserID: \(game.hostUserID), playerIDs: \(game.playerIDs)")
            
            // Check if user is the host
            if game.hostUserID == userId {
                print("🔍 DEBUG: User \(userId) is host of game \(game.id)")
                return true
            }
            
            // Check if user is a player using improved detection
            let isPlayer = isUserInGame(userId: userId, playerIDs: game.playerIDs, game: game)
            if isPlayer {
                print("🔍 DEBUG: User \(userId) is player in game \(game.id)")
            }
            return isPlayer
        }
        
        print("🔍 DEBUG: getGamesForUser found \(userGames.count) games for user \(userId)")
        return userGames
    }
    
    /// Helper function to check if a user is in a game's player list
    /// This handles both registered users (direct user ID) and anonymous users (userID:displayName format)
    /// Also checks player hierarchy for child players in hierarchy games
    private func isUserInGame(userId: String, playerIDs: [String], game: Game? = nil) -> Bool {
        print("🔍 DEBUG: isUserInGame checking user \(userId) in playerIDs: \(playerIDs)")
        
        // Check for exact match (registered users)
        if playerIDs.contains(userId) {
            print("🔍 DEBUG: Found exact match for user \(userId)")
            return true
        }
        
        // Check for prefix match (anonymous users with format "userID:displayName")
        let hasPrefixMatch = playerIDs.contains { playerID in
            playerID.hasPrefix(userId + ":")
        }
        
        if hasPrefixMatch {
            print("🔍 DEBUG: Found prefix match for user \(userId)")
            return true
        }
        
        // Additional check: look for any playerID that contains the user ID
        // This handles edge cases where the format might be different
        let hasContainedMatch = playerIDs.contains { playerID in
            playerID.contains(userId)
        }
        
        if hasContainedMatch {
            print("🔍 DEBUG: Found contained match for user \(userId)")
            return true
        }
        
        // Check player hierarchy for child players (hierarchy games)
        if let game = game, game.hasPlayerHierarchy {
            let hierarchy = game.getPlayerHierarchy()
            let allChildPlayers = hierarchy.values.flatMap { $0 }
            
            // Compare by userId (extract from "userId:username" format)
            let hasChildMatch = allChildPlayers.contains { childPlayer in
                let childUserId = childPlayer.components(separatedBy: ":").first ?? childPlayer
                return childUserId == userId || childPlayer.hasPrefix(userId + ":")
            }
            
            if hasChildMatch {
                print("🔍 DEBUG: Found user \(userId) as child player in hierarchy")
                return true
            }
        }
        
        print("🔍 DEBUG: No match found for user \(userId)")
        return false
    }
    
    func getScoresForGame(_ gameId: String) -> [Score] {
        return scores.filter { $0.gameID == gameId }
    }
    
    func getScoresForPlayer(_ playerId: String) -> [Score] {
        var playerScores = scores.filter { $0.playerID == playerId }
        
        // For hierarchy games, also include scores from parent team if player is a child player
        for game in games {
            if game.hasPlayerHierarchy {
                let hierarchy = game.getPlayerHierarchy()
                // Check if the player is a child player and get their parent team's scores
                for (parentID, childPlayers) in hierarchy {
                    // Compare by userId (extract from "userId:username" format)
                    let hasMatch = childPlayers.contains { childPlayer in
                        let childUserId = childPlayer.components(separatedBy: ":").first ?? childPlayer
                        return childUserId == playerId
                    }
                    
                    if hasMatch {
                        let parentScores = scores.filter { $0.playerID == parentID && $0.gameID == game.id }
                        playerScores.append(contentsOf: parentScores)
                    }
                }
            }
        }
        
        return playerScores
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
    
    // MARK: - Analytics Data Generation (Cost-Efficient)
    
    /// Generates analytics data for a specific user using cached data (no API calls)
    func generateUserAnalytics(for userId: String) -> Any? {
        print("🔍 DEBUG: DataManager.generateUserAnalytics called for user: \(userId)")
        
        // Get user's games from cached data
        let userGames = getGamesForUser(userId)
        print("🔍 DEBUG: DataManager.generateUserAnalytics - Found \(userGames.count) games for user")
        
        // Get ALL scores for the user's games (not just the user's scores)
        // This is needed to determine winners correctly by comparing against all players/teams
        var allScoresForUserGames: [Score] = []
        for game in userGames {
            let gameScores = scores.filter { $0.gameID == game.id }
            allScoresForUserGames.append(contentsOf: gameScores)
        }
        
        print("🔍 DEBUG: DataManager.generateUserAnalytics - Found \(allScoresForUserGames.count) total scores across user's games")
        
        // Use the same logic as AnalyticsService but with cached data
        guard !userGames.isEmpty, !allScoresForUserGames.isEmpty else {
            print("🔍 DEBUG: DataManager.generateUserAnalytics - No data available for user")
            return nil
        }
        
        // Return the raw data for AnalyticsTabView to process
        print("🔍 DEBUG: DataManager.generateUserAnalytics - Successfully generated analytics data for user")
        return ["games": userGames, "scores": allScoresForUserGames, "userId": userId]
    }
    
    // MARK: - Reactive Leaderboard System
    
    /// Sets up reactive leaderboard calculation that automatically updates when games or scores change
    private func setupReactiveLeaderboard() {
        // Combine games, scores, and currentUserId publishers to trigger leaderboard recalculation
        Publishers.CombineLatest3($games, $scores, $currentUserId)
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main) // Debounce to avoid excessive calculations
            .sink { [weak self] games, scores, currentUserId in
                Task { @MainActor in
                    await self?.calculateReactiveLeaderboard(games: games, scores: scores, currentUserId: currentUserId)
                    // Also calculate reactive analytics data
                    await self?.calculateReactiveAnalytics(games: games, scores: scores, currentUserId: currentUserId)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Calculates leaderboard reactively using existing data (no additional API calls)
    @MainActor
    private func calculateReactiveLeaderboard(games: [Game], scores: [Score], currentUserId: String?) async {
        print("🔍 DEBUG: DataManager - Reactive leaderboard calculation triggered")
        print("🔍 DEBUG: DataManager - Games count: \(games.count), Scores count: \(scores.count), Current user: \(currentUserId ?? "nil")")
        
        // If no current user, clear the leaderboard
        guard let currentUserId = currentUserId else {
            print("🔍 DEBUG: DataManager - No current user, clearing leaderboard")
            reactiveLeaderboardData = []
            return
        }
        
        // Filter games to only include those where the current user is host or player
        let userGames = games.filter { game in
            // Check if user is the host
            if game.hostUserID == currentUserId {
                return true
            }
            
            // Check if user is a player using improved detection
            return isUserInGame(userId: currentUserId, playerIDs: game.playerIDs, game: game)
        }
        
        print("🔍 DEBUG: DataManager - Filtered to \(userGames.count) games where user \(currentUserId) participated")
        
        // Filter scores to only include those for the user's games
        let userGameIds = Set(userGames.map { $0.id })
        let userScores = scores.filter { userGameIds.contains($0.gameID) }
        
        print("🔍 DEBUG: DataManager - Filtered to \(userScores.count) scores for user's games")
        
        // Debug: Print all game statuses
        for game in userGames {
            print("🔍 DEBUG: DataManager - User game \(game.id) status: \(game.gameStatus)")
        }
        
        // Only calculate if we have data
        guard !userGames.isEmpty && !userScores.isEmpty else { 
            print("🔍 DEBUG: DataManager - Skipping leaderboard calculation (no user data)")
            reactiveLeaderboardData = []
            return 
        }
        
        // Reset player stats for each calculation to avoid double counting
        var playerStats: [String: PlayerStats] = [:]
        
        // Process completed games to determine winners
        let completedGames = userGames.filter { $0.gameStatus == .completed }
        print("🔍 DEBUG: DataManager - Found \(completedGames.count) completed games out of \(userGames.count) total user games")
        
        // Debug: Check for duplicate games and deduplicate if needed
        let gameIds = completedGames.map { $0.id }
        let uniqueGameIds = Set(gameIds)
        if gameIds.count != uniqueGameIds.count {
            print("🔍 DEBUG: DataManager - WARNING: Found duplicate games in completedGames array!")
            print("🔍 DEBUG: DataManager - Game IDs: \(gameIds)")
            print("🔍 DEBUG: DataManager - Unique Game IDs: \(Array(uniqueGameIds))")
        }
        
        // Deduplicate games by ID to prevent double counting
        let uniqueCompletedGames = Array(Dictionary(grouping: completedGames, by: { $0.id }).compactMapValues { $0.first }.values)
        print("🔍 DEBUG: DataManager - After deduplication: \(uniqueCompletedGames.count) unique completed games")
        
        // Track processed games to avoid double counting
        var processedGames: Set<String> = []
        
        for game in uniqueCompletedGames {
            print("🔍 DEBUG: DataManager - Processing completed game ID: \(game.id), status: \(game.gameStatus)")
            print("🔍 DEBUG: DataManager - Game \(game.id) playerIDs: \(game.playerIDs)")
            
            // Check if we've already processed this game
            if processedGames.contains(game.id) {
                print("🔍 DEBUG: DataManager - WARNING: Game \(game.id) already processed! Skipping to avoid double counting.")
                continue
            }
            
            // Mark this game as processed
            processedGames.insert(game.id)
            guard let winCondition = game.winCondition else { 
                print("🔍 DEBUG: DataManager - Game \(game.id) has no win condition, skipping")
                continue 
            }
            
            // Get all scores for this game
            let gameScores = userScores.filter { $0.gameID == game.id }
            print("🔍 DEBUG: DataManager - Game \(game.id) has \(gameScores.count) scores")
            guard !gameScores.isEmpty else { 
                print("🔍 DEBUG: DataManager - Game \(game.id) has no scores, skipping")
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
            
            guard let winningScore = winner else { 
                print("🔍 DEBUG: DataManager - No clear winner for game ID: \(game.id)")
                continue 
            }
            let winnerPlayerID = winningScore.playerID
            print("🔍 DEBUG: DataManager - Game \(game.id) winner ID: \(winnerPlayerID)")
            
            // Initialize player stats for the winner if needed
            if playerStats[winnerPlayerID] == nil {
                playerStats[winnerPlayerID] = PlayerStats(playerID: winnerPlayerID)
            }
            
            // Increment total wins for the winner ONCE per game
            let beforeWins = playerStats[winnerPlayerID]?.totalWins ?? 0
            playerStats[winnerPlayerID]?.totalWins += 1
            let afterWins = playerStats[winnerPlayerID]?.totalWins ?? 0
            let nickname = users.first(where: { $0.id == winnerPlayerID })?.username ?? winnerPlayerID
            print("🔍 DEBUG: DataManager - After processing game \(game.id), \(winnerPlayerID) (nickname: \(nickname)) now has \(afterWins) wins (was \(beforeWins))")
            
            // Calculate total score for the winner (sum of all rounds)
            let winnerTotalScore = gameScores
                .filter { $0.playerID == winnerPlayerID }
                .reduce(0) { $0 + $1.score }
            
            // Add to gamesWon list for the winner
            playerStats[winnerPlayerID]?.gamesWon.append(GameWinDetail(
                gameID: game.id,
                gameName: game.gameName ?? "Untitled Game",
                winCondition: winCondition,
                finalScore: winnerTotalScore,  // Total score across all rounds
                date: game.createdAt.foundationDate ?? Date(),
                totalPlayers: game.playerIDs.count
            ))
            
            // Update win condition specific stats for the winner
            switch winCondition {
            case .highestScore:
                playerStats[winnerPlayerID]?.highestScoreWins += 1
            case .lowestScore:
                playerStats[winnerPlayerID]?.lowestScoreWins += 1
            }
            
            // Process all players in this game for participation tracking
            for playerIDInGame in game.playerIDs {
                if playerStats[playerIDInGame] == nil {
                    playerStats[playerIDInGame] = PlayerStats(playerID: playerIDInGame)
                }
                playerStats[playerIDInGame]?.gamesPlayed.insert(game.id)
                
                // Calculate total score for this player (sum of all rounds)
                let playerTotalScore = gameScores
                    .filter { $0.playerID == playerIDInGame }
                    .reduce(0) { $0 + $1.score }
                
                // Add to allGamesPlayed for detailed tracking
                let isWin = playerIDInGame == winnerPlayerID
                playerStats[playerIDInGame]?.allGamesPlayed.append(GamePlayDetail(
                    gameID: game.id,
                    gameName: game.gameName ?? "Untitled Game",
                    winCondition: winCondition,
                    finalScore: playerTotalScore,  // Total score across all rounds
                    date: game.createdAt.foundationDate ?? Date(),
                    totalPlayers: game.playerIDs.count,
                    isWin: isWin
                ))
            }
        }
        
        
        // Debug: Print final playerStats before creating leaderboard entries
        print("🔍 DEBUG: DataManager - Final playerStats dictionary:")
        for (playerID, stats) in playerStats {
            print("🔍 DEBUG: DataManager - Player \(playerID): \(stats.totalWins) wins, \(stats.gamesPlayed.count) games played")
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
        reactiveLeaderboardData = Array(leaderboardEntries
            .sorted { player1, player2 in
                if player1.totalWins != player2.totalWins {
                    return player1.totalWins > player2.totalWins
                }
                return player1.winRate > player2.winRate
            }
            .prefix(100)) // Limit to top 100 players
        
        print("🔍 DEBUG: DataManager - Reactive leaderboard calculation completed with \(reactiveLeaderboardData.count) entries")
        for (index, entry) in reactiveLeaderboardData.enumerated() {
            print("🔍 DEBUG: DataManager - Leaderboard entry \(index): \(entry.nickname) with \(entry.totalWins) wins")
        }
    }
    
    /// Calculates analytics data reactively using existing data (no additional API calls)
    @MainActor
    private func calculateReactiveAnalytics(games: [Game], scores: [Score], currentUserId: String?) async {
        print("🔍 DEBUG: DataManager - Reactive analytics calculation triggered")
        
        // If no current user, clear the analytics data
        guard let currentUserId = currentUserId else {
            print("🔍 DEBUG: DataManager - No current user, clearing analytics data")
            reactiveAnalyticsData = nil
            return
        }
        
        // Use the generateUserAnalytics method to create analytics data from cached data
        let analyticsData = generateUserAnalytics(for: currentUserId)
        
        if let analyticsData = analyticsData {
            print("🔍 DEBUG: DataManager - Reactive analytics calculation completed for user \(currentUserId)")
            print("🔍 DEBUG: DataManager - Analytics data generated successfully")
        } else {
            print("🔍 DEBUG: DataManager - No analytics data available for user \(currentUserId)")
        }
        
        reactiveAnalyticsData = analyticsData
    }
    
    /// Callback for when a game is updated - triggers reactive leaderboard recalculation
    @MainActor
    func onGameUpdated(_ updatedGame: Game) {
        print("🔍 DEBUG: DataManager.onGameUpdated() called for game ID: \(updatedGame.id), status: \(updatedGame.gameStatus)")
        print("🔍 DEBUG: DataManager - Games count before update: \(games.count)")
        
        // Update the games array with the new game data
        if let index = games.firstIndex(where: { $0.id == updatedGame.id }) {
            print("🔍 DEBUG: DataManager - Updating existing game at index \(index)")
            games[index] = updatedGame
        } else {
            print("🔍 DEBUG: DataManager - Adding new game to array")
            games.append(updatedGame)
        }
        
        print("🔍 DEBUG: DataManager - Games count after update: \(games.count)")
        print("🔍 DEBUG: DataManager - Game statuses: \(games.map { "\($0.id): \($0.gameStatus)" })")
        
        // The reactive system will automatically recalculate the leaderboard
        // No additional API calls needed!
    }
    
    /// Callback for when scores are updated - triggers reactive leaderboard recalculation
    @MainActor
    func onScoresUpdated(_ updatedScores: [Score]) {
        print("🔍 DEBUG: DataManager.onScoresUpdated() called with \(updatedScores.count) scores")
        print("🔍 DEBUG: DataManager - Scores count before update: \(scores.count)")
        
        // If we have scores for a specific game, we need to handle them specially
        // to ensure we have complete data for that game
        if let firstScore = updatedScores.first {
            let gameID = firstScore.gameID
            let allScoresForGame = updatedScores.filter { $0.gameID == gameID }
            
            // Check if all updated scores are for the same game
            if allScoresForGame.count == updatedScores.count {
                print("🔍 DEBUG: DataManager - All \(updatedScores.count) scores are for game \(gameID)")
                
                // Remove existing scores for this game to avoid duplicates
                let scoresBeforeRemoval = scores.count
                scores.removeAll { $0.gameID == gameID }
                let scoresAfterRemoval = scores.count
                print("🔍 DEBUG: DataManager - Removed \(scoresBeforeRemoval - scoresAfterRemoval) existing scores for game \(gameID)")
                
                // Add all the new scores for this game
                scores.append(contentsOf: allScoresForGame)
                print("🔍 DEBUG: DataManager - Added \(allScoresForGame.count) new scores for game \(gameID)")
            } else {
                // Mixed scores from different games - handle individually
                for updatedScore in updatedScores {
                    if let index = scores.firstIndex(where: { $0.id == updatedScore.id }) {
                        print("🔍 DEBUG: DataManager - Updating existing score at index \(index)")
                        scores[index] = updatedScore
                    } else {
                        print("🔍 DEBUG: DataManager - Adding new score for game \(updatedScore.gameID), player \(updatedScore.playerID), round \(updatedScore.roundNumber), value \(updatedScore.score)")
                        scores.append(updatedScore)
                    }
                }
            }
        } else {
            // No scores provided - nothing to do
            print("🔍 DEBUG: DataManager - No scores provided to onScoresUpdated")
        }
        
        print("🔍 DEBUG: DataManager - Scores count after update: \(scores.count)")
        
        // The reactive system will automatically recalculate the leaderboard
        // No additional API calls needed!
    }
    
    /// Callback for when a game is deleted - triggers reactive leaderboard recalculation
    @MainActor
    func onGameDeleted(_ deletedGame: Game) {
        print("🔍 DEBUG: DataManager.onGameDeleted() called for game ID: \(deletedGame.id)")
        print("🔍 DEBUG: DataManager - Games count before deletion: \(games.count)")
        print("🔍 DEBUG: DataManager - Scores count before deletion: \(scores.count)")
        
        // Remove the deleted game from the games array
        let gamesBefore = games.count
        games.removeAll { $0.id == deletedGame.id }
        let gamesAfter = games.count
        
        // Remove all scores associated with the deleted game
        let scoresBefore = scores.count
        scores.removeAll { $0.gameID == deletedGame.id }
        let scoresAfter = scores.count
        
        print("🔍 DEBUG: DataManager - Games count after deletion: \(gamesAfter) (removed \(gamesBefore - gamesAfter))")
        print("🔍 DEBUG: DataManager - Scores count after deletion: \(scoresAfter) (removed \(scoresBefore - scoresAfter))")
        
        // The reactive system will automatically recalculate the leaderboard
        // No additional API calls needed!
        print("🔍 DEBUG: DataManager - Removed deleted game \(deletedGame.id) and its scores from reactive system")
    }
    
    /// Manual trigger for testing reactive leaderboard calculation
    func triggerReactiveLeaderboardUpdate() {
        Task { @MainActor in
            await calculateReactiveLeaderboard(games: games, scores: scores, currentUserId: currentUserId)
        }
    }
    
    /// Sets the current user and clears data if signing out
    @MainActor
    func setCurrentUser(id: String?) async {
        print("🔍 DEBUG: DataManager.setCurrentUser() called with user ID: \(id ?? "nil")")
        
        if let userId = id {
            // User is signing in
            currentUserId = userId
            print("🔍 DEBUG: DataManager - Set current user to: \(userId)")
            
            // Invalidate cache to force fresh data fetch for new user
            invalidateCache()
            
            // Load data for the new user
            await loadAllData()
            print("🔍 DEBUG: DataManager - Finished loading data for user: \(userId)")
        } else {
            // User is signing out - clear all data
            currentUserId = nil
            games = []
            scores = []
            users = []
            reactiveLeaderboardData = []
            reactiveAnalyticsData = nil
            userLeaderboardData = []
            leaderboardData = []
            lastError = nil
            print("🔍 DEBUG: DataManager - User signed out, cleared all data")
        }
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
