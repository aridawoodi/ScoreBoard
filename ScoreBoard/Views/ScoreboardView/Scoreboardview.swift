//
//  Scoreboardview.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 7/24/25.
//

import SwiftUI
import Amplify

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// ScoreCell view to handle individual score cells
struct ScoreCell: View {
    let player: TestPlayer
    let roundIndex: Int
    let canEdit: Bool
    let onScoreTap: (Int) -> Void
    let currentScore: Int
    let backgroundColor: Color
    let displayText: String?
    let isFocused: Bool
    let hasScoreBeenEntered: Bool
    
    var body: some View {
        Button(action: {
            if canEdit {
                // Pass 0 instead of -1 for empty cells to avoid showing -1 in input
                let scoreToPass = currentScore == -1 ? 0 : currentScore
                onScoreTap(scoreToPass)
            }
        }) {
            HStack {
                Text(displayText ?? (hasScoreBeenEntered && currentScore != -1 ? "\(currentScore)" : ""))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                // Add edit indicator for cells that haven't been scored yet
                if (!hasScoreBeenEntered || currentScore == -1) && canEdit {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .opacity(0.6)
                        .onAppear {
                            print("🔍 DEBUG: Showing edit pencil for player \(player.name) round \(roundIndex + 1) - hasScoreBeenEntered: \(hasScoreBeenEntered), currentScore: \(currentScore), canEdit: \(canEdit)")
                        }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(cellBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(cellBorderColor, lineWidth: cellBorderWidth)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isFocused ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .scaleEffect(x: 1.0, y: isFocused ? 1.02 : 1.0, anchor: .center)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
            .zIndex(isFocused ? 10 : 0)
            .overlay(
                // Active cell indicator when keyboard is open
                Group {
                    if isFocused {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color("LightGreen"), lineWidth: 3)
                            .shadow(color: Color("LightGreen").opacity(0.5), radius: 8, x: 0, y: 0)
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isFocused)
        .overlay(
            // Pulsing animation for active cell
            Group {
                if isFocused {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color("LightGreen").opacity(0.3), lineWidth: 1)
                        .scaleEffect(1.1)
                        .opacity(0.6)
                        .animation(
                            Animation.easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true),
                            value: isFocused
                        )
                }
            }
        )
    }
    
    // Consistent dark theme background color
    private var cellBackgroundColor: Color {
        if isFocused {
            return backgroundColor.opacity(0.8)
        } else if canEdit {
            return backgroundColor.opacity(0.4)
        } else {
            return Color.black.opacity(0.3)
        }
    }
    
    // Consistent dark theme border color
    private var cellBorderColor: Color {
        if isFocused {
            return Color.accentColor
        } else if canEdit {
            return Color.white.opacity(0.3)
        } else {
            return Color.white.opacity(0.2)
        }
    }
    
    // Consistent border width
    private var cellBorderWidth: CGFloat {
        if isFocused {
            return 2.0
        } else if canEdit {
            return 1.0
        } else {
            return 0.5
        }
    }
    
    // Consistent shadow properties for dark theme
    private var shadowColor: Color {
        if isFocused {
            return Color.black.opacity(0.3)
        } else if canEdit {
            return Color.white.opacity(0.05)
        } else {
            return Color.clear
        }
    }
    
    private var shadowRadius: CGFloat {
        if isFocused {
            return 4.0
        } else if canEdit {
            return 2.0
        } else {
            return 0.0
        }
    }
    
    private var shadowOffset: CGFloat {
        if isFocused {
            return 2.0
        } else if canEdit {
            return 1.0
        } else {
            return 0.0
        }
    }
}

struct TestPlayer: Identifiable {
    let id = UUID()
    let name: String
    let scores: [Int]
    let playerID: String
    var total: Int { scores.filter { $0 != -1 }.reduce(0, +) }
}

// MARK: - Scoreboard Mode
enum ScoreboardMode {
    case edit        // For active games (current behavior)
    case readCompleted // For completed games (new behavior)
}

struct ScoreboardView: View {
    @Binding var game: Game
    let mode: ScoreboardMode
    @State private var selectedRound = 1
    @State private var players: [TestPlayer] = []
    @State private var isLoading = true
    @State private var showEditBoard = false
    @State private var showGameSettings = false
    @State private var playerNames: [String: String] = [:]
    @State private var scores: [String: [Int]] = [:]
    
    // Player hierarchy states
    @State private var playerHierarchy: [String: [String]] = [:]
    @State private var childPlayerNames: [String: String] = [:]
    @State private var playerData: [String: (name: String, scores: [Int])] = [:]
    @State private var gameUpdateCounter = 0 // Track game updates
    @State private var currentGameId: String // Track current game ID
    @State private var lastKnownGameRounds: Int // Track last known rounds
    @State private var hasUnsavedChanges = false // Track unsaved changes
    @State private var unsavedScores: [String: [Int]] = [:] // Store unsaved score changes
    @State private var lastSavedScores: [String: [Int]] = [:] // Store last saved state for undo
    @State private var enteredScores: Set<String> = [] // Track which scores have been explicitly entered by user
    @State private var showScoreInput = false // Show score input sheet
    @State private var editingScore = 0 // Current score being edited
    @State private var editingPlayer: TestPlayer? // Player being edited
    @State private var editingRound = 1 // Round being edited
    @State private var showSaveSuccess = false // Show save success message
    @State private var showSaveError = false // Show save error message
    @State private var saveErrorMessage = "" // Save error message
    @State private var currentUserID: String = "" // Current user ID for permission checks
    // @State private var isGameComplete: Bool = false // Track if game is complete - temporarily disabled
    @State private var showCelebration = false // Show celebration animation
    @State private var winner: TestPlayer? // Winner of the game
    @State private var celebrationMessage = "" // Celebration message

    @State private var scoreInputText: String = "" // Inline score input text
    
    // Floating action button state
    @State private var isFloatingButtonExpanded = false
    
    // Swipe navigation state
    @State private var availableGames: [Game] = []
    @State private var currentGameIndex: Int = 0
    
    // Dynamic rounds management
    @State private var dynamicRounds: Int = 1 // Track current number of rounds

    @State private var showRemoveRoundAlert = false // Show alert for removing round
    @State private var roundToRemove: Int = 0 // Track which round to remove
    
    // Toast message states
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastIcon = ""
    @State private var toastOpacity: Double = 0.0 // Add opacity state for animation
    @State private var showCopiedFeedback = false // Show copied feedback
    
    @State private var isGameDeleted = false // Flag when backend no longer has this game
    
    // Delete mode states
    @State private var isDeleteMode = false // Toggle delete mode
    @State private var showDeletePlayerAlert = false // Show alert for deleting player
    @State private var showDeleteRoundAlert = false // Show alert for deleting round
    @State private var showDeleteGameAlert = false // Show alert for deleting game
    @State private var playerToDelete: TestPlayer? // Track which player to delete
    @State private var roundToDelete: Int = 0 // Track which round to delete
    
    // Computed property to ensure delete mode is only active when game is active
    private var effectiveDeleteMode: Bool {
        return isDeleteMode && game.gameStatus == .active && canUserEditGame()
    }
    
    // Force view refresh when game status changes
    @State private var gameStatusRefreshTrigger = 0
    
    // Pull-to-refresh state
    @State private var isRefreshing = false
    
    // Highlight newly added round
    @State private var newlyAddedRound: Int? = nil
    
    // Trigger scroll to specific round
    @State private var scrollToRound: Int? = nil
    
    // Custom rules for score display
    @State private var customRules: [CustomRule] = []
    
    // Game list sheet state
    @State private var showGameListSheet = false
    
    // Game info sheet state
    @State private var showGameInfoSheet = false
    
    // Complete Game button animation state
    @State private var completeGameButtonPulse = false
    
    // Copy tooltip state
    @State private var showCopyTooltip = false
    
    // Keyboard scroll state
    @State private var shouldScrollToActiveCell = false
    @State private var keyboardOffset: CGFloat = 0 // Offset when custom keyboard is open
    @FocusState private var isScoreFieldFocused: Bool
    @State private var showSystemKeyboard = false // Track system keyboard visibility
    
    // Player name editing state
    @State private var editingPlayerName = ""
    @State private var editingPlayerIndex: Int? = nil
    @State private var showPlayerNameEditor = false
    @State private var originalPlayerNames: [String] = [] // For undo functionality

    let onGameUpdated: ((Game) -> Void)?
    let onGameDeleted: (() -> Void)?
    let onKeyboardStateChanged: ((Bool) -> Void)?
    
    init(game: Binding<Game>, mode: ScoreboardMode = .edit, onGameUpdated: ((Game) -> Void)? = nil, onGameDeleted: (() -> Void)? = nil, onKeyboardStateChanged: ((Bool) -> Void)? = nil) {
        self._game = game
        self._currentGameId = State(initialValue: game.wrappedValue.id)
        self._lastKnownGameRounds = State(initialValue: game.wrappedValue.rounds)
        self._dynamicRounds = State(initialValue: game.wrappedValue.rounds)
        self.mode = mode
        self.onGameUpdated = onGameUpdated
        self.onGameDeleted = onGameDeleted
        self.onKeyboardStateChanged = onKeyboardStateChanged
    }
    
    // MARK: - Helper Functions
    
    /// Extract the first letter from custom rules (e.g., "A=5" returns "A")
    private func extractCustomRuleLetter(from customRules: String?) -> String {
        guard let rules = customRules, !rules.isEmpty else { return "" }
        
        // Try to parse as JSON first
        if let data = rules.data(using: .utf8),
           let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let firstRule = jsonArray.first,
           let letter = firstRule["letter"] as? String {
            let extracted = String(letter.prefix(1))
            return extracted.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Fallback: try simple "=" format
        let parts = rules.components(separatedBy: "=")
        if let firstPart = parts.first, !firstPart.isEmpty {
            let extracted = String(firstPart.prefix(1))
            return extracted.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return ""
    }
    
    // MARK: - Game Status Functions
    
    /// Check if the game is complete (all scores filled)
    func isGameComplete() -> Bool {
        // All scores must be explicitly entered for current dynamic rounds
        guard !players.isEmpty, dynamicRounds > 0 else { 
            print("🔍 DEBUG: isGameComplete() - players empty or dynamicRounds <= 0")
            return false 
        }
        
        for (playerIndex, player) in players.enumerated() {
            if player.scores.count < dynamicRounds { 
                print("🔍 DEBUG: isGameComplete() - Player \(player.name) has \(player.scores.count) scores, need \(dynamicRounds)")
                return false 
            }
            for idx in 0..<dynamicRounds {
                let roundNumber = idx + 1
                if !hasScoreBeenEntered(for: player.playerID, round: roundNumber) { 
                    print("🔍 DEBUG: isGameComplete() - Player \(player.name) has no score entered at round \(roundNumber)")
                    return false 
                }
            }
        }
        
        print("🔍 DEBUG: isGameComplete() - Game is complete! All scores filled.")
        return true
    }
    
    /// Check if game is complete and determine winner
    func checkGameCompletionAndWinner(showCelebration: Bool = false) {
        guard isGameComplete() && !players.isEmpty else { return }
        
        print("🔍 DEBUG: Game winCondition: \(String(describing: game.winCondition))")
        
        // Determine winner based on game's win condition
        let sortedPlayers: [TestPlayer]
        let winningScore: Int
        
        if game.winCondition == .lowestScore {
            // For lowest score wins, sort by ascending order
            sortedPlayers = players.sorted { $0.total < $1.total }
            winningScore = sortedPlayers.first?.total ?? 0
        } else {
            // Default to highest score wins (including when winCondition is nil or .highestScore)
            sortedPlayers = players.sorted { $0.total > $1.total }
            winningScore = sortedPlayers.first?.total ?? 0
        }
        
        // Check if there's a clear winner (no ties)
        let winners = sortedPlayers.filter { $0.total == winningScore }
        
        if winners.count == 1 {
            // We have a clear winner!
            winner = winners.first
            let winConditionText = game.winCondition == .lowestScore ? "lowest" : "highest"
            celebrationMessage = "🎉 Congratulations \(winner?.name ?? "Player")! 🎉\nYou won with the \(winConditionText) score of \(winningScore)!"
            
            // Only show celebration if explicitly requested and we haven't shown it before for this game
            if showCelebration && !hasShownCelebrationForGame() {
                self.showCelebration = true
                markCelebrationAsShown()
                print("🔍 DEBUG: 🎉 GAME COMPLETE! Winner: \(winner?.name ?? "Unknown") with \(winConditionText) score: \(winningScore)")
            }
        } else if winners.count > 1 {
            // We have a tie
            let winnerNames = winners.map { $0.name }.joined(separator: ", ")
            let winConditionText = game.winCondition == .lowestScore ? "lowest" : "highest"
            celebrationMessage = "🤝 It's a tie! 🤝\nCongratulations to \(winnerNames)!\nAll tied with the \(winConditionText) score of \(winningScore)!"
            
            // Only show celebration if explicitly requested and we haven't shown it before for this game
            if showCelebration && !hasShownCelebrationForGame() {
                self.showCelebration = true
                markCelebrationAsShown()
                print("🔍 DEBUG: 🤝 GAME COMPLETE! Tie between: \(winnerNames) with \(winConditionText) score: \(winningScore)")
            }
        }
    }
    
    /// Check if current user can edit the game
    func canUserEditGame() -> Bool {
        // Only the game creator (host) can edit the game
        guard !currentUserID.isEmpty else { return false }
        return game.hostUserID == currentUserID
    }
    
    /// Check if current user can edit scores
func canUserEditScores() -> Bool {
        // Only the host can edit scores, and only while the game is ACTIVE
        return canUserEditGame() && game.gameStatus == .active
}

/// Check if celebration has already been shown for this game
func hasShownCelebrationForGame() -> Bool {
    let key = "celebration_shown_\(game.id)"
    return UserDefaults.standard.bool(forKey: key)
}

/// Mark celebration as shown for this game
func markCelebrationAsShown() {
    let key = "celebration_shown_\(game.id)"
    UserDefaults.standard.set(true, forKey: key)
}

/// Get the winner of the game (if completed)
func getGameWinner() -> (winner: TestPlayer?, message: String, isTie: Bool) {
    guard isGameComplete() && !players.isEmpty else {
        return (nil, "", false)
    }
    
    // Determine winner based on game's win condition
    let sortedPlayers: [TestPlayer]
    let winningScore: Int
    
    if game.winCondition == .lowestScore {
        // For lowest score wins, sort by ascending order
        sortedPlayers = players.sorted { $0.total < $1.total }
        winningScore = sortedPlayers.first?.total ?? 0
    } else {
        // Default to highest score wins (including when winCondition is nil or .highestScore)
        sortedPlayers = players.sorted { $0.total > $1.total }
        winningScore = sortedPlayers.first?.total ?? 0
    }
    
    let winners = sortedPlayers.filter { $0.total == winningScore }
    
    if winners.count == 1 {
        let winConditionText = game.winCondition == .lowestScore ? "lowest" : "highest"
        let message = "🏆 Winner: \(winners.first?.name ?? "Unknown") (\(winConditionText): \(winningScore) points)"
        return (winners.first, message, false)
    } else if winners.count > 1 {
        let winnerNames = winners.map { $0.name }.joined(separator: ", ")
        let winConditionText = game.winCondition == .lowestScore ? "lowest" : "highest"
        let message = "🤝 Tie: \(winnerNames) (\(winConditionText): \(winningScore) points each)"
        return (winners.first, message, true)
    }
    
    return (nil, "", false)
}
    
    /// Load current user ID
    func loadCurrentUser() async {
        // Get current user info using helper function that works for both guest and authenticated users
        if let currentUserInfo = await getCurrentUser() {
            let userId = currentUserInfo.userId
            await MainActor.run {
                self.currentUserID = userId
            }
            print("🔍 DEBUG: Loaded current user ID: \(userId)")
        } else {
            print("🔍 DEBUG: Unable to get current user information")
        }
    }
    
    // MARK: - Player Name Editing Functions
    
    /// Check if current user can edit player names
    func canEditPlayerNames() -> Bool {
        return canUserEditGame() && game.gameStatus == .active
    }
    
    /// Check if a specific player's name can be edited
    func canEditSpecificPlayerName(_ player: TestPlayer) -> Bool {
        // Only allow editing if:
        // 1. User can edit player names in general
        // 2. Player is an anonymous player (display name only, not a registered user)
        //    - Guest users (guest_ prefix) cannot be edited
        //    - Cognito users (UUID format) cannot be edited
        //    - Only anonymous players (simple display names) can be edited
        return canEditPlayerNames() && isAnonymousPlayer(player)
    }
    
    /// Check if a player is an anonymous player (display name only)
    private func isAnonymousPlayer(_ player: TestPlayer) -> Bool {
        let playerID = player.playerID
        
        // Guest users have "guest_" prefix
        if playerID.hasPrefix("guest_") {
            return false
        }
        
        // Cognito users have UUID format (36 characters with dashes)
        // They can also have format "UUID:username" for registered users
        if playerID.count == 36 && playerID.contains("-") {
            return false
        }
        
        // Registered users with format "UUID:username" (Cognito users)
        if playerID.contains(":") {
            let uuidPart = String(playerID.prefix(36))
            if uuidPart.count == 36 && uuidPart.contains("-") {
                return false
            }
        }
        
        // Email addresses (for some registered users)
        if playerID.contains("@") {
            return false
        }
        
        // If none of the above, it's likely an anonymous player (display name)
        return true
    }
    
    /// Start editing a player name
    func startEditingPlayerName(_ player: TestPlayer, at index: Int) {
        // Double-check that this specific player can be edited
        guard canEditSpecificPlayerName(player) else {
            print("🔍 DEBUG: Attempted to edit non-editable player: \(player.name)")
            return
        }
        
        print("🔍 DEBUG: Starting to edit player at index \(index): '\(player.name)' (playerID: '\(player.playerID)')")
        print("🔍 DEBUG: Current game.playerIDs: \(game.playerIDs)")
        print("🔍 DEBUG: Current players array: \(players.map { "\($0.name) (ID: \($0.playerID))" })")
        
        editingPlayerName = player.name
        editingPlayerIndex = index
        showPlayerNameEditor = true
        
        // Store original names for undo functionality
        if originalPlayerNames.isEmpty {
            originalPlayerNames = players.map { $0.name }
        }
        

    }
    
    /// Save the edited player name
    func savePlayerName() async {
        guard let index = editingPlayerIndex,
              index < players.count,
              !editingPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        let trimmedName = editingPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Get the actual playerID from the player being edited (not relying on index)
        let oldPlayerID = players[index].playerID
        
        // Update the player name in the local players array
        players[index] = TestPlayer(
            name: trimmedName,
            scores: players[index].scores,
            playerID: trimmedName // Update playerID to match the new name
        )
        
        // Update the game's playerIDs array to persist the change
        var updatedGame = game
        // Find the correct index in playerIDs by matching the playerID (not visual index)
        if let playerIDIndex = updatedGame.playerIDs.firstIndex(of: oldPlayerID) {
            print("🔍 DEBUG: Updating playerIDs[\(playerIDIndex)] from '\(oldPlayerID)' to '\(trimmedName)'")
            updatedGame.playerIDs[playerIDIndex] = trimmedName
            print("🔍 DEBUG: Updated game.playerIDs: \(updatedGame.playerIDs)")
            
            // If this is a parent player in a hierarchy, update the hierarchy keys
            if !playerHierarchy.isEmpty && playerHierarchy.keys.contains(oldPlayerID) {
                var hierarchy = playerHierarchy
                if let childPlayers = hierarchy[oldPlayerID] {
                    hierarchy.removeValue(forKey: oldPlayerID)
                    hierarchy[trimmedName] = childPlayers
                    updatedGame = updatedGame.setPlayerHierarchy(hierarchy)
                    // Update local state to match
                    playerHierarchy = hierarchy
                    print("🔍 DEBUG: Updated hierarchy key from '\(oldPlayerID)' to '\(trimmedName)' with \(childPlayers.count) children")
                    print("🔍 DEBUG: New hierarchy: \(hierarchy)")
                }
            }
            
            // Update playerData dictionary to use the new playerID
            if let existingPlayerData = playerData[oldPlayerID] {
                playerData.removeValue(forKey: oldPlayerID)
                playerData[trimmedName] = existingPlayerData
                print("🔍 DEBUG: Updated playerData key from '\(oldPlayerID)' to '\(trimmedName)'")
            }
            
            // Update enteredScores set to use new playerID
            let oldEnteredScores = enteredScores.filter { $0.hasPrefix("\(oldPlayerID)-") }
            for oldScoreKey in oldEnteredScores {
                enteredScores.remove(oldScoreKey)
                let roundNumber = String(oldScoreKey.dropFirst("\(oldPlayerID)-".count))
                let newScoreKey = "\(trimmedName)-\(roundNumber)"
                enteredScores.insert(newScoreKey)
                print("🔍 DEBUG: Updated enteredScores key from '\(oldScoreKey)' to '\(newScoreKey)'")
            }
            
            // Update lastSavedScores dictionary to use new playerID
            if let existingLastSavedScores = lastSavedScores[oldPlayerID] {
                lastSavedScores.removeValue(forKey: oldPlayerID)
                lastSavedScores[trimmedName] = existingLastSavedScores
                print("🔍 DEBUG: Updated lastSavedScores key from '\(oldPlayerID)' to '\(trimmedName)'")
            }
        } else {
            print("🔍 DEBUG: ERROR: PlayerID '\(oldPlayerID)' not found in game.playerIDs: \(updatedGame.playerIDs)")
        }
        
        // Save to backend
        do {
            let updatedGameResult = try await Amplify.API.mutate(request: .update(updatedGame))
            switch updatedGameResult {
            case .success(let savedGame):
                await MainActor.run {
                    game = savedGame
                    // Update the callback to refresh other views
                    onGameUpdated?(savedGame)
                }
                print("🔍 DEBUG: Player name updated successfully: \(trimmedName)")
                
                // Migrate existing scores to use the new player ID
                await migrateScoresForRenamedPlayer(oldPlayerID: oldPlayerID, newPlayerID: trimmedName)
                
                // Reload game data to ensure UI state is consistent with database
                await MainActor.run {
                    print("🔍 DEBUG: Reloading game data after player rename and score migration")
                    loadGameData()
                }
            case .failure(let error):
                print("🔍 DEBUG: Failed to update player name: \(error)")
                // Revert the change on failure
                await revertPlayerNameChange()
            }
        } catch {
            print("🔍 DEBUG: Error updating player name: \(error)")
            await revertPlayerNameChange()
        }
        
        // Reset editing state
        editingPlayerIndex = nil
        editingPlayerName = ""
        showPlayerNameEditor = false
    }
    
    /// Migrate existing scores to use the new player ID when a player is renamed
    func migrateScoresForRenamedPlayer(oldPlayerID: String, newPlayerID: String) async {
        print("🔍 DEBUG: ===== MIGRATING SCORES FOR RENAMED PLAYER =====")
        print("🔍 DEBUG: Migrating scores from '\(oldPlayerID)' to '\(newPlayerID)'")
        
        do {
            // Fetch all scores for this game
            let scoresResult = try await Amplify.API.query(request: .list(Score.self, where: Score.keys.gameID.eq(game.id)))
            
            switch scoresResult {
            case .success(let scores):
                print("🔍 DEBUG: Found \(scores.count) scores to check for migration")
                
                // Find scores that need to be migrated
                let scoresToMigrate = scores.filter { $0.playerID == oldPlayerID }
                print("🔍 DEBUG: Found \(scoresToMigrate.count) scores to migrate")
                
                for score in scoresToMigrate {
                    print("🔍 DEBUG: Migrating score - Round: \(score.roundNumber), Score: \(score.score)")
                    
                    // Try to update the existing score first
                    var updatedScore = score
                    updatedScore.playerID = newPlayerID
                    
                    let updateResult = try await Amplify.API.mutate(request: .update(updatedScore))
                    switch updateResult {
                    case .success(let updatedScore):
                        print("🔍 DEBUG: Successfully updated score for player '\(newPlayerID)' - Round: \(updatedScore.roundNumber), Score: \(updatedScore.score)")
                    case .failure(let error):
                        print("🔍 DEBUG: Update failed (likely due to key constraint), falling back to delete/create: \(error)")
                        
                        // Fallback: Delete old score and create new one
                        let _ = try await Amplify.API.mutate(request: .delete(score))
                        print("🔍 DEBUG: Deleted old score for player '\(oldPlayerID)'")
                        
                        // Create new score with updated player ID
                        let newScore = Score(
                            id: UUID().uuidString,
                            gameID: score.gameID,
                            playerID: newPlayerID,
                            roundNumber: score.roundNumber,
                            score: score.score,
                            createdAt: Temporal.DateTime.now(),
                            updatedAt: Temporal.DateTime.now(),
                            owner: score.owner
                        )
                        
                        let createResult = try await Amplify.API.mutate(request: .create(newScore))
                        switch createResult {
                        case .success(let createdScore):
                            print("🔍 DEBUG: Created new score for player '\(newPlayerID)' - Round: \(createdScore.roundNumber), Score: \(createdScore.score)")
                        case .failure(let createError):
                            print("🔍 DEBUG: Failed to create new score: \(createError)")
                        }
                    }
                }
                
                print("🔍 DEBUG: Score migration completed successfully")
                
            case .failure(let error):
                print("🔍 DEBUG: Failed to fetch scores for migration: \(error)")
            }
            
        } catch {
            print("🔍 DEBUG: Error during score migration: \(error)")
        }
        
            print("🔍 DEBUG: ===== SCORE MIGRATION END =====")
            
            // Validate state consistency after migration
            await validateStateConsistency(oldPlayerID: oldPlayerID, newPlayerID: newPlayerID)
        }
    
    /// Validate state consistency after player rename and score migration
    func validateStateConsistency(oldPlayerID: String, newPlayerID: String) async {
        print("🔍 DEBUG: ===== VALIDATING STATE CONSISTENCY =====")
        print("🔍 DEBUG: Checking consistency for player rename: '\(oldPlayerID)' -> '\(newPlayerID)'")
        
        // Check if old playerID still exists in any state
        let oldPlayerInEnteredScores = enteredScores.contains { $0.hasPrefix("\(oldPlayerID)-") }
        let oldPlayerInLastSavedScores = lastSavedScores.keys.contains(oldPlayerID)
        let oldPlayerInPlayerData = playerData.keys.contains(oldPlayerID)
        
        print("🔍 DEBUG: Old playerID '\(oldPlayerID)' still exists in:")
        print("🔍 DEBUG: - enteredScores: \(oldPlayerInEnteredScores)")
        print("🔍 DEBUG: - lastSavedScores: \(oldPlayerInLastSavedScores)")
        print("🔍 DEBUG: - playerData: \(oldPlayerInPlayerData)")
        
        // Check if new playerID exists in all relevant state
        let newPlayerInEnteredScores = enteredScores.contains { $0.hasPrefix("\(newPlayerID)-") }
        let newPlayerInLastSavedScores = lastSavedScores.keys.contains(newPlayerID)
        let newPlayerInPlayerData = playerData.keys.contains(newPlayerID)
        
        print("🔍 DEBUG: New playerID '\(newPlayerID)' exists in:")
        print("🔍 DEBUG: - enteredScores: \(newPlayerInEnteredScores)")
        print("🔍 DEBUG: - lastSavedScores: \(newPlayerInLastSavedScores)")
        print("🔍 DEBUG: - playerData: \(newPlayerInPlayerData)")
        
        // Check for any inconsistencies
        if oldPlayerInEnteredScores || oldPlayerInLastSavedScores || oldPlayerInPlayerData {
            print("🔍 DEBUG: ⚠️ WARNING: Old playerID still exists in some state - this may cause UI glitches")
        }
        
        if !newPlayerInEnteredScores && !newPlayerInLastSavedScores && !newPlayerInPlayerData {
            print("🔍 DEBUG: ⚠️ WARNING: New playerID doesn't exist in any state - this may cause UI glitches")
        }
        
        // Log current state for debugging
        print("🔍 DEBUG: Current enteredScores keys: \(Array(enteredScores).sorted())")
        print("🔍 DEBUG: Current lastSavedScores keys: \(Array(lastSavedScores.keys).sorted())")
        print("🔍 DEBUG: Current playerData keys: \(Array(playerData.keys).sorted())")
        
        print("🔍 DEBUG: ===== STATE CONSISTENCY VALIDATION END =====")
    }
    
    /// Revert player name changes (undo functionality)
    func revertPlayerNameChange() async {
        guard !originalPlayerNames.isEmpty else { return }
        
        await MainActor.run {
            // Restore original names
            for (index, originalName) in originalPlayerNames.enumerated() {
                if index < players.count {
                    players[index] = TestPlayer(
                        name: originalName,
                        scores: players[index].scores,
                        playerID: players[index].playerID
                    )
                }
            }
            
            // Reset editing state
            editingPlayerIndex = nil
            editingPlayerName = ""
            showPlayerNameEditor = false
            originalPlayerNames = []
            
            // Show undo success toast
            showToastMessage(message: "Player names reverted to original", icon: "arrow.uturn.backward.circle")
        }
    }
    
    /// Cancel player name editing
    func cancelPlayerNameEditing() {
        editingPlayerIndex = nil
        editingPlayerName = ""
        showPlayerNameEditor = false
    }
    
    /// Check and mark game as complete if all scores are filled - temporarily disabled
    func checkAndMarkGameComplete() async {
        // Temporarily disabled until game status is properly implemented
        print("Game completion check temporarily disabled")
    }
    
    /// Refresh game data from backend
    func refreshGameData() async {
        print("🔍 DEBUG: ===== REFRESH GAME DATA START =====")
        
        await MainActor.run {
            isRefreshing = true
        }
        
        do {
            // Fetch the latest game data from backend with timeout
            let result = try await withTimeout(seconds: 10) {
                try await Amplify.API.query(request: .get(Game.self, byId: game.id))
            }
            
            // Check if the task was cancelled
            try Task.checkCancellation()
            
            switch result {
            case .success(let updatedGame):
                if let updatedGame = updatedGame {
                    print("🔍 DEBUG: Successfully refreshed game data")
                    print("🔍 DEBUG: Updated game playerIDs: \(updatedGame.playerIDs)")
                    print("🔍 DEBUG: Previous game playerIDs: \(self.game.playerIDs)")
                    
                    await MainActor.run {
                        self.game = updatedGame
                        self.currentGameId = updatedGame.id
                        self.lastKnownGameRounds = updatedGame.rounds
                        self.dynamicRounds = updatedGame.rounds
                        
                        // Clear current data to force complete reload
                        print("🔍 DEBUG: Clearing current data for complete reload")
                        self.players = []
                        self.scores = [:]
                        self.playerNames = [:]
                        self.unsavedScores = [:]
                        self.hasUnsavedChanges = false
                        
                        // Force immediate reload of game data
                        self.loadGameData()
                        
                        // Show success feedback
                        self.showToastMessage(message: "Game refreshed", icon: "arrow.clockwise.circle.fill")
                        
                        // Force UI update to reflect changes
                        self.gameUpdateCounter += 1
                        
                        self.isRefreshing = false
                    }
                } else {
                    print("🔍 DEBUG: Game no longer exists in backend")
                    await MainActor.run {
                        self.isGameDeleted = true
                        self.showToastMessage(message: "Game not found", icon: "exclamationmark.circle.fill")
                        self.isRefreshing = false
                    }
                }
            case .failure(let error):
                print("🔍 DEBUG: Failed to refresh game: \(error)")
                await MainActor.run {
                    self.showToastMessage(message: "Refresh failed", icon: "exclamationmark.circle.fill")
                    self.isRefreshing = false
                }
            }
        } catch is CancellationError {
            print("🔍 DEBUG: Refresh was cancelled - attempting to complete data update anyway")
            // Even if cancelled, try to complete the data update if we have the game data
            await MainActor.run {
                self.isRefreshing = false
            }
        } catch is TimeoutError {
            print("🔍 DEBUG: Refresh timed out")
            await MainActor.run {
                self.isRefreshing = false
                self.showToastMessage(message: "Refresh timed out", icon: "clock.circle.fill")
            }
        } catch {
            print("🔍 DEBUG: Error refreshing game data: \(error)")
            await MainActor.run {
                self.isRefreshing = false
                self.showToastMessage(message: "Refresh failed", icon: "exclamationmark.circle.fill")
            }
        }
        
        print("🔍 DEBUG: ===== REFRESH GAME DATA END =====")
    }
    
    // MARK: - Helper Functions
    
    /// Helper function to add timeout to async operations
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    /// Custom timeout error
    private struct TimeoutError: Error {}
    
    private func onAppearAction() {
        print("🔍 DEBUG: ===== SCOREBOARDVIEW ONAPPEAR =====")
        print("🔍 DEBUG: Scoreboardview onAppear - Game ID: \(game.id)")
        print("🔍 DEBUG: Scoreboardview onAppear - Mode: \(mode)")
        print("🔍 DEBUG: Current game rounds: \(game.rounds)")
        print("🔍 DEBUG: Current game status: \(game.gameStatus)")
        print("🔍 DEBUG: Last known rounds: \(lastKnownGameRounds)")
        
        
        // Initialize dynamic rounds
        dynamicRounds = game.rounds
        
        // Load current user and initialize game status
        Task {
            await loadCurrentUser()
            await checkAndMarkGameComplete()
        }
        
        // Check if game has changed
        if currentGameId != game.id || lastKnownGameRounds != game.rounds {
            print("🔍 DEBUG: Game has changed - updating state")
            currentGameId = game.id
            lastKnownGameRounds = game.rounds
            dynamicRounds = game.rounds
            loadGameData()
        } else {
            loadGameData()
        }
    }
    
    private func loadAvailableGames() {
        print("🔍 DEBUG: Loading available games for swipe navigation")
        Task {
            await DataManager.shared.refreshGames()
            if let currentUserInfo = await getCurrentUser() {
                let userId = currentUserInfo.userId
                let userGames = DataManager.shared.getGamesForUser(userId)
                
                await MainActor.run {
                    // Filter based on mode: active games for edit mode, all games for readCompleted mode
                    let filteredGames: [Game]
                    if mode == .readCompleted {
                        // In read-only mode, include all games (active and completed)
                        filteredGames = userGames
                    } else {
                        // In edit mode, only show active games
                        filteredGames = userGames.filter { $0.gameStatus == .active }
                    }
                    
                    let sortedGames = filteredGames.sorted { game1, game2 in
                        // Sort by creation date - most recent first
                        let date1 = game1.createdAt.foundationDate ?? Date.distantPast
                        let date2 = game2.createdAt.foundationDate ?? Date.distantPast
                        return date1 > date2
                    }
                    
                    // Take only the latest 3 games
                    let latest3Games = Array(sortedGames.prefix(3))
                    
                    self.availableGames = latest3Games
                    
                    // Find current game index in the filtered list
                    if let currentIndex = latest3Games.firstIndex(where: { $0.id == self.game.id }) {
                        self.currentGameIndex = currentIndex
                    } else {
                        self.currentGameIndex = 0
                    }
                    
                    let gameTypeDescription = mode == .readCompleted ? "games (all statuses)" : "active games"
                    print("🔍 DEBUG: ScoreboardView - Filtered to \(latest3Games.count) latest \(gameTypeDescription)")
                    print("🔍 DEBUG: ScoreboardView - Available games: \(latest3Games.map { $0.gameName ?? "Untitled" })")
                    print("🔍 DEBUG: Loaded \(latest3Games.count) games, current index: \(self.currentGameIndex)")
                }
            }
        }
    }
    
    private func handleGameUpdate(_ updatedGame: Game) {
        print("🔍 DEBUG: ===== GAME UPDATE CALLBACK START =====")
        print("🔍 DEBUG: Original game rounds: \(game.rounds)")
        print("🔍 DEBUG: Updated game rounds: \(updatedGame.rounds)")
        print("🔍 DEBUG: Original game playerIDs: \(game.playerIDs)")
        print("🔍 DEBUG: Updated game playerIDs: \(updatedGame.playerIDs)")
        print("🔍 DEBUG: showGameSettings current state: \(showGameSettings)")
        print("🔍 DEBUG: showGameListSheet current state: \(showGameListSheet)")
        
        // If a sheet is currently being presented, delay the game update to prevent interference
        if showGameSettings || showGameListSheet {
            print("🔍 DEBUG: Sheet is currently presented - delaying game update")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.performGameUpdate(updatedGame)
            }
        } else {
            performGameUpdate(updatedGame)
        }
        
        print("🔍 DEBUG: ===== GAME UPDATE CALLBACK END =====")
    }
    
    private func performGameUpdate(_ updatedGame: Game) {
        print("🔍 DEBUG: Performing game update")
        
        // Update the game binding immediately
        self.game = updatedGame
        self.currentGameId = updatedGame.id
        self.lastKnownGameRounds = updatedGame.rounds
        self.dynamicRounds = updatedGame.rounds
        
        // Increment counter to trigger reload
        self.gameUpdateCounter += 1
        
        // Update DataManager for reactive leaderboard calculation
        DataManager.shared.onGameUpdated(updatedGame)
        
        // Call the parent callback
        self.onGameUpdated?(updatedGame)
        
        print("🔍 DEBUG: Game update completed")
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background gradient - consistent dark theme
            GradientBackgroundView()
            
            if isGameDeleted {
                // Ask parent to clear selection by sending an empty updated game with nil-like id? Not possible here.
                // As a fallback, dismiss this view by hiding content; parent tab will show empty state when no selection.
                Color.black.opacity(0.8).ignoresSafeArea()
            } else {
            mainContentView
            }
            
            // Toast message overlay
            if showToast {
                VStack {
                    Spacer()
                    ToastMessageView(
                        message: toastMessage,
                        icon: toastIcon,
                        isVisible: $showToast
                    )
                    .opacity(toastOpacity) // Use opacity state for animation
                    .padding(.bottom, 100) // Position above floating tab bar
                }
            }

            // Winner banner overlay near bottom, below the toast area
            // if isGameComplete() {
            //     VStack {
            //         Spacer()
            //         gameCompletionBanner
            //             .padding(.bottom, 40)
            //     }
            //     .allowsHitTesting(false)
            //     .transition(.opacity)
            // }
            
            // Floating Action Button - COMMENTED OUT FOR FUTURE USE
            /*
            FloatingActionButton(
                isExpanded: $isFloatingButtonExpanded,
                onBackToBoards: {
                    // Navigate back to YourBoardTabView
                    // This will clear the selected game and show the empty state
                    if let onGameDeleted = onGameDeleted {
                        onGameDeleted()
                    }
                },
                onViewAllGames: {
                    // Show all available games
                    print("🔍 DEBUG: View All Games tapped - showing \(availableGames.count) games")
                    // The swipe navigation is already active, just show a toast
                    showToastMessage(message: "Swipe left/right to switch between \(availableGames.count) games", icon: "hand.draw")
                }
            )
            .onChange(of: isFloatingButtonExpanded) { _, isExpanded in
                if isExpanded {
                    // Refresh available games when floating button is expanded
                    loadAvailableGames()
                }
            }
            */
        }
        // Persistent accessory bar above the keyboard for Cancel/Save - DISABLED: Now using system keyboard with enhanced toolbar
        /*
        .safeAreaInset(edge: .bottom) {
            if isScoreFieldFocused {
                ZStack {
                    // Leading/Trailing controls with generous horizontal padding
                    HStack {
                        Button("Cancel") {
                            isScoreFieldFocused = false
                            editingPlayer = nil
                        }
                        Spacer()
                        Button("Next") {
                            if let player = editingPlayer {
                                let newScore = parseScoreInput(scoreInputText) ?? 0
                                updateScore(playerID: player.playerID, round: editingRound, newScore: newScore)
                            }
                            awaitSaveChangesSilently()
                            moveToNextZeroCellInSameRound()
                            if editingPlayer != nil {
                                isScoreFieldFocused = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // Centered save group with live value
                    HStack(spacing: 10) {
                        Text(scoreInputText.isEmpty ? "0" : scoreInputText)
                            .font(.headline)
                            .monospacedDigit()
                        Button("Save") {
                            if let player = editingPlayer {
                                let newScore = parseScoreInput(scoreInputText) ?? 0
                                updateScore(playerID: player.playerID, round: editingRound, newScore: newScore)
                            }
                            awaitSaveChangesSilently()
                            isScoreFieldFocused = false
                            scoreInputText = ""
                            editingPlayer = nil
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(.regularMaterial)
                .overlay(Divider(), alignment: .top)
            }
        }
        */
        // EditBoardView sheet - DISABLED: Users now use gear icon for editing
        /*
        .sheet(isPresented: $showEditBoard) {
            EditBoardView(game: game) { updatedGame in
                handleGameUpdate(updatedGame)
            }
        }
        */
        .sheet(isPresented: $showGameSettings) {
            //print("🔍 DEBUG: Creating CreateGameView for sheet")
            CreateGameView(
                showCreateGame: $showGameSettings,
                mode: .edit(game), // This will use the updated game object after handleGameUpdate
                onGameCreated: { _ in }, // Not used in edit mode
                onGameUpdated: { updatedGame in
                    //print("🔍 DEBUG: CreateGameView onGameUpdated callback triggered")
                    handleGameUpdate(updatedGame)
                }
            )
        }
        .onChange(of: showGameSettings) { _, isPresented in
            print("🔍 DEBUG: showGameSettings changed to: \(isPresented)")
            if isPresented {
                print("🔍 DEBUG: Game settings sheet is being presented")
            } else {
                print("🔍 DEBUG: Game settings sheet is being dismissed")
            }
        }
        // .id("game-settings-sheet-\(game.id)-\(gameUpdateCounter)") // Force recreation when game updates - TEMPORARILY DISABLED
        .alert("Save Failed", isPresented: $showSaveError) {
            Button("OK") { }
        } message: {
            Text(saveErrorMessage)
        }

        .alert("Remove Round", isPresented: $showRemoveRoundAlert) {
            Button("Remove", role: .destructive) {
                removeRound()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Remove round \(roundToRemove)? This will delete all scores for this round.")
        }
        
        .alert("Delete Player", isPresented: $showDeletePlayerAlert) {
            Button("Delete", role: .destructive) {
                if let player = playerToDelete {
                    deletePlayer(player)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let player = playerToDelete {
                Text("Delete \(player.name) from this game? This will remove all their scores and cannot be undone.")
            }
        }
        
        .alert("Delete Round", isPresented: $showDeleteRoundAlert) {
            Button("Delete", role: .destructive) {
                deleteRound(roundToDelete)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Delete round \(roundToDelete)? This will remove all scores for this round and cannot be undone.")
        }
        
        .alert("Delete Game", isPresented: $showDeleteGameAlert) {
            Button("Delete", role: .destructive) {
                deleteGame()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Delete this entire game? This will permanently remove the game and all its scores. This action cannot be undone.")
        }
        .sheet(isPresented: $showGameListSheet) {
            //print("🔍 DEBUG: Creating GameListBottomSheet for sheet")
            GameListBottomSheet(
                games: availableGames,
                currentIndex: $currentGameIndex,
                onGameSelected: { index in
                    print("🔍 DEBUG: Game selected in list sheet: \(index)")
                    currentGameIndex = index
                    showGameListSheet = false
                },
                mode: mode
            )
        }
        .sheet(isPresented: $showPlayerNameEditor) {
            PlayerNameEditorSheet(
                playerName: $editingPlayerName,
                onSave: {
                    Task {
                        await savePlayerName()
                    }
                },
                onCancel: {
                    cancelPlayerNameEditing()
                },
                isHierarchyGame: !playerHierarchy.isEmpty,
                childPlayers: {
                    if let index = editingPlayerIndex, index < players.count {
                        let playerID = players[index].playerID
                        return playerHierarchy[playerID] ?? []
                    }
                    return []
                }()
            )
        }
        .sheet(isPresented: $showGameInfoSheet) {
            GameInfoSheet(game: game, players: players, isPresented: $showGameInfoSheet)
        }
        .onChange(of: showGameListSheet) { _, isPresented in
            print("🔍 DEBUG: showGameListSheet changed to: \(isPresented)")
            if isPresented {
                print("🔍 DEBUG: Game list sheet is being presented")
            } else {
                print("🔍 DEBUG: Game list sheet is being dismissed")
            }
        }
    }
    
    private var bottomSheetTriggerView: some View {
        Button(action: {
            print("🔍 DEBUG: Game list button tapped - attempting to show game list sheet")
            print("🔍 DEBUG: showGameSettings current state: \(showGameSettings)")
            print("🔍 DEBUG: showGameListSheet current state: \(showGameListSheet)")
            
            // Prevent multiple sheets from being presented simultaneously
            if !showGameSettings {
                showGameListSheet = true
                print("🔍 DEBUG: Game list sheet presentation triggered")
            } else {
                print("🔍 DEBUG: Game settings sheet is already presented - delaying game list sheet")
                // Delay the presentation to avoid conflicts
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !showGameSettings {
                        showGameListSheet = true
                        print("🔍 DEBUG: Game list sheet presentation triggered after delay")
                    }
                }
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(availableGames.count) \(mode == .readCompleted ? "Game" : "Active Game")\(availableGames.count == 1 ? "" : "s")")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Mini carousel preview
                HStack(spacing: 4) {
                    ForEach(0..<min(3, availableGames.count), id: \.self) { index in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(index == currentGameIndex ? Color("LightGreen") : Color.white.opacity(0.3))
                            .frame(width: 16, height: 4)
                            .animation(.easeInOut(duration: 0.2), value: currentGameIndex)
                    }
                }
                
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.6))
                    .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Enhanced Page indicators - COMMENTED OUT
            /*
            if availableGames.count > 1 {
                HStack(spacing: 12) {
                    ForEach(0..<availableGames.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentGameIndex ? Color("LightGreen") : Color.white.opacity(0.4))
                            .frame(width: 12, height: 12)
                            .scaleEffect(index == currentGameIndex ? 1.3 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentGameIndex)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentGameIndex = index
                                }
                            }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.black.opacity(0.6))
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            */
            
            // Alternative: Floating indicator with side arrows - COMMENTED OUT
            /*
            if availableGames.count > 1 {
                HStack(spacing: 0) {
                    // Left arrow
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if currentGameIndex > 0 {
                                currentGameIndex -= 1
                            } else {
                                currentGameIndex = availableGames.count - 1
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                    }
                    
                    Spacer()
                    
                    // Floating page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<availableGames.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentGameIndex ? Color("LightGreen") : Color.white.opacity(0.3))
                                .frame(width: index == currentGameIndex ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentGameIndex)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentGameIndex = index
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.7))
                            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                    )
                    
                    Spacer()
                    
                    // Right arrow
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if currentGameIndex < availableGames.count - 1 {
                                currentGameIndex += 1
                            } else {
                                currentGameIndex = 0
                            }
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
            }
            */
            
            // Alternative: Bottom sheet trigger with carousel preview
            // Only show for edit mode (not for read-only completed games)
            if availableGames.count > 1 && mode != .readCompleted {
                bottomSheetTriggerView
            }
            
            // Swipeable content
            TabView(selection: $currentGameIndex) {
                ForEach(Array(availableGames.enumerated()), id: \.element.id) { index, game in
                    singleGameView(for: game)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .onChange(of: currentGameIndex) { _, newIndex in
                if newIndex < availableGames.count {
                    let newGame = availableGames[newIndex]
                    print("🔍 DEBUG: Swiped to game: \(newGame.id)")
                    // Update the game binding
                    self.game = newGame
                    // Update navigation state if needed
                    if let onGameUpdated = onGameUpdated {
                        onGameUpdated(newGame)
                    }
                }
            }
        }
        .onAppear {
            loadAvailableGames()
        }
    }
    
    // Computed property for custom number pad overlay
    private var customNumberPadOverlay: some View {
        Group {
            if showSystemKeyboard {
                let customRuleLetter = extractCustomRuleLetter(from: self.game.customRules)
                
                SystemKeyboardView(
                    text: $scoreInputText,
                    isVisible: $showSystemKeyboard,
                    editingPlayer: $editingPlayer,
                    editingRound: $editingRound,
                    players: players,
                    updateScore: updateScore,
                    awaitSaveChangesSilently: awaitSaveChangesSilently,
                    customRuleLetter: customRuleLetter,
                    parseScoreInput: parseScoreInput,
                    dynamicRounds: dynamicRounds,
                    hasScoreBeenEntered: hasScoreBeenEntered,
                    canAddRound: canAddRound,
                    addRound: addRound,
                    maxRounds: game.maxRounds ?? 8
                )
                .zIndex(1000) // Ensure it's on top
                .onAppear {
                    // Trigger scroll to active cell when system keyboard appears
                    print("🔍 DEBUG: System keyboard appeared - triggering scroll to round \(editingRound)")
                    print("🔍 DEBUG: Custom rule letter: '\(customRuleLetter)' (length: \(customRuleLetter.count), isEmpty: \(customRuleLetter.isEmpty))")
                    print("🔍 DEBUG: Game custom rules: \(self.game.customRules ?? "nil")")
                    // Immediate scroll without delay
                    scrollToRound = editingRound
                }
                
                // Hidden TextField to trigger system keyboard
                TextField("", text: $scoreInputText)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .opacity(0)
                    .frame(width: 0, height: 0)
                    .focused($isScoreFieldFocused)
                    .onChange(of: isScoreFieldFocused) { _, newValue in
                        showSystemKeyboard = newValue
                    }
                    .onSubmit {
                        // Auto-save on Enter
                        if let currentScore = parseScoreInput(scoreInputText) {
                            updateScore(playerID: editingPlayer?.playerID ?? "", round: editingRound, newScore: currentScore)
                            awaitSaveChangesSilently()
                        }
                        // Dismiss keyboard immediately
                        isScoreFieldFocused = false
                        showSystemKeyboard = false
                    }
            }
        }
    }
    
    private func singleGameView(for game: Game) -> some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                headerView

                if isLoading {
                    loadingView
                } else {
                    if players.isEmpty {
                        loadingView
                    } else {
                        scoreboardTableView
                            .padding(.top, 12)
                    }
                }

                Spacer()
            }
            .offset(y: keyboardOffset) // Apply keyboard offset to make room for number pad
            .id("\(game.id)-\(gameStatusRefreshTrigger)")
            .background(Color.clear)
            .navigationBarTitleDisplayMode(.large)
            .navigationBarHidden(true)
            .onAppear {
                onAppearAction()
            }
            
            // Celebration overlay
            if showCelebration {
                CelebrationView(
                    message: celebrationMessage,
                    winner: winner,
                    onDismiss: {
                        showCelebration = false
                        winner = nil
                        celebrationMessage = ""
                    }
                )
            }
        }
        .overlay(
            // Custom number pad overlay - moved outside ZStack
            customNumberPadOverlay
                .animation(showSystemKeyboard ? .easeInOut(duration: 0.3) : nil, value: showSystemKeyboard)
        )
        .overlay(
            // Custom number pad overlay - positioned to cover floating tab bar
            Group {
                if isScoreFieldFocused {
                    VStack(spacing: 0) {
                        Spacer()
                        customNumberPadOverlay
                    }
                    .ignoresSafeArea(.all)
                }
            }
        )
        .onChange(of: gameUpdateCounter) { _, _ in
            print("🔍 DEBUG: Game update counter changed - reloading data")
            print("🔍 DEBUG: showGameSettings: \(showGameSettings), showGameListSheet: \(showGameListSheet)")
            loadGameData()
        }
        .onChange(of: game.rounds) { _, newRounds in
            print("🔍 DEBUG: ===== GAME ROUNDS CHANGED =====")
            print("🔍 DEBUG: Game rounds changed to \(newRounds) - updating state and reloading data")
            print("🔍 DEBUG: Previous dynamicRounds: \(dynamicRounds)")
            print("🔍 DEBUG: showGameSettings: \(showGameSettings), showGameListSheet: \(showGameListSheet)")
            lastKnownGameRounds = newRounds
            dynamicRounds = newRounds
            print("🔍 DEBUG: New dynamicRounds: \(dynamicRounds)")
            // Reset selectedRound if it's now out of bounds
            if selectedRound > newRounds {
                selectedRound = 1
            }
            loadGameData()
            print("🔍 DEBUG: ===== GAME ROUNDS CHANGED END =====")
        }
        .onChange(of: game.playerIDs) { _, newPlayerIDs in
            print("🔍 DEBUG: Game playerIDs changed to \(newPlayerIDs) - reloading data")
            print("🔍 DEBUG: showGameSettings: \(showGameSettings), showGameListSheet: \(showGameListSheet)")
            loadGameData()
        }
        .onChange(of: game.id) { _, newGameId in
            print("🔍 DEBUG: Game ID changed to \(newGameId) - updating state and reloading data")
            print("🔍 DEBUG: showGameSettings: \(showGameSettings), showGameListSheet: \(showGameListSheet)")
            currentGameId = newGameId
            loadGameData()
        }
        .onChange(of: game.gameStatus) { _, newStatus in
            print("🔍 DEBUG: Game status changed to \(newStatus)")
            print("🔍 DEBUG: showGameSettings: \(showGameSettings), showGameListSheet: \(showGameListSheet)")
            // Automatically disable delete mode when game is completed
            if newStatus == .completed && isDeleteMode {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isDeleteMode = false
                }
            }
            // Force view refresh when game status changes
            gameStatusRefreshTrigger += 1
        }
        .onChange(of: isScoreFieldFocused) { _, isFocused in
            // Apply keyboard offset when custom number pad appears/disappears
            if isFocused {
                withAnimation(.easeInOut(duration: 0.3)) {
                    keyboardOffset = -120 // Move scoreboard up when keyboard appears
                }
            } else {
                // No animation when dismissing - immediate reset
                keyboardOffset = 0
            }
            
            // Update navigation state for keyboard visibility (to hide floating tab bar)
            print("🔍 DEBUG: Keyboard state changed to: \(isFocused)")
            print("🔍 DEBUG: onKeyboardStateChanged callback exists: \(onKeyboardStateChanged != nil)")
            onKeyboardStateChanged?(isFocused)
            
            // Auto-save when input loses focus
            let shouldAutoSave = !isFocused && editingPlayer != nil && !scoreInputText.isEmpty
            if shouldAutoSave {
                if let currentScore = parseScoreInput(scoreInputText) {
                    updateScore(playerID: editingPlayer!.playerID, round: editingRound, newScore: currentScore)
                    awaitSaveChangesSilently()
                }
                // Don't save anything if parseScoreInput returns nil (empty or invalid input)
            }
        }
        .onChange(of: editingRound) { _, newRound in
            // Auto-scroll when editing round changes and custom number pad is open
            if isScoreFieldFocused {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    scrollToRound = newRound
                }
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // Game name, custom rules, and ID all on the same line
            HStack(spacing: 8) {
                // Game name with truncation - aligned to left
                if let gameName = game.gameName, !gameName.isEmpty {
                    Text(gameName)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                } else {
                    // Fallback if no game name is provided
                    Text("Game")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                }
                
                // Round Count Information
                HStack(spacing: 4) {
                    Image(systemName: "number.circle.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    Text("\(dynamicRounds)/\(game.maxRounds ?? 8)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.2))
                .cornerRadius(6)
                
                // Custom Rules Hint (only show if there are custom rules)
                if !customRules.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(customRules, id: \.id) { rule in
                            HStack(spacing: 4) {
                                Text(rule.letter)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("=")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("\(rule.value)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                }
                
                // Game ID with copy functionality
                ZStack {
                    HStack(spacing: 6) {
                        Text("Code: \(String(game.id.prefix(6)))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .onTapGesture {
                                // Show iOS native share sheet
                                let activityViewController = UIActivityViewController(
                                    activityItems: [String(game.id.prefix(6))],
                                    applicationActivities: nil
                                )
                                
                                // For iPad, set the popover source
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = windowScene.windows.first,
                                   let rootViewController = window.rootViewController {
                                    
                                    if let popover = activityViewController.popoverPresentationController {
                                        popover.sourceView = window
                                        popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                                        popover.permittedArrowDirections = []
                                    }
                                    
                                    rootViewController.present(activityViewController, animated: true)
                                }
                            }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .onLongPressGesture {
                        // Copy the short ID (the one shown)
                        UIPasteboard.general.string = String(game.id.prefix(6))
                        
                        // Show copy tooltip
                            withAnimation(.easeInOut(duration: 0.15)) {
                                showCopyTooltip = true
                            }
                            
                            // Hide tooltip after 0.8 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showCopyTooltip = false
                                }
                            }
                            
                            // Haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        }
                    
                    // Copy Tooltip - positioned above Game ID
                    if showCopyTooltip {
                        VStack(spacing: 0) {
                            // Tooltip bubble
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 10))
                                Text("Copied!")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.black.opacity(0.9))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.green.opacity(0.6), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
                            
                            // Pointing arrow (points downward to Game ID)
                            Triangle()
                                .fill(Color.black.opacity(0.9))
                                .frame(width: 12, height: 6)
                                .overlay(
                                    Triangle()
                                        .stroke(Color.green.opacity(0.6), lineWidth: 1)
                                )
                        }
                        .offset(y: -45)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(9999)
                    }
                }
            }
            
            // Edit Board and Complete Game buttons
            HStack(spacing: 16) {
                Spacer()
                
                // Complete Game button (only when all scores filled and user can edit)
                if canUserEditGame() && isGameComplete() {
                    if game.gameStatus == .completed {
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Completed")
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color("Orange"))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                        }
                        .disabled(true)
                    } else if canUserEditScores() {
                        Button(action: { 
                            print("🔍 DEBUG: Complete Game button pressed")
                            print("🔍 DEBUG: Game status before: \(game.gameStatus)")
                            print("🔍 DEBUG: isGameComplete(): \(isGameComplete())")
                            print("🔍 DEBUG: canUserEditGame(): \(canUserEditGame())")
                            print("🔍 DEBUG: canUserEditScores(): \(canUserEditScores())")
                            completeGame() 
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "flag.checkered")
                                    .foregroundColor(Color("LightGreen"))
                                Text("Complete Game")
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color("Orange"))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .scaleEffect(completeGameButtonPulse ? 1.025 : 1.0)
                            .shadow(color: completeGameButtonPulse ? Color.blue.opacity(0.10) : Color.clear, radius: 4, x: 0, y: 2)
                        }
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                completeGameButtonPulse = true
                            }
                        }
                    }
                }
                
                // Delete Mode button (only when game is active and user can edit)
                if canUserEditGame() && game.gameStatus == .active {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isDeleteMode.toggle()
                        }
                    }) {
                        Image(systemName: isDeleteMode ? "trash.circle.fill" : "trash.circle")
                            .font(.title2)
                            .foregroundColor(isDeleteMode ? .red : Color("LightGreen"))
                            .frame(width: 24, height: 24)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                    }
                }
                
