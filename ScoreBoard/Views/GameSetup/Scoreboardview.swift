//
//  Scoreboardview.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 7/24/25.
//

import SwiftUI
import Amplify

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
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isFocused)
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

struct Scoreboardview: View {
    @Binding var game: Game
    @State private var selectedRound = 1
    @State private var players: [TestPlayer] = []
    @State private var isLoading = true
    @State private var showEditBoard = false
    @State private var showGameSettings = false
    @State private var playerNames: [String: String] = [:]
    @State private var scores: [String: [Int]] = [:]
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
    @FocusState private var isScoreFieldFocused: Bool // Focus for inline numeric input
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

    let onGameUpdated: ((Game) -> Void)?
    let onGameDeleted: (() -> Void)?
    
    init(game: Binding<Game>, onGameUpdated: ((Game) -> Void)? = nil, onGameDeleted: (() -> Void)? = nil) {
        self._game = game
        self._currentGameId = State(initialValue: game.wrappedValue.id)
        self._lastKnownGameRounds = State(initialValue: game.wrappedValue.rounds)
        self._dynamicRounds = State(initialValue: game.wrappedValue.rounds)
        self.onGameUpdated = onGameUpdated
        self.onGameDeleted = onGameDeleted
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
    func checkGameCompletionAndWinner() {
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
            
            // Only show celebration if we haven't shown it before for this game
            if !hasShownCelebrationForGame() {
                showCelebration = true
                markCelebrationAsShown()
                print("🔍 DEBUG: 🎉 GAME COMPLETE! Winner: \(winner?.name ?? "Unknown") with \(winConditionText) score: \(winningScore)")
            }
        } else if winners.count > 1 {
            // We have a tie
            let winnerNames = winners.map { $0.name }.joined(separator: ", ")
            let winConditionText = game.winCondition == .lowestScore ? "lowest" : "highest"
            celebrationMessage = "🤝 It's a tie! 🤝\nCongratulations to \(winnerNames)!\nAll tied with the \(winConditionText) score of \(winningScore)!"
            
            // Only show celebration if we haven't shown it before for this game
            if !hasShownCelebrationForGame() {
                showCelebration = true
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
        print("🔍 DEBUG: Scoreboardview onAppear - Game ID: \(game.id)")
        print("🔍 DEBUG: Current game rounds: \(game.rounds)")
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
                    self.availableGames = userGames
                    // Find current game index
                    if let currentIndex = userGames.firstIndex(where: { $0.id == self.game.id }) {
                        self.currentGameIndex = currentIndex
                    } else {
                        self.currentGameIndex = 0
                    }
                    print("🔍 DEBUG: Loaded \(userGames.count) games, current index: \(self.currentGameIndex)")
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
        
        // Update the game binding immediately
        self.game = updatedGame
        self.currentGameId = updatedGame.id
        self.lastKnownGameRounds = updatedGame.rounds
        self.dynamicRounds = updatedGame.rounds
        
        // Increment counter to trigger reload
        self.gameUpdateCounter += 1
        
        // Call the parent callback
        self.onGameUpdated?(updatedGame)
        
        print("🔍 DEBUG: ===== GAME UPDATE CALLBACK END =====")
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
            
            // Floating Action Button
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
        }
        // EditBoardView sheet - DISABLED: Users now use gear icon for editing
        /*
        .sheet(isPresented: $showEditBoard) {
            EditBoardView(game: game) { updatedGame in
                handleGameUpdate(updatedGame)
            }
        }
        */
        // Remove modal sheet keyboard; use inline system number pad instead
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
        // Persistent accessory bar above the keyboard for Cancel/Save
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
                                let newScore = Int(scoreInputText) ?? 0
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
                                let newScore = Int(scoreInputText) ?? 0
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
        .ignoresSafeArea(.keyboard, edges: .bottom) // Allow keyboard to push content up
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Page indicators
            if availableGames.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<availableGames.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentGameIndex ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentGameIndex ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: currentGameIndex)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
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
            .id("\(game.id)-\(gameStatusRefreshTrigger)") // Force view refresh when game status changes
            // Hidden inline input to trigger the standard iOS number pad
            TextField("", text: $scoreInputText)
                .keyboardType(.decimalPad)
                .focused($isScoreFieldFocused)
                .opacity(0)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
            .background(Color.clear)
            .navigationBarTitleDisplayMode(.large)
            .navigationBarHidden(true)
            .onAppear {
                onAppearAction()
            }
            .onChange(of: gameUpdateCounter) { _, _ in
                print("🔍 DEBUG: Game update counter changed - reloading data")
                loadGameData()
            }
            .onChange(of: game.rounds) { _, newRounds in
                print("🔍 DEBUG: ===== GAME ROUNDS CHANGED =====")
                print("🔍 DEBUG: Game rounds changed to \(newRounds) - updating state and reloading data")
                print("🔍 DEBUG: Previous dynamicRounds: \(dynamicRounds)")
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
                loadGameData()
            }
            .onChange(of: game.id) { _, newGameId in
                print("🔍 DEBUG: Game ID changed to \(newGameId) - updating state and reloading data")
                currentGameId = newGameId
                loadGameData()
            }
            .onChange(of: game.gameStatus) { _, newStatus in
                print("🔍 DEBUG: Game status changed to \(newStatus)")
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
                // Auto-save when input loses focus
                                        if !isFocused && editingPlayer != nil && !scoreInputText.isEmpty {
                            let currentScore = parseScoreInput(scoreInputText) ?? 0
                            updateScore(playerID: editingPlayer!.playerID, round: editingRound, newScore: currentScore)
                            awaitSaveChangesSilently()
                        }
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
        // EditBoardView sheet - DISABLED: Users now use gear icon for editing
        /*
        .sheet(isPresented: $showEditBoard) {
            EditBoardView(game: game) { updatedGame in
                handleGameUpdate(updatedGame)
            }
        }
        */
        .sheet(isPresented: $showGameSettings) {
            CreateGameView(
                showCreateGame: $showGameSettings,
                mode: .edit(game), // This will use the updated game object after handleGameUpdate
                onGameCreated: { _ in }, // Not used in edit mode
                onGameUpdated: { updatedGame in
                    handleGameUpdate(updatedGame)
                }
            )
        }
        .id("game-settings-sheet-\(game.id)-\(gameUpdateCounter)") // Force recreation when game updates
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
    }
    
//    private var scoreInputSheet: some View {
//        Group {
//            if let player = editingPlayer {
//                ScoreInputView(
//                    playerName: player.name,
//                    currentScore: editingScore,
//                    onScoreChanged: { newScore in
//                        updateScore(playerID: player.playerID, round: editingRound, newScore: newScore)
//                    },
//                    isIPad: UIDevice.current.userInterfaceIdiom == .pad
//                )
//            }
//        }
//    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // Game name centered with truncation
            if let gameName = game.gameName, !gameName.isEmpty {
                Text(gameName)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            } else {
                // Fallback if no game name is provided
                Text("Game")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
            }
            
            // Game ID with copy functionality
            HStack {
                Spacer()
                Text("Game: \(String(game.id.prefix(8)))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                    .onLongPressGesture {
                        // Copy the short ID (the one shown)
                        UIPasteboard.general.string = String(game.id.prefix(8))
                        
                        // Show visual feedback
                        withAnimation(.easeInOut(duration: 0.2)) {
                            // You can add a temporary state here if needed
                        }
                        
                        // Haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                    }
                Spacer()
            }
            
            // Custom Rules Hint (only show if there are custom rules)
            if !customRules.isEmpty {
                VStack(spacing: 4) {
                    Text("Custom Rules:")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        ForEach(customRules, id: \.id) { rule in
                            HStack(spacing: 4) {
                                Text(rule.letter)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.3))
                                    .cornerRadius(4)
                                
                                Text("=")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text("\(rule.value)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.2))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
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
                            .background(Color.green)
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
                                Text("Complete Game")
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(6)
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
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(isDeleteMode ? .red : .white.opacity(0.7))
                    }
                }
                
                // Refresh button
                Button(action: {
                    Task {
                        await refreshGameData()
                    }
                }) {
                    Image(systemName: isRefreshing ? "arrow.clockwise.circle.fill" : "arrow.clockwise.circle")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isRefreshing ? .green : .white.opacity(0.7))
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
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
                        showGameSettings = true
                    }) {
                        Image(systemName: "gearshape.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.orange)
                    }
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
                    VStack(spacing: 0) {
                        headerRow
                        scoreRows
                        addRoundButton
                    }
                    .background(Color.black.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.green, lineWidth: 2)
                    )
                    .cornerRadius(4)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.6) // Limit height to 60% of screen
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
                .onChange(of: scrollToRound) { _, roundToScroll in
                    // Auto-scroll to the specified round when triggered
                    if let round = roundToScroll {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo("round-\(round)", anchor: .center)
                        }
                        // Clear the trigger after scrolling
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            scrollToRound = nil
                        }
                    }
                }
            }
            
            // Save and Undo buttons below the table
            if hasUnsavedChanges {
                HStack(spacing: 12) {
                    // Undo button
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
            // Round header (empty space for round numbers)
            VStack(spacing: 0) {
                Text("")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                
                Text("")
                    .frame(maxWidth: .infinity, minHeight: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray6))
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
                        Text(player.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity)
                        
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
            if canUserEditGame() && canUserEditScores() {
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
                                .foregroundColor(.white)
                            Text("Add Round")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 2)
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
            roundTextColor = Color.secondary
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
            .background(Color(.systemBackground))
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
                        // Make sure the hidden text field is ready to receive input
                        DispatchQueue.main.async {
                            guard canUserEditScores() else { return }
                            
                            // Auto-save current input if we're switching from another cell
                            if let currentEditingPlayer = editingPlayer, 
                               (currentEditingPlayer.playerID != player.playerID || editingRound != roundIndex + 1) {
                                let currentScore = parseScoreInput(scoreInputText) ?? 0
                                updateScore(playerID: currentEditingPlayer.playerID, round: editingRound, newScore: currentScore)
                                awaitSaveChangesSilently()
                            }
                            
                            editingPlayer = player
                            editingRound = roundIndex + 1
                            // Don't show -1 in the input field, show empty instead
                            scoreInputText = score == -1 ? "" : getDisplayText(for: score) ?? String(score)
                            isScoreFieldFocused = true
                        }
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
        let trimmedInput = input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if trimmedInput.isEmpty {
            return nil
        }
        
        // First check if it's a custom rule letter
        if let customRule = customRules.first(where: { $0.letter == trimmedInput }) {
            return customRule.value
        }
        
        // Otherwise try to parse as regular number
        return Int(trimmedInput)
    }
    
    // Check if a score has been explicitly entered for a player and round
    func hasScoreBeenEntered(for playerID: String, round: Int) -> Bool {
        let scoreKey = "\(playerID)-\(round)"
        
        // Check if this score has been explicitly entered by the user
        if enteredScores.contains(scoreKey) {
            return true
        }
        
        // Check if there's a saved score in the backend (this indicates a score was explicitly saved)
        if let savedScores = lastSavedScores[playerID], round <= savedScores.count {
            let scoreValue = savedScores[round - 1] // Convert to 0-based index
            return scoreValue != -1 // Only consider it entered if it's not -1 (empty)
        }
        
        return false
    }
    
    // Load game data efficiently
    func loadGameData(suppressCompletionCelebration: Bool = false) {
        print("🔍 DEBUG: ===== LOAD GAME DATA START =====")
        print("🔍 DEBUG: Game ID: \(game.id)")
        print("🔍 DEBUG: Game rounds: \(game.rounds)")
        print("🔍 DEBUG: Dynamic rounds: \(dynamicRounds)")
        print("🔍 DEBUG: Game playerIDs: \(game.playerIDs)")
        print("🔍 DEBUG: Current players before load: \(players.count)")
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
                
                // Fetch scores for this game only (server-side filtering)
                let scoresQuery = Score.keys.gameID.eq(game.id)
                let scoresResult = try await Amplify.API.query(request: .list(Score.self, where: scoresQuery))
                
                await MainActor.run {
                    switch scoresResult {
                    case .success(let gameScores):
                        print("🔍 DEBUG: Found \(gameScores.count) scores for this game")
                        
                        // Process player names and scores
                        var playerData: [String: (name: String, scores: [Int])] = [:]
                        
                        // Initialize scores for all players in the game
                        for playerID in game.playerIDs {
                            // Use the improved getPlayerName function that checks cache
                            let playerName = getPlayerName(for: playerID)
                            playerData[playerID] = (name: playerName, scores: Array(repeating: -1, count: dynamicRounds))
                        }
                        
                        // Fill in actual scores from database
                        print("🔍 DEBUG: Processing \(gameScores.count) scores from database")
                        for score in gameScores {
                            print("🔍 DEBUG: Score from DB - playerID: \(score.playerID), roundNumber: \(score.roundNumber), score: \(score.score)")
                            if let existingPlayerData = playerData[score.playerID],
                               score.roundNumber <= dynamicRounds {
                                var updatedScores = existingPlayerData.scores
                                let roundIndex = score.roundNumber - 1 // Convert 1-based round to 0-based index
                                print("🔍 DEBUG: Updating player \(score.playerID) round \(score.roundNumber) (index \(roundIndex)) to score \(score.score)")
                                updatedScores[roundIndex] = score.score
                                playerData[score.playerID] = (name: existingPlayerData.name, scores: updatedScores)
                            } else {
                                print("🔍 DEBUG: Skipping score - playerID: \(score.playerID), roundNumber: \(score.roundNumber), dynamicRounds: \(dynamicRounds)")
                            }
                        }
                        
                        // Merge with unsaved scores to preserve current state
                        for (playerID, unsavedPlayerScores) in unsavedScores {
                            if let existingPlayerData = playerData[playerID] {
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
                                
                                playerData[playerID] = (name: existingPlayerData.name, scores: mergedScores)
                                print("🔍 DEBUG: Merged scores for \(playerID): \(mergedScores)")
                            }
                        }
                        
                        // Convert to TestPlayer array
                        self.players = playerData.map { playerID, data in
                            // Ensure scores array matches dynamic rounds
                            var scores = data.scores
                            while scores.count < dynamicRounds {
                                scores.append(-1) // Add -1 for missing rounds (empty cells)
                            }
                            // Truncate if there are more scores than rounds
                            if scores.count > dynamicRounds {
                                scores = Array(scores.prefix(dynamicRounds))
                            }
                            
                            return TestPlayer(
                                name: data.name,
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
                        
                        // Check for game completion and winner (unless suppressed)
                        if !suppressCompletionCelebration {
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
                
                // Process all unsaved changes
                for (playerID, scores) in unsavedScores {
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
                                let _ = try await Amplify.API.mutate(request: .update(scoreObject))
                            } else {
                                let _ = try await Amplify.API.mutate(request: .create(scoreObject))
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
                    
                    // Process every player and every round based on the table values
                    for (playerID, scoresRow) in scoresForAllPlayers {
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
            scoreInputText = currentScore == -1 ? "" : String(currentScore)
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
        
        // Extract registered user IDs (those without ":" format)
        let registeredUserIDs = game.playerIDs.filter { !$0.contains(":") }
        
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
    
    func addRound() {
        guard canUserEditGame() else { return }
        
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
        guard canUserEditGame() && isGameComplete() else { 
            print("🔍 DEBUG: completeGame() - Guard failed, returning early")
            return 
        }
        
        // Update local state immediately for better UX
        var updated = game
        updated.gameStatus = .completed
        updated.updatedAt = Temporal.DateTime.now()
        
        // Update local game state immediately
        self.game = updated
        self.gameUpdateCounter += 1
        
        print("🔍 DEBUG: completeGame() - Local game status updated to: \(self.game.gameStatus)")
        
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
                        // Update with the saved version from backend to ensure consistency
                        self.game = saved
                        self.onGameUpdated?(saved)
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

}



struct Scoreboardview_Previews: PreviewProvider {
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
        Scoreboardview(game: .constant(sampleGame))
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

// MARK: - Balloon View
struct BalloonView: View {
    let color: Color
    @State private var isFloating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Balloon body
            Circle()
                .fill(color)
                .frame(width: 40, height: 50)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            
            // Balloon string
            Rectangle()
                .fill(Color.gray)
                .frame(width: 2, height: 30)
        }
        .offset(y: isFloating ? -10 : 0)
        .animation(
            .easeInOut(duration: 2)
            .repeatForever(autoreverses: true),
            value: isFloating
        )
        .onAppear {
            isFloating = true
        }
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces, id: \.id) { piece in
                ConfettiPieceView(piece: piece)
            }
        }
        .onAppear {
            generateConfetti()
        }
    }
    
    private func generateConfetti() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        confettiPieces = (0..<50).map { _ in
            ConfettiPiece(
                id: UUID(),
                color: colors.randomElement() ?? .blue,
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: 0...screenHeight)
                ),
                rotation: Double.random(in: 0...360),
                scale: Double.random(in: 0.5...1.5)
            )
        }
    }
}

struct ConfettiPiece {
    let id: UUID
    let color: Color
    let position: CGPoint
    let rotation: Double
    let scale: Double
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: 8, height: 8)
            .position(piece.position)
            .rotationEffect(.degrees(piece.rotation))
            .scaleEffect(piece.scale)
            .opacity(isAnimating ? 0 : 1)
            .animation(
                .easeOut(duration: 3)
                .delay(Double.random(in: 0...2)),
                value: isAnimating
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...1)) {
                    isAnimating = true
                }
            }
    }
}
