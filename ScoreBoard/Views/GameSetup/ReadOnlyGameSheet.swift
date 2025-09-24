//
//  ReadOnlyGameSheet.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 12/14/24.
//

import SwiftUI
import Amplify

struct ReadOnlyGameSheet: View {
    let game: Game
    let onBack: () -> Void
    
    @State private var players: [TestPlayer] = []
    @State private var dynamicRounds: Int = 0
    @State private var showGameInfoSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // MARK: - Dynamic Background (matching ScoreboardView)
                GradientBackgroundView()
                
                VStack(spacing: 20) {
                    // MARK: - Header (matching GameSelectionView style)
                    VStack(spacing: 8) {
                        HStack {
                            Button(action: { showGameInfoSheet = true }) {
                                Image(systemName: "info.circle")
                                    .font(.body)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            Button("Cancel") {
                                onBack()
                            }
                            .foregroundColor(.white)
                            .font(.body)
                        }
                        .padding(.horizontal)
                        
                        Text("Game Details")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                        
                        // Game title and status
                        VStack(spacing: 4) {
                            Text(game.gameName ?? "Untitled Game")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text(game.gameStatus.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.top, 20)
                
                // MARK: - Winner Display (enhanced style)
                if let winnerName = getWinnerName() {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.title3)
                        Text("Winner: \(winnerName)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.8))
                    )
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                
                // MARK: - Score Table (matching ScoreboardView style)
                if !players.isEmpty {
                    // Excel-like table container with scroll (matching ScoreboardView)
                    ScrollViewReader { proxy in
                        ScrollView {
                            ZStack {
                                // Table content (background)
                                VStack(spacing: 0) {
                                    headerRow
                                    scoreRows
                                }
                                .background(Color.black.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                
                                // Static dark green border (matching ScoreboardView)
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        Color(hex: "4A7C59"),
                                        lineWidth: 4
                                    )
                                    .allowsHitTesting(false) // Allow touches to pass through
                            }
                            .padding(0) // Remove any default padding
                        }
                        .frame(maxHeight: UIScreen.main.bounds.height * 0.55) // Match ScoreboardView height
                        .padding(.horizontal, 16) // Add horizontal padding to show green borders
                    }
                } else {
                    Spacer()
                    Text("Loading game data...")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.body)
                    Spacer()
                }
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showGameInfoSheet) {
            ReadOnlyGameInfoSheet(game: game)
        }
        .onAppear {
            loadGameData()
        }
    }
    
    // MARK: - Header Row Component (matching ScoreboardView)
    private var headerRow: some View {
        HStack(spacing: 0) {
            // Round header with info indicator (matching ScoreboardView)
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
            .frame(width: 25) // Reduce width for better fit
            .background(Color.black.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            
            // Player columns (matching ScoreboardView)
            ForEach(Array(players.enumerated()), id: \.offset) { index, player in
                VStack(spacing: 0) {
                    HStack {
                        // Player name (read-only, no edit functionality)
                        HStack(spacing: 4) {
                            Text(player.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(maxWidth: .infinity)
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
    
    // MARK: - Score Rows Component (matching ScoreboardView)
    private var scoreRows: some View {
        VStack(spacing: 0) {
            ForEach(0..<dynamicRounds, id: \.self) { roundIndex in
                scoreRow(for: roundIndex)
            }
        }
    }
    
    // MARK: - Individual Score Row (matching ScoreboardView)
    private func scoreRow(for roundIndex: Int) -> some View {
        let roundTextColor: Color = Color.white
        let roundBorderColor: Color = Color.gray.opacity(0.3)
        let roundBorderWidth: CGFloat = 0.5
        let backgroundFillColor: Color = Color.clear
        let overlayStrokeColor: Color = Color.gray.opacity(0.2)
        let overlayStrokeWidth: CGFloat = 0.5
        let scaleEffect: CGFloat = 1.0
        
        return HStack(spacing: 0) {
            // Round number column (matching ScoreboardView)
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: {
                        // No action needed for read-only
                    }) {
                        Text("")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                    }
                    .disabled(true) // Disable interaction
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 4)
                .padding(.top, 8)
                .padding(.bottom, 4)
                
                Text("\(roundIndex + 1)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(roundTextColor)
                    .frame(maxWidth: .infinity, minHeight: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(roundBorderColor, lineWidth: roundBorderWidth)
                    )
            }
            .frame(width: 25) // Reduce width for better fit
            .background(Color.black.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            
            // Player score columns (matching ScoreboardView)
            ForEach(players.indices, id: \.self) { colIndex in
                let player = players[colIndex]
                let score = roundIndex < player.scores.count ? player.scores[roundIndex] : -1
                
                ReadOnlyScoreCell(
                    player: player,
                    roundIndex: roundIndex,
                    currentScore: score,
                    backgroundColor: columnColor(colIndex),
                    displayText: getDisplayText(for: score)
                )
            }
        }
        .id("round-\(roundIndex + 1)") // Add ID for scrolling (matching ScoreboardView)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundFillColor)
        )
        .scaleEffect(scaleEffect)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(overlayStrokeColor, lineWidth: overlayStrokeWidth)
        )
    }
    
    private func loadGameData() {
        // Get scores for this game
        let gameScores = DataManager.shared.getScoresForGame(game.id)
        
        // Group scores by player ID
        let scoresByPlayer = Dictionary(grouping: gameScores) { $0.playerID }
        
        // Create TestPlayer objects
        var loadedPlayers: [TestPlayer] = []
        
        for playerID in game.playerIDs {
            let playerScores = scoresByPlayer[playerID]?.map { $0.score } ?? []
            let playerName = DataManager.shared.getPlayerName(playerID)
            
            let player = TestPlayer(
                name: playerName,
                scores: playerScores,
                playerID: playerID
            )
            loadedPlayers.append(player)
        }
        
        // Calculate dynamic rounds
        let maxPlayerRounds = loadedPlayers.map { $0.scores.count }.max() ?? 0
        let gameMaxRounds = game.maxRounds ?? 8
        dynamicRounds = max(maxPlayerRounds, gameMaxRounds)
        
        players = loadedPlayers
    }
    
    private func getScoreForPlayer(_ player: TestPlayer, round: Int) -> String {
        if round <= player.scores.count {
            return "\(player.scores[round - 1])"
        }
        return "-"
    }
    
    private func getWinnerName() -> String? {
        // Find the player with the highest/lowest total score based on win condition
        guard !players.isEmpty else { return nil }
        
        let winner = players.max(by: { player1, player2 in
            switch game.winCondition {
            case .highestScore:
                return player1.total < player2.total
            case .lowestScore:
                return player1.total > player2.total
            case .none:
                return player1.total < player2.total // Default to highest
            }
        })
        return winner?.name
    }
    
    
    // MARK: - Helper Functions (matching ScoreboardView)
    
    // Column color matching ScoreboardView style with better dark mode support
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
    
    // Convert score to display text using custom rules (matching ScoreboardView)
    func getDisplayText(for score: Int) -> String? {
        if score == -1 {
            return nil // Empty cell
        }
        
        // For read-only view, we'll just return the score as string
        // In a full implementation, you might want to check for custom rules
        return String(score)
    }
}

// MARK: - ReadOnlyScoreCell Component (matching ScoreboardView ScoreCell)
struct ReadOnlyScoreCell: View {
    let player: TestPlayer
    let roundIndex: Int
    let currentScore: Int
    let backgroundColor: Color
    let displayText: String?
    
    var body: some View {
        // Read-only version of ScoreCell (no button, no interactions)
        HStack {
            Text(displayText ?? (currentScore != -1 ? "\(currentScore)" : ""))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
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
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
    }
    
    // Cell background color (matching ScoreboardView logic)
    private var cellBackgroundColor: Color {
        if currentScore == -1 {
            return Color.black.opacity(0.1)
        } else {
            return backgroundColor.opacity(0.3)
        }
    }
    
    // Cell border color (matching ScoreboardView)
    private var cellBorderColor: Color {
        return Color.white.opacity(0.2)
    }
    
    // Cell border width (matching ScoreboardView)
    private var cellBorderWidth: CGFloat {
        return 0.5
    }
    
    // Shadow properties (matching ScoreboardView)
    private var shadowColor: Color {
        return Color.white.opacity(0.05)
    }
    
    private var shadowRadius: CGFloat {
        return 2.0
    }
    
    private var shadowOffset: CGFloat {
        return 1.0
    }
}

// MARK: - ReadOnlyGameInfoSheet (using existing GameInfoSheet from Scoreboardview.swift)
struct ReadOnlyGameInfoSheet: View {
    let game: Game
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    InfoSection(title: "Game Details", icon: "gamecontroller.fill") {
                        InfoRow(title: "Name", value: game.gameName ?? "Untitled Game")
                        InfoRow(title: "Status", value: game.gameStatus.rawValue.capitalized)
                        InfoRow(title: "Created", value: formatDate(game.createdAt.foundationDate ?? Date()))
                        InfoRow(title: "Last Updated", value: formatDate(game.updatedAt.foundationDate ?? Date()))
                    }
                    
                    InfoSection(title: "Game Settings", icon: "gearshape.fill") {
                        InfoRow(title: "Rounds", value: "\(game.rounds)")
                        InfoRow(title: "Win Condition", value: winConditionText)
                        InfoRow(title: "Players", value: "\(game.playerIDs.count)")
                    }
                    
                    InfoSection(title: "Players", icon: "person.3.fill") {
                        ForEach(game.playerIDs, id: \.self) { playerID in
                            InfoRow(title: "Player", value: DataManager.shared.getPlayerName(playerID))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Game Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var winConditionText: String {
        switch game.winCondition {
        case .lowestScore:
            return "Lowest Score Wins"
        case .highestScore:
            return "Highest Score Wins"
        case .none:
            return "Highest Score Wins" // Default
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    // Create a sample game for preview
    let sampleGame = Game(
        id: "sample-id",
        gameName: "Sample Game",
        hostUserID: "host-id",
        playerIDs: ["Player 1", "Player 2"],
        rounds: 5, gameStatus: .completed,
        winCondition: .highestScore,
        createdAt: Temporal.DateTime.now(),
        updatedAt: Temporal.DateTime.now()
    )
    
    ReadOnlyGameSheet(game: sampleGame) {
        // Preview back action
    }
}
