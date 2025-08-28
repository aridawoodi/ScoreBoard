//
//  PlayerDetailView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI

struct PlayerDetailView: View {
    let player: PlayerLeaderboardEntry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Player Header
                    VStack(spacing: 12) {
                        Text(player.nickname)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        // Overall Stats
                        HStack(spacing: 20) {
                            PlayerDetailStatCard(title: "Total Wins", value: "\(player.totalWins)", color: .green)
                            PlayerDetailStatCard(title: "Total Games", value: "\(player.totalGames)", color: .blue)
                            PlayerDetailStatCard(title: "Win Rate", value: "\(Int(player.winRate * 100))%", color: .orange)
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                    
                    // Performance Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Performance Breakdown")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 16) {
                            BreakdownCard(
                                title: "Highest Score Wins",
                                value: "\(player.highestScoreWins)",
                                icon: "arrow.up.circle.fill",
                                color: .green
                            )
                            
                            BreakdownCard(
                                title: "Lowest Score Wins",
                                value: "\(player.lowestScoreWins)",
                                icon: "arrow.down.circle.fill",
                                color: .blue
                            )
                            
                            BreakdownCard(
                                title: "Average Score",
                                value: "\(Int(player.averageScore))",
                                icon: "chart.bar.fill",
                                color: .orange
                            )
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                    
                    // Games Won
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Games Won")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if player.gamesWon.isEmpty {
                            Text("No games won yet")
                                .foregroundColor(.white.opacity(0.7))
                                .italic()
                        } else {
                            LazyVStack(spacing: 8) {
                                ForEach(player.gamesWon) { game in
                                    GameWonCard(game: game)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Player Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
                .foregroundColor(.white)
            )
            .gradientBackground()
        }
    }
}

// MARK: - Player Detail Stat Card
struct PlayerDetailStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - Breakdown Card
struct BreakdownCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
}

// MARK: - Game Won Card
struct GameWonCard: View {
    let game: GameWinDetail
    
    private var winConditionIcon: String {
        switch game.winCondition {
        case .highestScore: return "🏆"
        case .lowestScore: return "🎯"
        }
    }
    
    private var winConditionText: String {
        switch game.winCondition {
        case .highestScore: return "Highest Score"
        case .lowestScore: return "Lowest Score"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Win Condition Icon
            Text(winConditionIcon)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(game.gameName.isEmpty ? "Untitled Game" : game.gameName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(winConditionText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Score: \(game.finalScore)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("\(game.totalPlayers) players")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(8)
    }
}

#Preview {
    let samplePlayer = PlayerLeaderboardEntry(
        nickname: "John Doe",
        playerID: "123",
        totalWins: 15,
        totalGames: 20,
        winRate: 0.75,
        highestScoreWins: 10,
        lowestScoreWins: 5,
        averageScore: 132.5,
        gamesWon: [
            GameWinDetail(
                gameID: "1",
                gameName: "Poker Night",
                winCondition: .highestScore,
                finalScore: 150,
                date: Date(),
                totalPlayers: 4
            ),
            GameWinDetail(
                gameID: "2",
                gameName: "Family Game",
                winCondition: .lowestScore,
                finalScore: 45,
                date: Date(),
                totalPlayers: 3
            )
        ]
    )
    
    PlayerDetailView(player: samplePlayer)
}