                // Undo Player Name Changes button (only when there are original names to revert to)
                /*
                if canEditPlayerNames() && !originalPlayerNames.isEmpty {
                    Button(action: {
                        Task {
                            await revertPlayerNameChange()
                        }
                    }) {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
                */
                
                // Refresh button
                Button(action: {
                    Task {
                        await refreshGameData()
                    }
                }) {
                    Image(systemName: isRefreshing ? "arrow.clockwise.circle.fill" : "arrow.clockwise.circle")
                        .font(.title2)
                        .foregroundColor(Color("LightGreen"))
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isRefreshing)
                
                // Edit Board button - DISABLED: Users now use gear icon for editing
                /*
                Button(action: {
                    showEditBoard = true
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(canUserEditGame() ? .blue : .gray)
                }
                .disabled(!canUserEditGame())
                */
                
                // Game Settings button (gear icon)
                if canUserEditGame() && game.gameStatus == .active {
                    Button(action: {
                        print("🔍 DEBUG: Gear icon tapped - attempting to show game settings sheet")
                        print("🔍 DEBUG: showGameListSheet current state: \(showGameListSheet)")
                        print("🔍 DEBUG: showGameSettings current state: \(showGameSettings)")
                        
                        // Prevent multiple sheets from being presented simultaneously
                        if !showGameListSheet {
                            showGameSettings = true
                            print("🔍 DEBUG: Game settings sheet presentation triggered")
                        } else {
                            print("🔍 DEBUG: Game list sheet is already presented - delaying game settings sheet")
                            // Delay the presentation to avoid conflicts
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if !showGameListSheet {
                                    showGameSettings = true
                                    print("🔍 DEBUG: Game settings sheet presentation triggered after delay")
                                }
                            }
                        }
                    }) {
                        Image(systemName: "gearshape.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color("LightGreen"))
                            .frame(width: 24, height: 24)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 16) // Add spacing between header and table
        .id(gameStatusRefreshTrigger) // Force header refresh when game status changes
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView("Loading scores...")
                .foregroundColor(.white)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var scoreboardTableView: some View {
        VStack(spacing: 16) {
            // Delete Game Button (only in delete mode)
            if effectiveDeleteMode {
                HStack {
                    Button(action: {
                        showDeleteGameAlert = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Delete Board")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.red)
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            
            // Excel-like table container with scroll
            ScrollViewReader { proxy in
                ScrollView {
                    ZStack {
                        // Table content (background)
                        VStack(spacing: 0) {
                            headerRow
                            scoreRows
                            addRoundButton
                        }
                        .background(Color.black.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                        // Static dark green border
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                Color(hex: "4A7C59"),
                                lineWidth: 4
                            )
                            .allowsHitTesting(false) // Allow touches to pass through to the table
                    }
                    .padding(0) // Remove any default padding
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.55) // Increased height to show more content
                .refreshable {
                    // Start the refresh operation and ensure it completes
                    // Use Task to prevent cancellation when gesture is released
                    Task {
                        await refreshGameData()
                    }
                }
                .onChange(of: editingRound) { _, newRound in
                    // Auto-scroll to the editing round when keyboard appears
                    if isScoreFieldFocused {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("round-\(newRound)", anchor: .center)
                        }
                    }
                }
                .onChange(of: isScoreFieldFocused) { _, isFocused in
                    // Auto-scroll to active cell when keyboard appears
                    if isFocused && editingPlayer != nil {
                        print("🔍 DEBUG: Keyboard appeared - scrolling to round \(editingRound)")
                        shouldScrollToActiveCell = true
                        
                        // Immediate scroll to active round
                        withAnimation(.easeInOut(duration: 0.8)) {
                            proxy.scrollTo("round-\(editingRound)", anchor: .top)
                        }
                        
                        // Additional scroll after a delay to ensure good positioning
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo("round-\(editingRound)", anchor: .center)
                            }
                        }
                        
                        // Ensure add round button is visible
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo("add-round-button", anchor: .bottom)
                            }
                        }
                        
                        shouldScrollToActiveCell = false
                    }
                }
                .onChange(of: scrollToRound) { _, roundToScroll in
                    // Auto-scroll to the specified round when triggered
                    if let round = roundToScroll {
                        print("🔍 DEBUG: scrollToRound triggered - scrolling to round \(round)")
                        withAnimation(.easeInOut(duration: 0.8)) {
                            proxy.scrollTo("round-\(round)", anchor: .top)
                        }
                        
                        // Additional scroll to center after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo("round-\(round)", anchor: .center)
                            }
                        }
                        
                        // Clear the trigger after scrolling
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            scrollToRound = nil
                        }
                    }
                }
                .onChange(of: dynamicRounds) { _, newRounds in
                    // Auto-scroll when new round is added and keyboard is open
                    if isScoreFieldFocused {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                // Scroll to the new round
                                proxy.scrollTo("round-\(newRounds)", anchor: .center)
                            }
                        }
                    }
                }
            }
            
            // Save and Undo buttons below the table
            if hasUnsavedChanges {
                HStack(spacing: 12) {
                    // Undo button - COMMENTED OUT
                    /*
                    Button(action: {
                        undoChanges()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                            Text("Undo")
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    */
                    
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal)
    }
    
    private var gameCompletionBanner: some View {
        let winnerInfo = getGameWinner()
        
        return VStack(spacing: 8) {
            HStack {
                Image(systemName: winnerInfo.isTie ? "hand.raised.fill" : "trophy.fill")
                    .font(.title2)
                    .foregroundColor(winnerInfo.isTie ? .orange : .yellow)
                
                Text(winnerInfo.message)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(winnerInfo.isTie ? Color.orange.opacity(0.1) : Color.yellow.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(winnerInfo.isTie ? Color.orange.opacity(0.3) : Color.yellow.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
    
    private var headerRow: some View {
        HStack(spacing: 0) {
            // Round header with info indicator
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: {
                        showGameInfoSheet = true
                    }) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(Color("LightGreen"))
                            .font(.system(size: 12))
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                            .padding(2)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                Text("")
                    .frame(maxWidth: .infinity, minHeight: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
            }
            .frame(width: effectiveDeleteMode ? 40 : 30)
            .background(Color.black.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            
            ForEach(Array(players.enumerated()), id: \.offset) { index, player in
                VStack(spacing: 0) {
                    HStack {
                        // Player name - tappable for editing
                        Button(action: {
                            if canEditSpecificPlayerName(player) {
                                startEditingPlayerName(player, at: index)
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text(player.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                
                                // Child count notification badge for parent players
                                if let childIDs = playerHierarchy[player.playerID], !childIDs.isEmpty {
                                    ZStack {
                                        Circle()
                                            .fill(Color("LightGreen"))
                                            .frame(width: 18, height: 18)
                                        
                                        // Show person icons based on count (up to 3 icons max to fit in circle)
                                        HStack(spacing: 0) {
                                            ForEach(0..<min(childIDs.count, 3), id: \.self) { _ in
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 5, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                            if childIDs.count > 3 {
                                                Text("+")
                                                    .font(.system(size: 5, weight: .bold))
                                                    .foregroundColor(.white)
                                            }
                                        }
                                    }
                                }
                                
                                // Edit indicator
                                if canEditSpecificPlayerName(player) {
                                    Image(systemName: "pencil.circle")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .frame(maxWidth: .infinity)
                        .scaleEffect(canEditSpecificPlayerName(player) ? 1.02 : 1.0)
                        
                        // Delete player icon (only in delete mode)
                        if effectiveDeleteMode {
                            Button(action: {
                                playerToDelete = player
                                showDeletePlayerAlert = true
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                            }
                            .padding(.trailing, 4)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    
                    Text("\(player.total)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                }
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var scoreRows: some View {
        VStack(spacing: 0) {
            ForEach(0..<dynamicRounds, id: \.self) { roundIndex in
                scoreRow(for: roundIndex)
            }
        }
    }
    
    private var addRoundButton: some View {
        Group {
            if canUserEditGame() && canUserEditScores() && canAddRound() {
                // Show add round button when rounds can be added
                HStack(spacing: 0) {
                    // Empty space for round number column alignment
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: effectiveDeleteMode ? 40 : 30, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                        )
                    
                    // Add round button spanning all player columns
                    Button(action: { addRound() }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color("LightGreen"))
                            Text("Add Round")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 2)
                .id("add-round-button") // Add ID for scrolling
            } else if canUserEditGame() && !canAddRound() {
                // Show max rounds reached message
                HStack(spacing: 0) {
                    // Empty space for round number column alignment
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: effectiveDeleteMode ? 40 : 30, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                        )
                    
                    // Max rounds reached message
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.orange)
                        Text("Max Rounds (\(game.maxRounds ?? 8)) Reached")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.orange)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.top, 2)
                .padding(.bottom, 8)
                .id("max-rounds-reached")
            }
        }
    }
    
    private func scoreRow(for roundIndex: Int) -> some View {
        // Break down complex expressions into simpler variables
        let isCurrentRound = editingRound == roundIndex + 1 && isScoreFieldFocused
        let isNewlyAdded = newlyAddedRound == roundIndex + 1
        
        let roundTextColor: Color
        if isCurrentRound {
            roundTextColor = Color.accentColor
        } else if isNewlyAdded {
            roundTextColor = Color.green
        } else {
            roundTextColor = Color.white
        }
        
        let roundBorderColor: Color
        if isCurrentRound {
            roundBorderColor = Color.accentColor
        } else if isNewlyAdded {
            roundBorderColor = Color.green
        } else {
            roundBorderColor = Color.gray.opacity(0.3)
        }
        
        let roundBorderWidth: CGFloat
        if isCurrentRound {
            roundBorderWidth = 1.5
        } else if isNewlyAdded {
            roundBorderWidth = 2.0
        } else {
            roundBorderWidth = 0.5
        }
        
        let backgroundFillColor: Color = isNewlyAdded ? Color.green.opacity(0.1) : Color.clear
        let overlayStrokeColor: Color = isNewlyAdded ? Color.green.opacity(0.3) : Color.gray.opacity(0.2)
        let overlayStrokeWidth: CGFloat = isNewlyAdded ? 1.0 : 0.5
        let scaleEffect: CGFloat = isNewlyAdded ? 1.02 : 1.0
        
        return HStack(spacing: 0) {
            
            HStack(spacing: 2) {
                Text("\(roundIndex + 1)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(roundTextColor)
                    .frame(width: 20, height: 44)
                
                // Delete round icon (only in delete mode)
                if effectiveDeleteMode {
                    Button(action: {
                        roundToDelete = roundIndex + 1
                        showDeleteRoundAlert = true
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    .frame(width: 10, height: 44)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: effectiveDeleteMode ? 40 : 30, height: 44)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(roundBorderColor, lineWidth: roundBorderWidth)
            )
            
            ForEach(players.indices, id: \.self) { colIndex in
                let player = players[colIndex]
                let score = roundIndex < player.scores.count ? player.scores[roundIndex] : -1
                let isEditingThisCell = editingPlayer?.playerID == player.playerID && editingRound == roundIndex + 1 && isScoreFieldFocused
                
                ScoreCell(
                    player: player,
                    roundIndex: roundIndex,
                    canEdit: canUserEditScores(),
                    onScoreTap: { _ in
                        print("🔍 DEBUG: Score cell tapped for player \(player.name), round \(roundIndex + 1)")
                        guard canUserEditScores() else { 
                            print("🔍 DEBUG: User cannot edit scores")
                            return 
                        }
                        
                        // Auto-save current input if we're switching from another cell
                        if let currentEditingPlayer = editingPlayer, 
                           (currentEditingPlayer.playerID != player.playerID || editingRound != roundIndex + 1) {
                            let currentScore = parseScoreInput(scoreInputText) ?? 0
                            updateScore(playerID: currentEditingPlayer.playerID, round: editingRound, newScore: currentScore)
                            awaitSaveChangesSilently()
                        }
                        
                        editingPlayer = player
                        editingRound = roundIndex + 1
                        // Only show existing score if it has been explicitly entered by user
                        let hasBeenEntered = hasScoreBeenEntered(for: player.playerID, round: roundIndex + 1)
                        print("🔍 DEBUG: Cell tap - Player: \(player.name), Round: \(roundIndex + 1), Score: \(score), HasBeenEntered: \(hasBeenEntered)")
                        
                        if hasBeenEntered && score != -1 {
                            scoreInputText = getDisplayText(for: score) ?? String(score)
                            print("🔍 DEBUG: Setting scoreInputText to: \(scoreInputText)")
                        } else {
                            scoreInputText = "" // Show empty for unentered scores
                            print("🔍 DEBUG: Setting scoreInputText to empty string")
                        }
                        isScoreFieldFocused = true
                        showSystemKeyboard = true
                        print("🔍 DEBUG: Set isScoreFieldFocused = true")
                    },
                    currentScore: score,
                    backgroundColor: columnColor(colIndex),
                    displayText: isEditingThisCell ? scoreInputText : getDisplayText(for: score),
                    isFocused: isEditingThisCell,
                    hasScoreBeenEntered: hasScoreBeenEntered(for: player.playerID, round: roundIndex + 1)
                )
            }
        }
        .id("round-\(roundIndex + 1)") // Add ID for scrolling
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundFillColor)
        )
        .scaleEffect(scaleEffect)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(overlayStrokeColor, lineWidth: overlayStrokeWidth)
        )
        .animation(isNewlyAdded ? .easeInOut(duration: 0.5).repeatCount(3, autoreverses: true) : .default, value: isNewlyAdded)
    }
    
    private var totalRow: some View {
        HStack(spacing: 0) {
            // Consistent first column (round + delete icon space)
                            Rectangle()
                    .fill(Color.clear)
                    .frame(width: effectiveDeleteMode ? 40 : 30, height: 44)
                    .overlay(
                        Rectangle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
            
            ForEach(players) { player in
                let total = player.total
                Text("\(total)")
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .fontWeight(.bold)
                    .background(Color(.systemGray6))
                    .overlay(
                        Rectangle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                    )
            }
        }
    }
    
    // Helper for cell coloring
    func cellColor(for player: TestPlayer, round: Int) -> Color {
        return Color.green.opacity(0.15)
    }
    
    // Column color matching Testview style with better dark mode support
    func columnColor(_ index: Int) -> Color {
        switch index {
        case 0: return .orange
        case 1: return .blue
        case 2: return .green
        case 3: return .purple
        case 4: return .pink
        case 5: return .teal
        case 6: return .indigo
        case 7: return .mint
        default: return .cyan
        }
    }
    
    // Convert score to display text using custom rules
    func getDisplayText(for score: Int) -> String? {
        if score == -1 {
            return nil // Empty cell
        }
        
        // Check if there's a custom rule for this score
        if let customRule = customRules.first(where: { $0.value == score }) {
            return customRule.letter
        }
        
        // Otherwise return the score as string
        return String(score)
    }
    
    // Parse input text to score value (handles custom letters and numbers)
    func parseScoreInput(_ input: String) -> Int? {
        print("🔍 DEBUG: parseScoreInput called with: '\(input)'")
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        print("🔍 DEBUG: trimmedInput: '\(trimmedInput)'")
        
        if trimmedInput.isEmpty {
            print("🔍 DEBUG: Input is empty, returning nil")
            return nil
        }
        
        // First check if it's a custom rule letter
        if let customRule = customRules.first(where: { $0.letter == trimmedInput }) {
            print("🔍 DEBUG: Found custom rule: \(customRule.letter) = \(customRule.value)")
            return customRule.value
        }
        
        // Otherwise try to parse as regular number
        if let number = Int(trimmedInput) {
            print("🔍 DEBUG: Parsed as number: \(number)")
            return number
        }
        
        print("🔍 DEBUG: Failed to parse input, returning nil")
        return nil
    }
    
    // Check if a score has been explicitly entered for a player and round
    func hasScoreBeenEntered(for playerID: String, round: Int) -> Bool {
        let scoreKey = "\(playerID)-\(round)"
        
        // Check if this score has been explicitly entered by the user
        if enteredScores.contains(scoreKey) {
            print("🔍 DEBUG: hasScoreBeenEntered(\(playerID), \(round)) = true (found in enteredScores)")
            return true
        }
        
        // Check if there's a saved score in the backend (this indicates a score was explicitly saved)
        if let savedScores = lastSavedScores[playerID], round <= savedScores.count {
            let scoreValue = savedScores[round - 1] // Convert to 0-based index
            let hasBeenEntered = scoreValue != -1 // Only consider it entered if it's not -1 (empty)
            print("🔍 DEBUG: hasScoreBeenEntered(\(playerID), \(round)) = \(hasBeenEntered) (savedScores[\(round-1)] = \(scoreValue))")
            return hasBeenEntered
        }
        
        print("🔍 DEBUG: hasScoreBeenEntered(\(playerID), \(round)) = false (not found in enteredScores or lastSavedScores)")
        return false
    }
    
    // Load child player usernames for hierarchy
    func loadChildPlayerUsernames() async {
        print("🔍 DEBUG: Loading child player usernames...")
        
        let allChildPlayers = playerHierarchy.values.flatMap { $0 }
        
        // Extract display names from "userId:username" format, prioritizing fresh username from cache
        for childPlayerIdentifier in allChildPlayers {
            let displayName: String
            let components = childPlayerIdentifier.components(separatedBy: ":")
            
            if components.count > 1 {
                // Has "userId:username" format
                let userId = components[0]
                let storedUsername = components[1]
                
                // Priority 1: Try to get fresh username from DataManager's in-memory cache
                if let user = DataManager.shared.getUser(userId) {
                    displayName = user.username ?? storedUsername
                    print("🔍 DEBUG: Using fresh username '\(displayName)' from DataManager for '\(userId)'")
                } else if let cachedUsername = UsernameCacheService.shared.cachedUsernames[userId] {
                    // Priority 2: Try to get from UsernameCacheService
                    displayName = cachedUsername
                    print("🔍 DEBUG: Using cached username '\(displayName)' from UsernameCacheService for '\(userId)'")
                } else {
                    // Priority 3: Use stored username as fallback
                    displayName = storedUsername
                    print("🔍 DEBUG: Using stored username '\(displayName)' from identifier '\(childPlayerIdentifier)'")
                }
            } else if childPlayerIdentifier.hasPrefix("user_") || childPlayerIdentifier.hasPrefix("guest_") {
                // Plain userId format - try to get fresh username from DataManager first
                if let user = DataManager.shared.getUser(childPlayerIdentifier) {
                    displayName = user.username ?? UsernameCacheService.shared.getDisplayName(for: childPlayerIdentifier)
                    print("🔍 DEBUG: Fetched username '\(displayName)' from DataManager for userId '\(childPlayerIdentifier)'")
                } else {
                    displayName = UsernameCacheService.shared.getDisplayName(for: childPlayerIdentifier)
                    print("🔍 DEBUG: Fetched username '\(displayName)' from cache for userId '\(childPlayerIdentifier)'")
                }
            } else {
                // Anonymous player name - use as-is
                displayName = childPlayerIdentifier
                print("🔍 DEBUG: Using display name '\(displayName)' as-is")
            }
            
            await MainActor.run {
                childPlayerNames[childPlayerIdentifier] = displayName
            }
        }
        
        print("🔍 DEBUG: Loaded \(childPlayerNames.count) child player usernames")
    }
    
    // Get display name for a player with hierarchy information
    func getPlayerDisplayName(for playerID: String) -> String {
        if let baseDisplayName = playerNames[playerID] ?? childPlayerNames[playerID] {
            // If this is a parent player with children, show child count
            if let childPlayers = playerHierarchy[playerID], !childPlayers.isEmpty {
                return "\(baseDisplayName) (\(childPlayers.count) players)"
            }
            return baseDisplayName
        }
        
        // Fallback to playerID if no display name found
        if let childPlayers = playerHierarchy[playerID], !childPlayers.isEmpty {
            return "\(playerID) (\(childPlayers.count) players)"
        }
        return playerID
    }
    
    // Check if current user can edit scores for a specific player
    func canCurrentUserEditScores(for playerID: String) -> Bool {
        // For child players, check if user can edit the parent's scores
        if let parentPlayer = game.getParentPlayer(forChild: playerID) {
            return game.canUserEditScores(for: parentPlayer, userId: currentUserID)
        }
        
        // For parent players or regular players, check normally
        return game.canUserEditScores(for: playerID, userId: currentUserID)
    }
    
    // Get the actual player ID for score operations (parent for children, self for parents/regular)
    func getScorePlayerID(for displayPlayerID: String) -> String {
        if let parentPlayer = game.getParentPlayer(forChild: displayPlayerID) {
            return parentPlayer
        }
        return displayPlayerID
    }
    
    // Load game data efficiently
    func loadGameData(suppressCompletionCelebration: Bool = false) {
        print("🔍 DEBUG: ===== LOAD GAME DATA START =====")
        print("🔍 DEBUG: Game ID: \(game.id)")
        print("🔍 DEBUG: Game rounds: \(game.rounds)")
        print("🔍 DEBUG: Dynamic rounds: \(dynamicRounds)")
        print("🔍 DEBUG: Game playerIDs: \(game.playerIDs)")
        print("🔍 DEBUG: Current players before load: \(players.count)")
        print("🔍 DEBUG: showGameSettings: \(showGameSettings), showGameListSheet: \(showGameListSheet)")
        for (index, player) in players.enumerated() {
            print("🔍 DEBUG: Player \(index) (\(player.name)) current scores: \(player.scores)")
        }
        print("🔍 DEBUG: Current unsavedScores keys: \(unsavedScores.keys)")
        for (playerID, scores) in unsavedScores {
            print("🔍 DEBUG: Unsaved scores for \(playerID): \(scores)")
        }
        
        // Load custom rules from game
        customRules = CustomRulesManager.shared.jsonToRules(game.customRules)
        print("🔍 DEBUG: Loaded \(customRules.count) custom rules from game")
        
        // Load player hierarchy from game
        playerHierarchy = game.getPlayerHierarchy()
        print("🔍 DEBUG: Loaded player hierarchy: \(playerHierarchy)")
        
        isLoading = true
        
        Task {
            do {
                // Verify game still exists on backend
                do {
                    let getResult = try await Amplify.API.query(request: .get(Game.self, byId: game.id))
                    switch getResult {
                    case .success(let maybeGame):
                        if maybeGame == nil {
                            await MainActor.run {
                                print("🔍 DEBUG: Game not found on backend. Notifying parent to show empty state.")
                                self.isGameDeleted = true
                                self.players = []
                                self.unsavedScores = [:]
                                self.lastSavedScores = [:]
                                self.isLoading = false
                                self.onGameDeleted?()
                            }
                            return
                        }
                    case .failure:
                        break // transient; continue
                    }
                } catch {
                    // network/transient; continue to try loading scores
                }
                // First, load usernames for registered users
                await loadPlayerUsernames()
                
                // Load child player usernames if hierarchy exists
                if !playerHierarchy.isEmpty {
                    await loadChildPlayerUsernames()
                }
                
                // Fetch scores for this game only (server-side filtering)
                let scoresQuery = Score.keys.gameID.eq(game.id)
                let scoresResult = try await Amplify.API.query(request: .list(Score.self, where: scoresQuery))
                
                await MainActor.run {
                    switch scoresResult {
                    case .success(let gameScores):
                        print("🔍 DEBUG: Found \(gameScores.count) scores for this game")
                        
                        // Process player names and scores
                        self.playerData = [:]
                        
                        // Initialize scores for all players in the game
                        for (index, playerID) in game.playerIDs.enumerated() {
                            // Determine player name based on playerID format
                            let playerName: String
                            if playerID.contains(":") {
                                // Anonymous user with format "userID:displayName" - use display name
                                playerName = getPlayerName(for: playerID)
                            } else if playerID.hasPrefix("guest_") {
                                // Guest user (registered but with guest_ prefix) - use cached username or fallback
                                playerName = getPlayerName(for: playerID)
                            } else if playerID.count > 20 && playerID.contains("-") {
                                // Cognito authenticated user (UUID format) - use cached username or fallback
                                playerName = getPlayerName(for: playerID)
                            } else {
                                // Simple display name (like "Team 1", "Team 2") - use directly
                                playerName = playerID
                            }
                            self.playerData[playerID] = (name: playerName, scores: Array(repeating: -1, count: dynamicRounds))
                        }
                        
                        // Add child players to playerData with inherited scores
                        for (parentID, childIDs) in playerHierarchy {
                            for childID in childIDs {
                                let childName = getPlayerName(for: childID)
                                // Child players inherit parent's scores (will be set after parent scores are loaded)
                                self.playerData[childID] = (name: childName, scores: Array(repeating: -1, count: dynamicRounds))
                            }
                        }
                        
                        // Fill in actual scores from database
                        print("🔍 DEBUG: Processing \(gameScores.count) scores from database")
                        for score in gameScores {
                            print("🔍 DEBUG: Score from DB - playerID: \(score.playerID), roundNumber: \(score.roundNumber), score: \(score.score)")
                            if let existingPlayerData = self.playerData[score.playerID],
                               score.roundNumber <= dynamicRounds {
                                var updatedScores = existingPlayerData.scores
                                let roundIndex = score.roundNumber - 1 // Convert 1-based round to 0-based index
                                print("🔍 DEBUG: Updating player \(score.playerID) round \(score.roundNumber) (index \(roundIndex)) to score \(score.score)")
                                updatedScores[roundIndex] = score.score
                                self.playerData[score.playerID] = (name: existingPlayerData.name, scores: updatedScores)
                                
                                // Inherit scores to child players
                                if let childPlayers = playerHierarchy[score.playerID] {
                                    for childID in childPlayers {
                                        if var childData = self.playerData[childID] {
                                            childData.scores[roundIndex] = score.score
                                            self.playerData[childID] = childData
                                            print("🔍 DEBUG: Inherited score \(score.score) to child player \(childID) for round \(score.roundNumber)")
                                        }
                                    }
                                }
                            } else {
                                print("🔍 DEBUG: Skipping score - playerID: \(score.playerID), roundNumber: \(score.roundNumber), dynamicRounds: \(dynamicRounds)")
                            }
                        }
                        
                        // Merge with unsaved scores to preserve current state
                        for (playerID, unsavedPlayerScores) in unsavedScores {
                            if let existingPlayerData = self.playerData[playerID] {
                                var mergedScores = existingPlayerData.scores
                                
                                // Ensure the merged scores array has the correct size
                                while mergedScores.count < dynamicRounds {
                                    mergedScores.append(-1)
                                }
                                if mergedScores.count > dynamicRounds {
                                    mergedScores = Array(mergedScores.prefix(dynamicRounds))
                                }
                                
                                // Apply unsaved scores (they take precedence)
                                for (roundIndex, unsavedScore) in unsavedPlayerScores.enumerated() {
                                    if roundIndex < mergedScores.count {
                                        mergedScores[roundIndex] = unsavedScore
                                    }
                                }
                                
                                self.playerData[playerID] = (name: existingPlayerData.name, scores: mergedScores)
                                print("🔍 DEBUG: Merged scores for \(playerID): \(mergedScores)")
                                
                                // Inherit unsaved scores to child players
                                if let childPlayers = playerHierarchy[playerID] {
                                    for childID in childPlayers {
                                        if var childData = self.playerData[childID] {
                                            var childMergedScores = childData.scores
                                            
                                            // Ensure the child scores array has the correct size
                                            while childMergedScores.count < dynamicRounds {
                                                childMergedScores.append(-1)
                                            }
                                            if childMergedScores.count > dynamicRounds {
                                                childMergedScores = Array(childMergedScores.prefix(dynamicRounds))
                                            }
                                            
                                            // Apply unsaved scores to child
                                            for (roundIndex, unsavedScore) in unsavedPlayerScores.enumerated() {
                                                if roundIndex < childMergedScores.count {
                                                    childMergedScores[roundIndex] = unsavedScore
                                                }
                                            }
                                            
                                            childData.scores = childMergedScores
                                            self.playerData[childID] = childData
                                            print("🔍 DEBUG: Inherited unsaved scores to child player \(childID): \(childMergedScores)")
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Convert to TestPlayer array - ONLY for parent players (not children)
                        self.players = self.playerData.compactMap { playerID, data in
                            // Skip child players - they don't get their own columns
                            let isChildPlayer = playerHierarchy.values.flatMap { $0 }.contains(playerID)
                            if isChildPlayer {
                                return nil
                            }
                            
                            // Ensure scores array matches dynamic rounds
                            var scores = data.scores
                            while scores.count < dynamicRounds {
                                scores.append(-1) // Add -1 for missing rounds (empty cells)
                            }
                            // Truncate if there are more scores than rounds
                            if scores.count > dynamicRounds {
                                scores = Array(scores.prefix(dynamicRounds))
                            }
                            
                            // Add child count badge to parent player name if they have children
                            var displayName = data.name
                            if let childIDs = playerHierarchy[playerID], !childIDs.isEmpty {
                                displayName = data.name // Will add badge in UI
                            }
                            
                            return TestPlayer(
                                name: displayName,
                                scores: scores,
                                playerID: playerID
                            )
                        }.sorted { $0.name < $1.name }
                        

                        
                        print("🔍 DEBUG: Created \(self.players.count) players")
                        for (index, player) in self.players.enumerated() {
                            print("🔍 DEBUG: Player \(index) (\(player.name)) final scores: \(player.scores)")
                        }
                        
                        // Initialize last saved scores (only from database, not unsaved)
                        self.lastSavedScores = playerData.mapValues { $0.scores }
                        
                        // Populate enteredScores set for existing scores from database
                        self.enteredScores.removeAll()
                        for score in gameScores {
                            let scoreKey = "\(score.playerID)-\(score.roundNumber)"
                            self.enteredScores.insert(scoreKey)
                        }
                        
                        // Update DataManager with all loaded scores for reactive leaderboard calculation
                        DataManager.shared.onScoresUpdated(Array(gameScores))
                        
                        // Check for game completion and winner (only if game is not already completed)
                        // Celebration will only be shown when user explicitly hits "Complete Game" button
                        if !suppressCompletionCelebration && game.gameStatus != .completed {
                            checkGameCompletionAndWinner()
                        }
                        

                        

                        
                    case .failure(let error):
                        print("Error loading scores: \(error)")
                        // Fallback to empty players
                        self.players = []
                    }
                    
                    self.isLoading = false
                    print("🔍 DEBUG: ===== LOAD GAME DATA END =====")
                }
                
            } catch {
                await MainActor.run {
                    print("Error in loadGameData: \(error)")
                    self.players = []
                    self.isLoading = false
                    print("🔍 DEBUG: ===== LOAD GAME DATA END (ERROR) =====")
                }
            }
        }
    }
    
    // Force UI refresh by incrementing counter
    func forceUIRefresh() {
        gameUpdateCounter += 1
    }
    
    // Save only unsaved scores without clearing the unsaved state
    func saveUnsavedScoresOnly() async {
        guard hasUnsavedChanges else { return }
        
        print("🔍 DEBUG: ===== SAVE UNSAVED SCORES ONLY START =====")
        print("🔍 DEBUG: Unsaved scores keys: \(unsavedScores.keys)")
        for (playerID, scores) in unsavedScores {
            print("🔍 DEBUG: Player \(playerID) unsaved scores: \(scores)")
        }
        print("🔍 DEBUG: Last saved scores keys: \(lastSavedScores.keys)")
        for (playerID, scores) in lastSavedScores {
            print("🔍 DEBUG: Player \(playerID) last saved scores: \(scores)")
        }
        
        do {
            // First, fetch existing scores for this game only (server-side filtering)
            let scoresQuery = Score.keys.gameID.eq(game.id)
            let scoresResult = try await Amplify.API.query(request: .list(Score.self, where: scoresQuery))
            
            switch scoresResult {
            case .success(let existingScores):
                var existingScoreMap: [String: Score] = [:]
                
                print("🔍 DEBUG: Found \(existingScores.count) existing scores for this game")
                
                // Create a map of existing scores for quick lookup
                for score in existingScores {
                    let key = "\(score.playerID)-\(score.roundNumber)"
                    existingScoreMap[key] = score
                    print("🔍 DEBUG: Existing score: \(score.playerID) round \(score.roundNumber) = \(score.score)")
                }
                
                // Process all unsaved changes - ONLY for parent players (not children)
                for (playerID, scores) in unsavedScores {
                    // Skip child players - they don't have their own scores
                    let isChildPlayer = playerHierarchy.values.flatMap { $0 }.contains(playerID)
                    if isChildPlayer {
                        print("🔍 DEBUG: Skipping score save for child player: \(playerID)")
                        continue
                    }
                    
                    print("🔍 DEBUG: Processing unsaved scores for player \(playerID): \(scores)")
                    for (roundIndex, score) in scores.enumerated() {
                        let roundNumber = roundIndex + 1
                        
                        // Ensure lastSavedScores array is properly sized
                        var lastSavedScore = -1  // Default to -1 (empty) if no last saved score
                        if let lastSavedArray = lastSavedScores[playerID], roundIndex < lastSavedArray.count {
                            lastSavedScore = lastSavedArray[roundIndex]
                        }
                        
                        print("🔍 DEBUG: Round \(roundNumber) - current: \(score), last saved: \(lastSavedScore)")
                        
                        // Only persist scores that are not -1 (empty). Zero is a valid score and should be saved.
                            let scoreKey = "\(playerID)-\(roundNumber)"
                        let existing = existingScoreMap[scoreKey]
                        if score == -1 {
                            // Empty cell (-1): delete if exists, skip if doesn't exist
                            if let existingScore = existing {
                                print("🔍 DEBUG: Empty cell (-1) and exists -> delete for player \(playerID) round \(roundNumber)")
                                let _ = try await Amplify.API.mutate(request: .delete(existingScore))
                            } else {
                                print("🔍 DEBUG: Empty cell (-1) and no existing -> skip create for player \(playerID) round \(roundNumber)")
                            }
                            continue
                        }

                        // Valid score (including 0): create or update if changed
                        if score != lastSavedScore || existing == nil {
                            print("🔍 DEBUG: Persist score \(score) for player \(playerID) round \(roundNumber)")
                            let scoreObject = Score(
                                id: "\(game.id)-\(playerID)-\(roundNumber)",
                                gameID: game.id,
                                playerID: playerID,
                                roundNumber: roundNumber,
                                score: score,
                                createdAt: Temporal.DateTime.now(),
                                updatedAt: Temporal.DateTime.now()
                            )
                            if existing != nil {
                                let result = try await Amplify.API.mutate(request: .update(scoreObject))
                                switch result {
                                case .success(let updatedScore):
                                    await MainActor.run {
                                        DataManager.shared.onScoresUpdated([updatedScore])
                                    }
                                case .failure(let error):
                                    print("Error updating score: \(error)")
                                }
                            } else {
                                let result = try await Amplify.API.mutate(request: .create(scoreObject))
                                switch result {
                                case .success(let createdScore):
                                    await MainActor.run {
                                        DataManager.shared.onScoresUpdated([createdScore])
                                    }
                                case .failure(let error):
                                    print("Error creating score: \(error)")
                                }
                            }
                        } else {
                            print("🔍 DEBUG: Non-zero unchanged and exists -> skip for player \(playerID) round \(roundNumber)")
                        }
                    }
                }
                
                await MainActor.run {
                    // Update the last saved state with the current unsaved scores
                    for (playerID, scores) in unsavedScores {
                        lastSavedScores[playerID] = scores
                    }
                    // Don't clear unsavedScores or hasUnsavedChanges - keep them for the UI
                }
                
            case .failure(let error):
                print("🔍 DEBUG: Failed to fetch existing scores: \(error)")
            }
            
        } catch {
            print("🔍 DEBUG: Error saving unsaved scores: \(error)")
        }
    }
    
    // Save unsaved changes to the backend
    func saveChanges() {
        guard hasUnsavedChanges || !players.isEmpty else { return }
        
        print("🔍 DEBUG: ===== SAVE CHANGES START =====")
        print("🔍 DEBUG: Building full scores map from current table values for all players")
        
        // Build a complete map of scores for all players from the current table view
        var scoresForAllPlayers: [String: [Int]] = [:]
        for player in players {
            var row = player.scores
            // Ensure correct length for current dynamic rounds
            while row.count < dynamicRounds { row.append(-1) }
            if row.count > dynamicRounds { row = Array(row.prefix(dynamicRounds)) }
            scoresForAllPlayers[player.playerID] = row
            print("🔍 DEBUG: Table scores for \(player.playerID): \(row)")
        }
        
        Task {
            do {
                // Fetch existing scores for this game only (server-side filtering)
                let scoresQuery = Score.keys.gameID.eq(game.id)
                let scoresResult = try await Amplify.API.query(request: .list(Score.self, where: scoresQuery))
                
                switch scoresResult {
                case .success(let existingScores):
                    var existingScoreMap: [String: Score] = [:]
                    print("🔍 DEBUG: Found \(existingScores.count) existing scores for this game")
                    for score in existingScores {
                        let key = "\(score.playerID)-\(score.roundNumber)"
                        existingScoreMap[key] = score
                        print("🔍 DEBUG: Existing score: \(score.playerID) round \(score.roundNumber) = \(score.score)")
                    }
                    
                    // Process every player and every round based on the table values - ONLY for parent players
                    for (playerID, scoresRow) in scoresForAllPlayers {
                        // Skip child players - they don't have their own scores
                        let isChildPlayer = playerHierarchy.values.flatMap { $0 }.contains(playerID)
                        if isChildPlayer {
                            print("🔍 DEBUG: Skipping score save for child player: \(playerID)")
                            continue
                        }
                        
                        for (roundIndex, scoreValue) in scoresRow.enumerated() {
                            let roundNumber = roundIndex + 1
                            let lastSavedArray = lastSavedScores[playerID] ?? []
                            let lastSavedScore = (roundIndex < lastSavedArray.count) ? lastSavedArray[roundIndex] : -1
                            let scoreKey = "\(playerID)-\(roundNumber)"
                            let existing = existingScoreMap[scoreKey]

                            if scoreValue == -1 {
                                // Empty cell (-1): delete if exists; else do nothing
                                if let existingScore = existing {
                                    print("🔍 DEBUG: DELETE empty cell (-1) for \(playerID) r\(roundNumber)")
                                    let _ = try await Amplify.API.mutate(request: .delete(existingScore))
                                } else {
                                    print("🔍 DEBUG: SKIP create empty cell (-1) for \(playerID) r\(roundNumber)")
                                }
                                continue
                            }

                            // Valid score (including 0): create or update
                            if existing == nil || scoreValue != lastSavedScore {
                                print("🔍 DEBUG: UPSERT score \(scoreValue) for \(playerID) r\(roundNumber)")
                            let scoreObject = Score(
                                id: "\(game.id)-\(playerID)-\(roundNumber)",
                                gameID: game.id,
                                playerID: playerID,
                                roundNumber: roundNumber,
                                score: scoreValue,
                                createdAt: Temporal.DateTime.now(),
                                updatedAt: Temporal.DateTime.now()
                            )
                                if existing != nil {
                                    let _ = try await Amplify.API.mutate(request: .update(scoreObject))
                                } else {
                                    let _ = try await Amplify.API.mutate(request: .create(scoreObject))
                                }
                            } else {
                                print("🔍 DEBUG: SKIP unchanged non-zero for \(playerID) r\(roundNumber)")
                            }
                        }
                    }
                    
                    await MainActor.run {
                        // Sync lastSavedScores with the table values we just persisted
                        lastSavedScores = scoresForAllPlayers
                        hasUnsavedChanges = false
                        unsavedScores = [:]
                        showToastMessage(message: "Game saved successfully", icon: "checkmark.circle.fill")
                        // Avoid full reload to prevent flicker; table already reflects current state
                    }
                
                case .failure(let error):
                    print("🔍 DEBUG: Failed to fetch existing scores: \(error)")
                }
            } catch {
                print("🔍 DEBUG: Error saving scores: \(error)")
            }
        }
    }
    
    // Undo all unsaved changes
    func undoChanges() {
        // Revert to the last saved state
        unsavedScores = [:]
        hasUnsavedChanges = false
        
        // Update the players array to reflect the reverted changes
        updatePlayersFromUnsavedScores()
        
        print("🔍 DEBUG: Undo performed - reverted to last saved state")
    }
    
    // Update score for a specific player and round
    func updateScore(playerID: String, round: Int, newScore: Int) {
        print("🔍 DEBUG: ===== UPDATE SCORE =====")
        print("🔍 DEBUG: playerID: \(playerID), round: \(round), newScore: \(newScore)")
        print("🔍 DEBUG: Current dynamicRounds: \(dynamicRounds)")
        
        // Initialize unsaved scores if needed, preserving existing scores
        if unsavedScores[playerID] == nil {
            print("🔍 DEBUG: No unsaved scores found for playerID: \(playerID)")
            // Start with the current player scores as the base
            if let currentPlayer = players.first(where: { $0.playerID == playerID }) {
                unsavedScores[playerID] = currentPlayer.scores
                print("🔍 DEBUG: Initialized unsaved scores from current player: \(currentPlayer.scores)")
            } else {
                // Fallback to -1 (empty) if player not found
                unsavedScores[playerID] = Array(repeating: -1, count: dynamicRounds)
                print("🔍 DEBUG: Initialized unsaved scores with -1: \(Array(repeating: -1, count: dynamicRounds))")
            }
        }
        
        // Ensure the unsaved scores array has enough elements for the current dynamic rounds
        if var playerScores = unsavedScores[playerID] {
            print("🔍 DEBUG: Original player scores: \(playerScores)")
            // Resize the array if needed
            while playerScores.count < dynamicRounds {
                playerScores.append(-1) // Add -1 for new rounds (empty cells)
            }
            // Truncate if there are more scores than rounds
            if playerScores.count > dynamicRounds {
                playerScores = Array(playerScores.prefix(dynamicRounds))
            }
            unsavedScores[playerID] = playerScores
            print("🔍 DEBUG: Resized player scores: \(playerScores)")
        }
        
        // Update only the specific round
        if round > 0 && round <= dynamicRounds {
            unsavedScores[playerID]?[round - 1] = newScore
            // Mark this score as explicitly entered by user (including 0)
            let scoreKey = "\(playerID)-\(round)"
            enteredScores.insert(scoreKey)
            print("🔍 DEBUG: Updated round \(round) to score \(newScore)")
            print("🔍 DEBUG: Final unsaved scores for playerID \(playerID): \(unsavedScores[playerID] ?? [])")
        }
        
        hasUnsavedChanges = true
        
        // Update the players array to reflect the change immediately
        updatePlayersFromUnsavedScores()
        
        print("🔍 DEBUG: ===== UPDATE SCORE END =====")
    }
    
    // Update the players array from unsaved scores
    func updatePlayersFromUnsavedScores() {
        print("🔍 DEBUG: ===== UPDATE PLAYERS FROM UNSAVED SCORES =====")
        print("🔍 DEBUG: Current dynamicRounds: \(dynamicRounds)")
        print("🔍 DEBUG: Players count: \(players.count)")
        print("🔍 DEBUG: UnsavedScores keys: \(unsavedScores.keys)")
        
        for (index, player) in players.enumerated() {
            print("🔍 DEBUG: Processing player \(index) (\(player.name))")
            print("🔍 DEBUG: Current player scores: \(player.scores)")
            
            if let unsavedPlayerScores = unsavedScores[player.playerID] {
                print("🔍 DEBUG: Found unsaved scores for player: \(unsavedPlayerScores)")
                var updatedScores = player.scores
                
                // Ensure the updatedScores array has the correct size for dynamic rounds
                while updatedScores.count < dynamicRounds {
                    updatedScores.append(-1) // Add -1 for missing rounds (empty cells)
                }
                if updatedScores.count > dynamicRounds {
                    updatedScores = Array(updatedScores.prefix(dynamicRounds))
                }
                
                print("🔍 DEBUG: Resized updatedScores: \(updatedScores)")
                
                // Only update the scores that have been changed in unsavedScores
                for (roundIndex, unsavedScore) in unsavedPlayerScores.enumerated() {
                    if roundIndex < updatedScores.count {
                        // Only update if this round has been modified (different from last saved)
                        let lastSavedArray = lastSavedScores[player.playerID] ?? []
                        let lastSavedScore = (roundIndex < lastSavedArray.count) ? lastSavedArray[roundIndex] : -1
                        if unsavedScore != lastSavedScore {
                            updatedScores[roundIndex] = unsavedScore
                            print("🔍 DEBUG: Updated round \(roundIndex) to \(unsavedScore)")
                        }
                    }
                }
                
                players[index] = TestPlayer(
                    name: player.name,
                    scores: updatedScores,
                    playerID: player.playerID
                )
                print("🔍 DEBUG: Final updated scores for player \(index): \(updatedScores)")
            } else {
                print("🔍 DEBUG: No unsaved scores found for player \(index)")
                // If no unsaved scores for this player, revert to last saved state
                var lastSavedPlayerScores = lastSavedScores[player.playerID] ?? Array(repeating: 0, count: dynamicRounds)
                
                // Ensure the lastSavedPlayerScores array has the correct size
                while lastSavedPlayerScores.count < dynamicRounds {
                    lastSavedPlayerScores.append(0)
                }
                if lastSavedPlayerScores.count > dynamicRounds {
                    lastSavedPlayerScores = Array(lastSavedPlayerScores.prefix(dynamicRounds))
                }
                
                players[index] = TestPlayer(
                    name: player.name,
                    scores: lastSavedPlayerScores,
                    playerID: player.playerID
                )
                print("🔍 DEBUG: Using last saved scores: \(lastSavedPlayerScores)")
            }
        }
        
        print("🔍 DEBUG: ===== UPDATE PLAYERS FROM UNSAVED SCORES END =====")
    }
    
    // Move focus to next zero-valued score in the same round
    func moveToNextZeroCellInSameRound() {
        guard let currentPlayer = editingPlayer else { return }
        let roundIndex = editingRound - 1
        // Find current player's index in players
        guard let currentIndex = players.firstIndex(where: { $0.playerID == currentPlayer.playerID }) else { return }
        // Search forward wrapping around once
        let total = players.count
        var nextIndex: Int? = nil
        for offset in 1...total { // check all others
            let idx = (currentIndex + offset) % total
            let val = (roundIndex < players[idx].scores.count) ? players[idx].scores[roundIndex] : -1
            let pending = unsavedScores[players[idx].playerID]?[roundIndex]
            let effective = pending ?? val
            if effective == -1 {
                nextIndex = idx
                break
            }
        }
        if let idx = nextIndex {
            let player = players[idx]
            editingPlayer = player
            // Show current score (empty for -1) in input field
            let currentScore = (roundIndex < player.scores.count) ? player.scores[roundIndex] : -1
            // Only show score if it has been explicitly entered by user
            if hasScoreBeenEntered(for: player.playerID, round: roundIndex + 1) && currentScore != -1 {
                scoreInputText = getDisplayText(for: currentScore) ?? String(currentScore)
            } else {
                scoreInputText = "" // Show empty for unentered scores
            }
            // Keep same round
            isScoreFieldFocused = true
        } else {
            // No more zeros; dismiss keyboard and clear editing state
            isScoreFieldFocused = false
            editingPlayer = nil
        }
    }
    
    // Show score input dialog
    func showScoreInputDialog(player: TestPlayer, round: Int, currentScore: Int) {
        editingPlayer = player
        editingRound = round
        editingScore = currentScore
        showScoreInput = true
    }
    
    // Get player name efficiently
    func getPlayerName(for playerID: String) -> String {
        if playerID.contains(":") {
            // Anonymous user with format "userID:displayName"
            let components = playerID.split(separator: ":", maxSplits: 1)
            if components.count == 2 {
                return String(components[1])
            }
        }
        
        // For registered users, check if we have a cached username
        if let cachedUsername = playerNames[playerID] {
            return cachedUsername
        }
        
        // Fallback to short ID if no cached username
        return String(playerID.prefix(8))
    }
    
    // Load usernames for registered users efficiently
    func loadPlayerUsernames() async {
        print("🔍 DEBUG: Loading usernames for registered users...")
        
        // Extract registered user IDs (both guest users and Cognito authenticated users)
        let registeredUserIDs = game.playerIDs.filter { playerID in
            // Guest users (guest_ prefix) or Cognito authenticated users (UUID format)
            (playerID.hasPrefix("guest_") || (playerID.count > 20 && playerID.contains("-"))) && !playerID.contains(":")
        }
        
        if registeredUserIDs.isEmpty {
            print("🔍 DEBUG: No registered users to look up")
            return
        }
        
        print("🔍 DEBUG: Looking up usernames for \(registeredUserIDs.count) registered users")
        
        do {
            // Query all users and filter locally for the specific user IDs we need
            // This is still efficient since we're only looking up a few specific users
            let result = try await Amplify.API.query(
                request: .list(User.self)
            )
            
            await MainActor.run {
                switch result {
                case .success(let allUsers):
                    print("🔍 DEBUG: Successfully fetched \(allUsers.count) total users")
                    
                    // Filter to only the users we need
                    let neededUsers = allUsers.filter { registeredUserIDs.contains($0.id) }
                    print("🔍 DEBUG: Found \(neededUsers.count) users out of \(registeredUserIDs.count) needed")
                    
                    // Cache the usernames
                    for user in neededUsers {
                        self.playerNames[user.id] = user.username
                        print("🔍 DEBUG: Cached username '\(user.username)' for user ID '\(user.id)'")
                    }
                    
                    // Check for any missing users
                    let foundUserIDs = Set(neededUsers.map { $0.id })
                    let missingUserIDs = Set(registeredUserIDs).subtracting(foundUserIDs)
                    
                    if !missingUserIDs.isEmpty {
                        print("🔍 DEBUG: Warning: Could not find usernames for \(missingUserIDs.count) users: \(missingUserIDs)")
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG: Error fetching usernames: \(error)")
                }
            }
            
        } catch {
            print("🔍 DEBUG: Error in loadPlayerUsernames: \(error)")
            }
}

// MARK: - System Keyboard with Enhanced Toolbar
struct SystemKeyboardView: View {
    @Binding var text: String
    @Binding var isVisible: Bool
    @Binding var editingPlayer: TestPlayer?
    @Binding var editingRound: Int
    let players: [TestPlayer]
    let updateScore: (String, Int, Int) -> Void
    let awaitSaveChangesSilently: () -> Void
    let customRuleLetter: String
    let parseScoreInput: (String) -> Int?
    let dynamicRounds: Int
    let hasScoreBeenEntered: (String, Int) -> Bool
    let canAddRound: () -> Bool
    let addRound: () -> Void
    let maxRounds: Int
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Gap between keyboard and toolbar
            Rectangle()
                .fill(Color.clear)
                .frame(height: 32)
            
            // Enhanced toolbar (Cancel, Save, CustomLetter, Next)
            enhancedToolbarView
                .background(Color(UIColor.systemBackground))
                .shadow(radius: 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(isVisible ? .easeInOut(duration: 0.15) : nil, value: isVisible)
        }
        .onTapGesture {
            // Dismiss keyboard when tapping outside
            if isVisible {
                isVisible = false
            }
        }
    }
    
    private var enhancedToolbarView: some View {
        HStack(spacing: 16) {
            // Cancel
                    Button("Cancel") {
                        text = ""
                        isVisible = false
                    }
            .foregroundColor(.red)
                    .font(.body)
            .fontWeight(.medium)
                    
                    Spacer()
                    
            // Save button (live preview commented out)
                    HStack(spacing: 8) {
                        // Live preview commented out
                        /*
                        Text(text.isEmpty ? "0" : text)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .monospacedDigit()
                            .frame(minWidth: 40)
                        */
                        
                        Button("Save") {
                            print("🔍 DEBUG: Save button tapped in SystemKeyboardView")
                            saveCurrentScore()
                            isVisible = false
                        }
                .foregroundColor(.blue)
                        .font(.body)
                        .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
            // Custom Letter (if available) - Between Save and Next
            let trimmedLetter = customRuleLetter.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedLetter.isEmpty && trimmedLetter.count > 0 && trimmedLetter != "" && trimmedLetter.rangeOfCharacter(from: .letters) != nil {
                Button(trimmedLetter) {
                    text += trimmedLetter
                }
                .foregroundColor(.green)
                .font(.body)
                .fontWeight(.semibold)
                .frame(width: 40, height: 32)
                .background(Color.green.opacity(0.2))
                .cornerRadius(8)
            }
            
            Spacer()
            
            // Next
                    Button("Next") {
                saveCurrentScore()
                moveToNextEmptyCell()
                // Keep keyboard open
            }
            .foregroundColor(.blue)
            .font(.body)
            .fontWeight(.semibold)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(Color(UIColor.systemGray6))
    }
    
    private func saveCurrentScore() {
        print("🔍 DEBUG: ===== SAVE CURRENT SCORE (KEYBOARD) =====")
        print("🔍 DEBUG: text value: '\(text)'")
        print("🔍 DEBUG: editingPlayer: \(editingPlayer?.name ?? "nil")")
        print("🔍 DEBUG: editingRound: \(editingRound)")
        
        if let currentScore = parseScoreInput(text) {
            print("🔍 DEBUG: Parsed score: \(currentScore)")
            updateScore(editingPlayer?.playerID ?? "", editingRound, currentScore)
            awaitSaveChangesSilently()
            print("🔍 DEBUG: Score saved successfully")
        } else {
            print("🔍 DEBUG: Failed to parse score from text: '\(text)'")
        }
        print("🔍 DEBUG: ===== SAVE CURRENT SCORE END =====")
    }
                        
    private func moveToNextEmptyCell() {
        print("🔍 DEBUG: ===== MOVE TO NEXT EMPTY CELL START =====")
        print("🔍 DEBUG: Current editingPlayer: \(editingPlayer?.name ?? "nil")")
        print("🔍 DEBUG: Current editingRound: \(editingRound)")
        print("🔍 DEBUG: Players count: \(players.count)")
        
        // Find next empty cell
        if let currentPlayer = editingPlayer, let currentPlayerIndex = players.firstIndex(where: { $0.playerID == currentPlayer.playerID }) {
            print("🔍 DEBUG: Current player index: \(currentPlayerIndex)")
            
            var nextPlayerIndex = currentPlayerIndex
            var nextRound = editingRound
            var foundEmpty = false
            
            // Start searching from the next player in the same round
            let startPlayerOffset = 1
            let maxRounds = dynamicRounds
            
            print("🔍 DEBUG: Starting search - maxRounds: \(maxRounds)")
            
            // Try to find next empty cell
            roundLoop: for roundOffset in 0...maxRounds {
                let testRound = editingRound + roundOffset
                
                guard testRound <= maxRounds else {
                    print("🔍 DEBUG: Round \(testRound) exceeds maxRounds \(maxRounds), breaking")
                    break
                }
                
                let playerStart = (roundOffset == 0) ? startPlayerOffset : 0
                
                for playerOffset in playerStart..<players.count {
                    let testPlayerIndex = (currentPlayerIndex + playerOffset) % players.count
                    let testPlayer = players[testPlayerIndex]
                    
                    print("🔍 DEBUG: Testing player \(testPlayerIndex) (\(testPlayer.name)), round \(testRound)")
                    
                    // Check if this cell is empty (score == -1)
                    if testRound - 1 < testPlayer.scores.count {
                        let score = testPlayer.scores[testRound - 1]
                        let hasBeenEntered = hasScoreBeenEntered(testPlayer.playerID, testRound)
                        
                        print("🔍 DEBUG: Score: \(score), hasBeenEntered: \(hasBeenEntered)")
                        
                        if score == -1 || !hasBeenEntered {
                            print("🔍 DEBUG: ✅ Found empty cell at player \(testPlayerIndex), round \(testRound)")
                            nextPlayerIndex = testPlayerIndex
                            nextRound = testRound
                            foundEmpty = true
                            break roundLoop
                        }
                    }
                }
            }
            
            if foundEmpty {
                print("🔍 DEBUG: Moving to next cell - Player: \(players[nextPlayerIndex].name), Round: \(nextRound)")
                // Move to next empty cell
                editingPlayer = players[nextPlayerIndex]
                editingRound = nextRound
                text = "" // Clear for next input
                // Keep keyboard open by not setting isVisible = false
            } else {
                print("🔍 DEBUG: No empty cells found")
                
                // Check if we can add a round
                if canAddRound() {
                    print("🔍 DEBUG: 🎯 Adding new round automatically (current: \(dynamicRounds), max: \(maxRounds))")
                    
                    // Add a new round
                    addRound()
                    
                    // Wait a brief moment for the round to be added, then move to first player of new round
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        let newRound = dynamicRounds + 1
                        if !players.isEmpty {
                            editingPlayer = players[0]
                            editingRound = newRound
                            text = ""
                            print("🔍 DEBUG: 📍 Moved to Player: \(players[0].name), Round: \(newRound)")
                        }
                    }
                    
                    // Keep keyboard open
                } else {
                    print("🔍 DEBUG: Cannot add round - at max limit (\(maxRounds)), dismissing keyboard")
                    // At max rounds, dismiss keyboard
                    isVisible = false
                }
            }
        } else {
            print("🔍 DEBUG: No currentPlayer or invalid index, dismissing keyboard")
            isVisible = false
        }
        
        print("🔍 DEBUG: ===== MOVE TO NEXT EMPTY CELL END =====")
    }
    

}



// MARK: - Toast Message View
    struct ToastMessageView: View {
        let message: String
        let icon: String
        @Binding var isVisible: Bool
        
        var body: some View {
            HStack(spacing: 12) {
                // Profile picture or icon
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: icon.isEmpty ? "checkmark" : icon)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    )
                
                // Message text
                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.9)) // Light green background for success
            )
            .padding(.horizontal, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.5), value: isVisible) // Slower animation
        }
    }
    
    // MARK: - Dynamic Rounds Management
    
    private func canAddRound() -> Bool {
        let maxRounds = game.maxRounds ?? 8
        let canAdd = dynamicRounds < maxRounds
        print("🔍 DEBUG: canAddRound() - current: \(dynamicRounds), max: \(maxRounds), canAdd: \(canAdd)")
        return canAdd
    }
    
    func addRound() {
        guard canUserEditGame() else { return }
        guard canAddRound() else { 
            print("🔍 DEBUG: Cannot add round - max rounds (\(game.maxRounds ?? 8)) reached")
            showToastMessage(message: "Max rounds (\(game.maxRounds ?? 8)) reached", icon: "exclamationmark.triangle.fill")
            return 
        }
        
        print("🔍 DEBUG: ===== ADD ROUND START =====")
        print("🔍 DEBUG: Current dynamicRounds: \(dynamicRounds)")
        print("🔍 DEBUG: Current players count: \(players.count)")
        print("🔍 DEBUG: Current unsavedScores keys: \(unsavedScores.keys)")
        
        // Store current scores before adding round
        let currentScores = unsavedScores
        print("🔍 DEBUG: Stored current scores for \(currentScores.count) players")
        
        // Log current player scores
        for (index, player) in players.enumerated() {
            print("🔍 DEBUG: Player \(index) (\(player.name)) scores: \(player.scores)")
        }
        
        // Add a new round
        dynamicRounds += 1
        print("🔍 DEBUG: New dynamicRounds: \(dynamicRounds)")
        
        // Resize all unsaved scores arrays to accommodate the new round
        // while preserving existing scores
        for (playerID, scores) in currentScores {
            var updatedScores = scores
            print("🔍 DEBUG: Player \(playerID) original scores: \(updatedScores)")
            // Ensure we have enough elements for the new round count
            while updatedScores.count < dynamicRounds {
                updatedScores.append(-1) // Add -1 to indicate empty cells (not entered)
            }
            unsavedScores[playerID] = updatedScores
            print("🔍 DEBUG: Player \(playerID) updated scores: \(updatedScores)")
        }
        
        // Also update the players array to reflect the new round count
        // while preserving existing scores
        for i in 0..<players.count {
            var updatedScores = players[i].scores
            print("🔍 DEBUG: Player \(i) (\(players[i].name)) original scores: \(updatedScores)")
            while updatedScores.count < dynamicRounds {
                updatedScores.append(-1) // Add -1 to indicate empty cells (not entered)
            }
            players[i] = TestPlayer(
                name: players[i].name,
                scores: updatedScores,
                playerID: players[i].playerID
            )
            print("🔍 DEBUG: Player \(i) (\(players[i].name)) updated scores: \(updatedScores)")
        }
        
        // Also resize lastSavedScores arrays to prevent index out of bounds errors
        for (playerID, scores) in lastSavedScores {
            var updatedLastSavedScores = scores
            while updatedLastSavedScores.count < dynamicRounds {
                updatedLastSavedScores.append(-1) // Add -1 to indicate empty cells (not entered)
            }
            lastSavedScores[playerID] = updatedLastSavedScores
            print("🔍 DEBUG: Resized lastSavedScores for \(playerID): \(updatedLastSavedScores)")
        }
        
        // Clear enteredScores for the new round to ensure it shows as empty
        for playerID in game.playerIDs {
            let scoreKey = "\(playerID)-\(dynamicRounds)"
            enteredScores.remove(scoreKey)
        }
        
        print("🔍 DEBUG: After updating players array:")
        for (index, player) in players.enumerated() {
            print("🔍 DEBUG: Player \(index) (\(player.name)) final scores: \(player.scores)")
        }
        
        // Update the game object
        var updatedGame = game
        updatedGame.rounds = dynamicRounds
        updatedGame.updatedAt = Temporal.DateTime.now()
        
        // Update the binding
        self.game = updatedGame
        
        // Set the newly added round for highlighting
        newlyAddedRound = dynamicRounds
        
        // Trigger auto-scroll to the new round after a brief delay to ensure UI is updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            scrollToRound = dynamicRounds
        }
        
        // Clear the highlight after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            newlyAddedRound = nil
        }
        
        // Don't show toast for routine round addition
        
        print("🔍 DEBUG: ===== ADD ROUND END =====")
        
        // Save the game update and any unsaved scores first
        Task {
            do {
                // First, save any unsaved scores to ensure they're preserved
                if hasUnsavedChanges {
                    print("🔍 DEBUG: Saving unsaved scores before adding round")
                    await saveUnsavedScoresOnly()
                }
                
                let result = try await Amplify.API.mutate(request: .update(updatedGame))
                switch result {
                case .success(let updatedGame):
                    await MainActor.run {
                        self.game = updatedGame
                        self.onGameUpdated?(updatedGame)
                    }
                case .failure(let error):
                    print("🔍 DEBUG: Failed to update game with new round: \(error)")
                    await MainActor.run {
                        showToastMessage(message: "Failed to save round", icon: "exclamationmark.circle.fill")
                    }
                }
            } catch {
                print("🔍 DEBUG: Error updating game: \(error)")
                await MainActor.run {
                    showToastMessage(message: "Error updating game", icon: "exclamationmark.circle.fill")
                }
            }
        }
    }
    
    func removeRound() {
        guard canUserEditGame() && dynamicRounds > 1 else { return }
        
        print("🔍 DEBUG: ===== REMOVE ROUND START =====")
        print("🔍 DEBUG: Removing round \(roundToRemove)")
        print("🔍 DEBUG: Current dynamicRounds: \(dynamicRounds)")
        
        // Store current scores before removing round
        let currentScores = unsavedScores
        
        // Remove the round
        dynamicRounds -= 1
        
        // Resize all unsaved scores arrays to match the new round count
        // while preserving existing scores
        for (playerID, scores) in currentScores {
            var updatedScores = scores
            // Truncate to the new round count
            if updatedScores.count > dynamicRounds {
                updatedScores = Array(updatedScores.prefix(dynamicRounds))
            }
            unsavedScores[playerID] = updatedScores
        }
        
        // Also update the players array to reflect the new round count
        // while preserving existing scores
        for i in 0..<players.count {
            var updatedScores = players[i].scores
            if updatedScores.count > dynamicRounds {
                updatedScores = Array(updatedScores.prefix(dynamicRounds))
            }
            players[i] = TestPlayer(
                name: players[i].name,
                scores: updatedScores,
                playerID: players[i].playerID
            )
        }
        
        // Update the game object
        var updatedGame = game
        updatedGame.rounds = dynamicRounds
        updatedGame.updatedAt = Temporal.DateTime.now()
        
        // Update the binding
        self.game = updatedGame
        
        // Clean up enteredScores for the removed round
        for playerID in game.playerIDs {
            let scoreKey = "\(playerID)-\(roundToRemove)"
            enteredScores.remove(scoreKey)
        }
        
        // Show success message
        // Don't show toast for routine round removal
        
        // Save the game update and delete scores for the removed round
        Task {
            do {
                print("🔍 DEBUG: Deleting scores for round \(roundToRemove)")
                
                // Fetch scores for this game only (server-side filtering)
                let scoresQuery = Score.keys.gameID.eq(game.id)
                let scoresResult = try await Amplify.API.query(request: .list(Score.self, where: scoresQuery))
                
                switch scoresResult {
                case .success(let gameScores):
                    print("🔍 DEBUG: Found \(gameScores.count) scores for this game")
                    
                    // Delete scores for the removed round
                    let scoresToDelete = gameScores.filter { $0.roundNumber == roundToRemove }
                    print("🔍 DEBUG: Found \(scoresToDelete.count) scores to delete for round \(roundToRemove)")
                    
                    for score in scoresToDelete {
                        print("🔍 DEBUG: Deleting score for player \(score.playerID), round \(score.roundNumber)")
                        let deleteResult = try await Amplify.API.mutate(request: .delete(score))
                        switch deleteResult {
                        case .success(let deletedScore):
                            print("🔍 DEBUG: Successfully deleted score: \(deletedScore.id)")
                        case .failure(let error):
                            print("🔍 DEBUG: Failed to delete score: \(error)")
                        }
                    }
                    
                    // Now update the game object
                    let result = try await Amplify.API.mutate(request: .update(updatedGame))
                    switch result {
                    case .success(let updatedGame):
                        await MainActor.run {
                            self.game = updatedGame
                            self.onGameUpdated?(updatedGame)
                        }
                        print("🔍 DEBUG: Successfully updated game after removing round")
                    case .failure(let error):
                        print("🔍 DEBUG: Failed to update game after removing round: \(error)")
                        await MainActor.run {
                            showToastMessage(message: "Failed to save changes", icon: "exclamationmark.circle.fill")
                        }
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG: Failed to fetch scores for deletion: \(error)")
                    await MainActor.run {
                        showToastMessage(message: "Failed to clean up scores", icon: "exclamationmark.circle.fill")
                    }
                }
                
            } catch {
                print("🔍 DEBUG: Error removing round: \(error)")
                await MainActor.run {
                    showToastMessage(message: "Error updating game", icon: "exclamationmark.circle.fill")
                }
            }
        }
        
        print("🔍 DEBUG: ===== REMOVE ROUND END =====")
    }
    
    func deletePlayer(_ player: TestPlayer) {
        guard canUserEditGame() && players.count > 1 else { return }
        
        print("🔍 DEBUG: ===== DELETE PLAYER START =====")
        print("🔍 DEBUG: Deleting player: \(player.name) (\(player.playerID))")
        
        // Remove player from local arrays
        players.removeAll { $0.playerID == player.playerID }
        unsavedScores.removeValue(forKey: player.playerID)
        playerNames.removeValue(forKey: player.playerID)
        
        // Update the game object
        var updatedGame = game
        updatedGame.playerIDs.removeAll { $0 == player.playerID }
        updatedGame.updatedAt = Temporal.DateTime.now()
        
        // Update the binding
        self.game = updatedGame
        
        // Exit delete mode
        isDeleteMode = false
        
        // Show success message
        showToastMessage(message: "\(player.name) removed from game", icon: "person.badge.minus")
        
        // Save the game update and delete scores for the removed player
        Task {
            do {
                print("🔍 DEBUG: Deleting scores for player \(player.playerID)")
                
                // Fetch scores for this game and player
                let scoresQuery = Score.keys.gameID.eq(game.id).and(Score.keys.playerID.eq(player.playerID))
                let scoresResult = try await Amplify.API.query(request: .list(Score.self, where: scoresQuery))
                
                switch scoresResult {
                case .success(let playerScores):
                    print("🔍 DEBUG: Found \(playerScores.count) scores for player \(player.playerID)")
                    
                    // Delete all scores for this player
                    for score in playerScores {
                        print("🔍 DEBUG: Deleting score for player \(score.playerID), round \(score.roundNumber)")
                        let deleteResult = try await Amplify.API.mutate(request: .delete(score))
                        switch deleteResult {
                        case .success(let deletedScore):
                            print("🔍 DEBUG: Successfully deleted score: \(deletedScore.id)")
                        case .failure(let error):
                            print("🔍 DEBUG: Failed to delete score: \(error)")
                        }
                    }
                    
                    // Now update the game object
                    let result = try await Amplify.API.mutate(request: .update(updatedGame))
                    switch result {
                    case .success(let updatedGame):
                        await MainActor.run {
                            self.game = updatedGame
                            self.onGameUpdated?(updatedGame)
                        }
                        print("🔍 DEBUG: Successfully updated game after deleting player")
                    case .failure(let error):
                        print("🔍 DEBUG: Failed to update game after deleting player: \(error)")
                        await MainActor.run {
                            showToastMessage(message: "Failed to save changes", icon: "exclamationmark.circle.fill")
                        }
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG: Failed to fetch scores for deletion: \(error)")
                    await MainActor.run {
                        showToastMessage(message: "Failed to delete player scores", icon: "exclamationmark.circle.fill")
                    }
                }
            } catch {
                print("🔍 DEBUG: Error deleting player: \(error)")
                await MainActor.run {
                    showToastMessage(message: "Error deleting player", icon: "exclamationmark.circle.fill")
                }
            }
        }
    }
    
    func deleteRound(_ roundNumber: Int) {
        guard canUserEditGame() && dynamicRounds > 1 && roundNumber <= dynamicRounds else { return }
        
        print("🔍 DEBUG: ===== DELETE ROUND START =====")
        print("🔍 DEBUG: Deleting round \(roundNumber)")
        print("🔍 DEBUG: Current dynamicRounds: \(dynamicRounds)")
        
        // Store current scores before removing round
        let currentScores = unsavedScores
        
        // Remove the round
        dynamicRounds -= 1
        
        // Resize all unsaved scores arrays to match the new round count
        // while preserving existing scores (excluding the deleted round)
        for (playerID, scores) in currentScores {
            var updatedScores = scores
            // Remove the specific round and shift remaining scores
            if roundNumber <= updatedScores.count {
                updatedScores.remove(at: roundNumber - 1)
            }
            // Truncate to the new round count
            if updatedScores.count > dynamicRounds {
                updatedScores = Array(updatedScores.prefix(dynamicRounds))
            }
            unsavedScores[playerID] = updatedScores
        }
        
        // Also update the players array to reflect the new round count
        // while preserving existing scores (excluding the deleted round)
        for i in 0..<players.count {
            var updatedScores = players[i].scores
            // Remove the specific round and shift remaining scores
            if roundNumber <= updatedScores.count {
                updatedScores.remove(at: roundNumber - 1)
            }
            // Truncate to the new round count
            if updatedScores.count > dynamicRounds {
                updatedScores = Array(updatedScores.prefix(dynamicRounds))
            }
            players[i] = TestPlayer(
                name: players[i].name,
                scores: updatedScores,
                playerID: players[i].playerID
            )
        }
        
        // Update the game object
        var updatedGame = game
        updatedGame.rounds = dynamicRounds
        updatedGame.updatedAt = Temporal.DateTime.now()
        
        // Update the binding
        self.game = updatedGame
        
        // Clean up enteredScores for the deleted round
        for playerID in game.playerIDs {
            let scoreKey = "\(playerID)-\(roundNumber)"
            enteredScores.remove(scoreKey)
        }
        
        // Exit delete mode
        isDeleteMode = false
        
        // Show success message
        // Don't show toast for routine round deletion
        
        // Save the game update and delete scores for the removed round
        Task {
            do {
                print("🔍 DEBUG: Deleting scores for round \(roundNumber)")
                
                // Fetch scores for this game only (server-side filtering)
                let scoresQuery = Score.keys.gameID.eq(game.id)
                let scoresResult = try await Amplify.API.query(request: .list(Score.self, where: scoresQuery))
                
                switch scoresResult {
                case .success(let gameScores):
                    print("🔍 DEBUG: Found \(gameScores.count) scores for this game")
                    
                    // Delete scores for the removed round
                    let scoresToDelete = gameScores.filter { $0.roundNumber == roundNumber }
                    print("🔍 DEBUG: Found \(scoresToDelete.count) scores to delete for round \(roundNumber)")
                    
                    for score in scoresToDelete {
                        print("🔍 DEBUG: Deleting score for player \(score.playerID), round \(score.roundNumber)")
                        let deleteResult = try await Amplify.API.mutate(request: .delete(score))
                        switch deleteResult {
                        case .success(let deletedScore):
                            print("🔍 DEBUG: Successfully deleted score: \(deletedScore.id)")
                        case .failure(let error):
                            print("🔍 DEBUG: Failed to delete score: \(error)")
                        }
                    }
                    
                    // Now update the game object
                    let result = try await Amplify.API.mutate(request: .update(updatedGame))
                    switch result {
                    case .success(let updatedGame):
                        await MainActor.run {
                            self.game = updatedGame
                            self.onGameUpdated?(updatedGame)
                        }
                        print("🔍 DEBUG: Successfully updated game after deleting round")
                    case .failure(let error):
                        print("🔍 DEBUG: Failed to update game after deleting round: \(error)")
                        await MainActor.run {
                            showToastMessage(message: "Failed to save changes", icon: "exclamationmark.circle.fill")
                        }
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG: Failed to fetch scores for deletion: \(error)")
                    await MainActor.run {
                        showToastMessage(message: "Failed to delete round scores", icon: "exclamationmark.circle.fill")
                    }
                }
            } catch {
                print("🔍 DEBUG: Error deleting round: \(error)")
                await MainActor.run {
                    showToastMessage(message: "Error deleting round", icon: "exclamationmark.circle.fill")
                }
            }
        }
    }
    
    func deleteGame() {
        guard canUserEditGame() && game.gameStatus == .active else { return }
        
        print("🔍 DEBUG: ===== DELETE GAME START =====")
        print("🔍 DEBUG: Deleting game: \(game.id)")
        
        // Exit delete mode
        isDeleteMode = false
        
        // Show success message
        showToastMessage(message: "Game deleted", icon: "trash.circle.fill")
        
        // Delete the game and all related scores
        Task {
            do {
                print("🔍 DEBUG: Deleting all scores for game \(game.id)")
                
                // Fetch all scores for this game
                let scoresQuery = Score.keys.gameID.eq(game.id)
                let scoresResult = try await Amplify.API.query(request: .list(Score.self, where: scoresQuery))
                
                switch scoresResult {
                case .success(let gameScores):
                    print("🔍 DEBUG: Found \(gameScores.count) scores to delete for game \(game.id)")
                    
                    // Delete all scores for this game
                    for score in gameScores {
                        print("🔍 DEBUG: Deleting score for player \(score.playerID), round \(score.roundNumber)")
                        let deleteResult = try await Amplify.API.mutate(request: .delete(score))
                        switch deleteResult {
                        case .success(let deletedScore):
                            print("🔍 DEBUG: Successfully deleted score: \(deletedScore.id)")
                        case .failure(let error):
                            print("🔍 DEBUG: Failed to delete score: \(error)")
                        }
                    }
                    
                    // Now delete the game itself
                    let gameDeleteResult = try await Amplify.API.mutate(request: .delete(game))
                    switch gameDeleteResult {
                    case .success(let deletedGame):
                        print("🔍 DEBUG: Successfully deleted game: \(deletedGame.id)")
                        await MainActor.run {
                            // Update DataManager to remove deleted game and scores from reactive system
                            DataManager.shared.onGameDeleted(deletedGame)
                            
                            // Notify parent that game was deleted
                            self.onGameDeleted?()
                        }
                    case .failure(let error):
                        print("🔍 DEBUG: Failed to delete game: \(error)")
                        await MainActor.run {
                            showToastMessage(message: "Failed to delete game", icon: "exclamationmark.circle.fill")
                        }
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG: Failed to fetch scores for deletion: \(error)")
                    await MainActor.run {
                        showToastMessage(message: "Failed to delete game scores", icon: "exclamationmark.circle.fill")
                    }
                }
                
            } catch {
                print("🔍 DEBUG: Error deleting game: \(error)")
                await MainActor.run {
                    showToastMessage(message: "Error deleting game", icon: "exclamationmark.circle.fill")
                }
            }
        }
        
        print("🔍 DEBUG: ===== DELETE GAME END =====")
    }
    
    // MARK: - Show Toast Message
    func showToastMessage(message: String, icon: String = "checkmark") {
        toastMessage = message
        toastIcon = icon
        showToast = true
        
        // Animate in
        withAnimation(.easeInOut(duration: 0.5)) {
            toastOpacity = 1.0
        }
        
        // Auto-hide after 3 seconds with slow fade-out
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 1.5)) { // Very slow fade-out animation
                toastOpacity = 0.0
            }
            
            // Hide the toast view after fade-out completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showToast = false
                toastOpacity = 0.0
            }
        }
    }

    // MARK: - Silent Save (no celebration or toast)
    func awaitSaveChangesSilently() {
        guard hasUnsavedChanges || !players.isEmpty else { return }
        var scoresForAllPlayers: [String: [Int]] = [:]
        for player in players {
            var row = player.scores
            while row.count < dynamicRounds { row.append(-1) }
            if row.count > dynamicRounds { row = Array(row.prefix(dynamicRounds)) }
            scoresForAllPlayers[player.playerID] = row
        }
        Task {
            do {
                let scoresQuery = Score.keys.gameID.eq(game.id)
                let scoresResult = try await Amplify.API.query(request: .list(Score.self, where: scoresQuery))
                switch scoresResult {
                case .success(let existingScores):
                    var existingScoreMap: [String: Score] = [:]
                    for score in existingScores {
                        let key = "\(score.playerID)-\(score.roundNumber)"
                        existingScoreMap[key] = score
                    }
                    for (playerID, scoresRow) in scoresForAllPlayers {
                        // Skip child players - they don't have their own scores
                        let isChildPlayer = playerHierarchy.values.flatMap { $0 }.contains(playerID)
                        if isChildPlayer {
                            print("🔍 DEBUG: Skipping score save for child player: \(playerID)")
                            continue
                        }
                        
                        for (roundIndex, scoreValue) in scoresRow.enumerated() {
                            let roundNumber = roundIndex + 1
                            let scoreKey = "\(playerID)-\(roundNumber)"
                            let existing = existingScoreMap[scoreKey]
                            if scoreValue == -1 {
                                // Empty cell (-1): delete if exists
                                if let existingScore = existing {
                                    let _ = try await Amplify.API.mutate(request: .delete(existingScore))
                                }
                                continue
                            }
                            let lastSavedArray = lastSavedScores[playerID] ?? []
                            let lastSavedScore = (roundIndex < lastSavedArray.count) ? lastSavedArray[roundIndex] : -1
                            if existing == nil || scoreValue != lastSavedScore {
                                if existing != nil {
                                    // Update existing score - preserve original createdAt
                                    var updatedScore = existing!
                                    updatedScore.score = scoreValue
                                    updatedScore.updatedAt = Temporal.DateTime.now()
                                    
                                    let result = try await Amplify.API.mutate(request: .update(updatedScore))
                                    switch result {
                                    case .success(let updatedScore):
                                        await MainActor.run {
                                            DataManager.shared.onScoresUpdated([updatedScore])
                                        }
                                    case .failure(let error):
                                        print("Error updating score: \(error)")
                                    }
                                } else {
                                    // Create new score
                                    let scoreObject = Score(
                                        id: "\(game.id)-\(playerID)-\(roundNumber)",
                                        gameID: game.id,
                                        playerID: playerID,
                                        roundNumber: roundNumber,
                                        score: scoreValue,
                                        createdAt: Temporal.DateTime.now(),
                                        updatedAt: Temporal.DateTime.now()
                                    )
                                    let result = try await Amplify.API.mutate(request: .create(scoreObject))
                                    switch result {
                                    case .success(let createdScore):
                                        await MainActor.run {
                                            DataManager.shared.onScoresUpdated([createdScore])
                                        }
                                    case .failure(let error):
                                        print("Error creating score: \(error)")
                                    }
                                }
                            }
                        }
                    }
                    await MainActor.run {
                        lastSavedScores = scoresForAllPlayers
                        hasUnsavedChanges = false
                        unsavedScores = [:]
                        // Do not reload data to avoid flicker; local state is already up to date
                    }
                case .failure:
                    break
                }
            } catch {
                // Silent failure
            }
        }
    }

    // MARK: - Complete Game
    func completeGame() {
        print("🔍 DEBUG: completeGame() called")
        print("🔍 DEBUG: canUserEditGame(): \(canUserEditGame())")
        print("🔍 DEBUG: isGameComplete(): \(isGameComplete())")
        print("🔍 DEBUG: completeGame() - Initial game status: \(self.game.gameStatus)")
        guard canUserEditGame() && isGameComplete() else { 
            print("🔍 DEBUG: completeGame() - Guard failed, returning early")
            return 
        }
        
        // Trigger celebration when user explicitly completes the game
        checkGameCompletionAndWinner(showCelebration: true)
        
        // Update local state immediately for better UX
        var updated = game
        updated.gameStatus = .completed
        updated.updatedAt = Temporal.DateTime.now()
        print("🔍 DEBUG: completeGame() - 'updated' game status before assignment: \(updated.gameStatus)")
        
        // Update local game state immediately
        self.game = updated
        self.gameUpdateCounter += 1
        
        print("🔍 DEBUG: completeGame() - Local game status after binding update: \(self.game.gameStatus)")
        
        // Immediately disable delete mode when game is completed
        withAnimation(.easeInOut(duration: 0.3)) {
            isDeleteMode = false
        }
        
        // Force view refresh to update all UI elements
        gameStatusRefreshTrigger += 1
        
        print("🔍 DEBUG: completeGame() - View refresh triggered, gameStatusRefreshTrigger: \(gameStatusRefreshTrigger)")
        
        Task {
            do {
                let result = try await Amplify.API.mutate(request: .update(updated))
                switch result {
                case .success(let saved):
                    await MainActor.run {
                        print("🔍 DEBUG: Game completed successfully on backend")
                        print("🔍 DEBUG: Backend saved game status: \(saved.gameStatus)")
                        // Update with the saved version from backend to ensure consistency
                        self.game = saved
                        // Notify DataManager of the game update for reactive leaderboard calculation
                        DataManager.shared.onGameUpdated(saved)
                        print("🔍 DEBUG: Local game status after backend update: \(self.game.gameStatus)")
                        self.onGameUpdated?(saved)
                        print("🔍 DEBUG: DataManager notified with game status: \(saved.gameStatus)")
                        showToastMessage(message: "Game marked complete", icon: "flag.checkered")
                    }
                case .failure(let error):
                    await MainActor.run {
                        showToastMessage(message: "Failed to complete game", icon: "exclamationmark.circle.fill")
                    }
                    print("🔍 DEBUG: Failed to mark complete: \(error)")
                }
            } catch {
                await MainActor.run {
                    showToastMessage(message: "Error completing game", icon: "exclamationmark.circle.fill")
                }
                print("🔍 DEBUG: Error completing game: \(error)")
            }
        }
    }


    
    // MARK: - View Components
}



struct ScoreboardView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample game for preview
        let sampleGame = Game(
            id: "sample-game-id",
            hostUserID: "host-user-id",
            playerIDs: ["player1", "player2"],
            rounds: 5,
            customRules: nil,
            finalScores: [],
            gameStatus: .active,
            createdAt: Temporal.DateTime.now(),
            updatedAt: Temporal.DateTime.now()
        )
        ScoreboardView(game: .constant(sampleGame), mode: .edit)
    }
}

// MARK: - Celebration View
struct CelebrationView: View {
    let message: String
    let winner: TestPlayer?
    let onDismiss: () -> Void
    
    @State private var balloonPositions: [CGPoint] = []
    @State private var showConfetti = false
    @State private var showMessage = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Celebration content
            VStack(spacing: 30) {
                // Trophy icon
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .scaleEffect(showMessage ? 1.2 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showMessage)
                
                // Winner message
                VStack(spacing: 16) {
                    Text("🎉 GAME COMPLETE! 🎉")
                        .font(.title.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(message)
                        .font(.title2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .opacity(showMessage ? 1 : 0)
                .animation(.easeIn(duration: 0.5), value: showMessage)
                
                // Dismiss button
                Button("Continue") {
                    onDismiss()
                }
                .font(.title3.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(25)
                .opacity(showMessage ? 1 : 0)
                .animation(.easeIn(duration: 0.5).delay(0.3), value: showMessage)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 20)
            )
            .scaleEffect(showMessage ? 1 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showMessage)
            
            // Floating balloons
            ForEach(0..<12, id: \.self) { index in
                BalloonView(color: balloonColors[index % balloonColors.count])
                    .position(
                        x: balloonPositions.indices.contains(index) ? balloonPositions[index].x : 0,
                        y: balloonPositions.indices.contains(index) ? balloonPositions[index].y : UIScreen.main.bounds.height + 100
                    )
                    .animation(
                        .easeInOut(duration: 3)
                        .delay(Double(index) * 0.2),
                        value: balloonPositions
                    )
            }
            
            // Confetti
            if showConfetti {
                ConfettiView()
            }
        }
        .onAppear {
            // Start animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showMessage = true
                showConfetti = true
                generateBalloonPositions()
            }
        }
    }
    
    private func generateBalloonPositions() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        balloonPositions = (0..<12).map { _ in
            CGPoint(
                x: CGFloat.random(in: 50...(screenWidth - 50)),
                y: CGFloat.random(in: 100...(screenHeight - 200))
            )
        }
    }
    
    private let balloonColors: [Color] = [
        .red, .blue, .green, .yellow, .orange, .purple, .pink, .cyan
    ]
}





// MARK: - Game List Bottom Sheet
struct GameListBottomSheet: View {
    let games: [Game]
    @Binding var currentIndex: Int
    let onGameSelected: (Int) -> Void
    var mode: ScoreboardMode = .edit // Add mode parameter
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    // Drag indicator
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                    
                    Text("Select Game")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Latest \(games.count) \(mode == .readCompleted ? "game" : "active game")\(games.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 20)
                
                // Carousel preview
                TabView(selection: $currentIndex) {
                    ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                        GameCardViewBottomSheet(game: game, isSelected: index == currentIndex)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 200)
                .padding(.horizontal, 20)
                
                // Game list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                            GameListItemView(
                                game: game,
                                isSelected: index == currentIndex,
                                onTap: {
                                    onGameSelected(index)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                Spacer()
            }
            .padding()
            .background(GradientBackgroundView())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            print("🔍 DEBUG: GameListBottomSheet onAppear - games count: \(games.count)")
        }
        .onDisappear {
            print("🔍 DEBUG: GameListBottomSheet onDisappear")
        }
    }
}

// MARK: - Game Card View for Bottom Sheet
struct GameCardViewBottomSheet: View {
    let game: Game
    let isSelected: Bool
    @StateObject private var usernameCache = UsernameCacheService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Game name
            Text(game.gameName ?? "Untitled Game")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .lineLimit(1)
            
            // Game info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(game.playerIDs.count) Players")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(game.rounds) Rounds")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Status indicator
                Circle()
                    .fill(isSelected ? Color("LightGreen") : Color.white.opacity(0.3))
                    .frame(width: 12, height: 12)
            }
            
            // Players list
            VStack(alignment: .leading, spacing: 4) {
                Text("Players:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                if usernameCache.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.6)
                        Text("Loading players...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    let playerList = game.playerIDs.map { playerID in
                        usernameCache.getDisplayName(for: playerID)
                    }
                    
                    Text(playerList.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.4))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color("LightGreen") : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onAppear {
            Task {
                await usernameCache.getUsernames(for: game.playerIDs)
            }
        }
    }
}

// MARK: - Game List Item View
struct GameListItemView: View {
    let game: Game
    let isSelected: Bool
    let onTap: () -> Void
    @StateObject private var usernameCache = UsernameCacheService.shared
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Game icon - Animated Logo
                AppLogoIcon(isSelected: isSelected, size: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.gameName ?? "Untitled Game")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(game.playerIDs.count) players • \(game.rounds) rounds")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        if !usernameCache.isLoading {
                            let playerList = game.playerIDs.map { playerID in
                                usernameCache.getDisplayName(for: playerID)
                            }
                            
                            Text(playerList.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("LightGreen"))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color("LightGreen").opacity(0.2) : Color.black.opacity(0.3))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            Task {
                await usernameCache.getUsernames(for: game.playerIDs)
            }
        }
    }
}

// MARK: - Player Name Editor Sheet
struct PlayerNameEditorSheet: View {
    @Binding var playerName: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    // Hierarchy information
    let isHierarchyGame: Bool
    let childPlayers: [String]
    
    /// Extract display name from "userId:username" format, prioritizing fresh username from cache
    private func getDisplayName(for playerIdentifier: String) -> String {
        let components = playerIdentifier.components(separatedBy: ":")
        
        if components.count > 1 {
            // Has "userId:username" format
            let userId = components[0]
            let storedUsername = components[1]
            
            // Priority 1: Try to get fresh username from DataManager's in-memory cache
            if let user = DataManager.shared.getUser(userId) {
                return user.username ?? storedUsername
            }
            
            // Priority 2: Try to get from UsernameCacheService
            let cachedUsername = UsernameCacheService.shared.cachedUsernames[userId]
            if let cachedUsername = cachedUsername {
                return cachedUsername
            }
            
            // Priority 3: Use stored username as fallback
            return storedUsername
        }
        
        // Plain format - check if it's a userId that needs lookup
        if playerIdentifier.hasPrefix("guest_") || playerIdentifier.hasPrefix("user_") || 
           (playerIdentifier.count > 20 && playerIdentifier.contains("-")) {
            // Try to get username from DataManager
            if let user = DataManager.shared.getUser(playerIdentifier) {
                return user.username ?? String(playerIdentifier.prefix(8))
            }
            return String(playerIdentifier.prefix(8))
        }
        
        // Anonymous player or team name - return as-is
        return playerIdentifier
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background for the entire sheet content
                GradientBackgroundView()
                
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.text.rectangle")
                            .font(.system(size: 48))
                            .foregroundColor(Color("LightGreen"))
                        
                        Text(isHierarchyGame ? "Enter a new name for this team" : "Enter a new name for this player")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Name input field
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isHierarchyGame ? "Team Name" : "Player Name")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ZStack(alignment: .leading) {
                            if playerName.isEmpty {
                                Text(isHierarchyGame ? "Enter team name" : "Enter player name")
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.leading, 16)
                            }
                            TextField("", text: $playerName)
                                .font(.body)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .focused($isTextFieldFocused)
                                .onSubmit {
                                    if !playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        onSave()
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Action button
                    VStack(spacing: 12) {
                        Button(action: onSave) {
                            Text("Save Changes")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color("LightGreen"))
                                )
                        }
                        .disabled(playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(.horizontal, 20)
                    
                    // Child players list for hierarchy games
                    if isHierarchyGame && !childPlayers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Team Players")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(childPlayers, id: \.self) { childPlayer in
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(Color("LightGreen"))
                                        
                                        Text(getDisplayName(for: childPlayer))
                                            .font(.body)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        .padding(.vertical, 16)
                        .background(Color.black.opacity(0.2))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
                .navigationTitle(isHierarchyGame ? "Edit Team Name" : "Edit Player Name")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.clear, for: .navigationBar)
                .navigationBarItems(
                    leading: Button("Cancel") { onCancel() }
                        .foregroundColor(.white)
                )
            }
        }
        .onAppear {
            isTextFieldFocused = true
        }
    }
}

// MARK: - Game Info Sheet
struct GameInfoSheet: View {
    let game: Game
    let players: [TestPlayer]
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Game Header
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Game Information")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(game.gameName ?? "Untitled Game")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            Spacer()
                            
                            // Game Status Badge
                            Text(game.gameStatus == .active ? "Active" : "Completed")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(game.gameStatus == .active ? Color.green : Color.orange)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Game Details
                    VStack(spacing: 16) {
                        // Basic Info
                        InfoSection(title: "Basic Information", icon: "gamecontroller.fill") {
                            InfoRow(title: "Game ID", value: String(game.id.prefix(8)).uppercased())
                            InfoRow(title: "Rounds", value: "\(game.rounds)")
                            InfoRow(title: "Created", value: formatDate(game.createdAt.foundationDate ?? Date()))
                            InfoRow(title: "Last Updated", value: formatDate(game.updatedAt.foundationDate ?? Date()))
                        }
                        
                        // Players
                        InfoSection(title: "Players", icon: "person.3.fill") {
                            ForEach(players, id: \.id) { player in
                                HStack {
                                    Text("• \(player.name)")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(player.total) pts")
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.caption)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        
                        // Game Settings
                        InfoSection(title: "Game Settings", icon: "gearshape.fill") {
                            InfoRow(title: "Win Condition", value: game.winCondition == .lowestScore ? "Lowest Score Wins" : "Highest Score Wins")
                            if let maxScore = game.maxScore {
                                InfoRow(title: "Max Score", value: "\(maxScore)")
                            }
                            if let maxRounds = game.maxRounds {
                                InfoRow(title: "Max Rounds", value: "\(maxRounds)")
                            }
                        }
                        
                        // Custom Rules
                        if let customRules = game.customRules, !customRules.isEmpty {
                            InfoSection(title: "Custom Rules", icon: "doc.text.fill") {
                                Text(customRules)
                                    .foregroundColor(.white.opacity(0.9))
                                    .font(.body)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(8)
                            }
                        }
                        
                        // Winner Information (if completed)
                        if game.gameStatus == .completed {
                            InfoSection(title: "Winner", icon: "trophy.fill") {
                                if let winner = determineWinner() {
                                    HStack {
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(.yellow)
                                        Text(winner.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text("\(winner.total) points")
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .padding()
                                    .background(Color.yellow.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)
            }
            .gradientBackground()
            .navigationTitle("Game Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .navigationBarItems(
                trailing: Button("Done") { 
                    isPresented = false
                }
                    .foregroundColor(.white)
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
    
    private func determineWinner() -> TestPlayer? {
        let winCondition = game.winCondition ?? .highestScore
        let sortedPlayers = players.sorted { player1, player2 in
            switch winCondition {
            case .highestScore:
                return player1.total > player2.total
            case .lowestScore:
                return player1.total < player2.total
            }
        }
        return sortedPlayers.first
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Info Section Component
struct InfoSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color("LightGreen"))
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 8) {
                content
            }
            .padding()
            .background(Color.black.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white.opacity(0.7))
                .font(.body)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Triangle Shape for Tooltip Arrow
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

