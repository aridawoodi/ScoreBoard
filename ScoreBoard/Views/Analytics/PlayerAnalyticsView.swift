//
//  PlayerAnalyticsView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/5/24.
//

import Foundation
import SwiftUI
import Charts
import Amplify

struct PlayerAnalyticsView: View {
    @State private var selectedTimeframe: AnalyticsTimeframe = .week
    @State private var playerStats: PlayerStats?
    @StateObject private var analyticsService = AnalyticsService.shared
    
    // Help alert states
    @State private var showingPlayerInfo = false
    @State private var showingStatsInfo = false
    @State private var showingWinLossInfo = false

    @State private var showingRecentGamesInfo = false
    @State private var showingAchievementsInfo = false
    @State private var showingStatInfo = false
    @State private var currentStatInfo = ""
    
    // Computed properties to break down complex expressions
    private var quickStatsData: [(String, String, Color, String)] {
        guard let stats = playerStats else { return [] }
        return [
            ("Games Played", "\(stats.totalGames)", .blue, AnalyticsHelpText.gamesPlayedInfo),
            ("Win Rate", "\(Int(stats.winRate * 100))%", .green, AnalyticsHelpText.winRateInfo)
        ]
    }
    
    private var recentGamesData: [(String, Int, String, String)] {
        guard let stats = playerStats else { return [] }
        return stats.recentGames.prefix(3).map { game in
            (game.gameName, game.score, game.isWin ? "Won" : "Lost", formatDate(game.date))
        }
    }
    
    private var achievementsData: [(String, String, String, Color, Bool)] {
        guard let stats = playerStats else { return [] }
        return stats.achievements.map { achievement in
            (achievement.title, achievement.description, achievement.icon, achievement.color, achievement.isUnlocked)
        }
    }
    
    var body: some View {
        Group {
            if analyticsService.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading analytics...")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                }
            } else if let error = analyticsService.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Error loading analytics")
                        .font(.headline)
                    .foregroundColor(.white)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task {
                            playerStats = await analyticsService.loadUserAnalytics()
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(8)
                }
                .padding()
            } else if playerStats == nil && !analyticsService.isLoading {
                // Show sample analytics when user has no data
                SampleAnalyticsView()
            } else if let stats = playerStats {
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        SharedPlayerHeaderView(
                            playerName: stats.playerName,
                            level: stats.level,
                            levelProgress: stats.levelProgress,
                            currentStreak: stats.currentStreak,
                            isSampleData: false,
                            onTap: { showingPlayerInfo = true }
                        )
                        
                        // Quick stats
                        SharedQuickStatsView(
                            stats: quickStatsData,
                            isSampleData: false,
                            onStatTap: { info in
                                currentStatInfo = info
                                showingStatInfo = true
                            },
                            onHeaderTap: { showingStatsInfo = true }
                        )
                        
                        // Win/Loss chart
                        SharedWinLossChartView(
                            wins: stats.winLossData.last?.wins ?? 0,
                            losses: stats.winLossData.last?.losses ?? 0,
                            timeframe: selectedTimeframe,
                            isSampleData: false,
                            onTap: { showingWinLossInfo = true }
                        )
                        
                        // Win Condition Breakdown
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Win Condition Breakdown")
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 16) {
                                // Highest Score Wins
                                VStack(spacing: 4) {
                                    HStack {
                                        Image(systemName: "arrow.up.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Highest Score Wins")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    Text("\(stats.highestScoreWins)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.green)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                                
                                // Lowest Score Wins
                                VStack(spacing: 4) {
                                    HStack {
                                        Image(systemName: "arrow.down.circle.fill")
                                            .foregroundColor(.blue)
                                        Text("Lowest Score Wins")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    Text("\(stats.lowestScoreWins)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(8)
                            }
                        }
                        

                        
                        // Recent games
                        SharedRecentGamesView(
                            recentGames: recentGamesData,
                            isSampleData: false,
                            onTap: { showingRecentGamesInfo = true }
                        )
                        
                        // Achievements
                        SharedAchievementsView(
                            achievements: achievementsData,
                            isSampleData: false,
                            onTap: { showingAchievementsInfo = true }
                        )
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white.opacity(0.7))
                    Text("No analytics data available")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Play some games to see your statistics")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .toolbar {
            if playerStats != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AnalyticsTimeframeSegmentedPicker(selection: $selectedTimeframe)
                }
            }
        }
        .alert("Player Information", isPresented: $showingPlayerInfo) {
            Button("OK") { }
        } message: {
            Text(AnalyticsHelpText.playerInfo)
        }
        .alert("Quick Stats Information", isPresented: $showingStatsInfo) {
            Button("OK") { }
        } message: {
            Text(AnalyticsHelpText.quickStatsInfo)
        }
        .alert("Win/Loss Information", isPresented: $showingWinLossInfo) {
            Button("OK") { }
        } message: {
            Text(AnalyticsHelpText.winLossInfo)
        }

        .alert("Recent Games Information", isPresented: $showingRecentGamesInfo) {
            Button("OK") { }
        } message: {
            Text(AnalyticsHelpText.recentGamesInfo)
        }
        .alert("Achievements Information", isPresented: $showingAchievementsInfo) {
            Button("OK") { }
        } message: {
            Text(AnalyticsHelpText.achievementsInfo)
        }
        .alert("Stat Information", isPresented: $showingStatInfo) {
            Button("OK") { }
        } message: {
            Text(currentStatInfo)
        }
        .onAppear {
            Task {
                playerStats = await analyticsService.loadUserAnalytics()
            }
        }
    }
    
    // Helper function for date formatting
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
}
    
    // MARK: - Data Models
    struct PlayerStats {
        let playerName: String
        let level: Int
        let levelProgress: Double
        let currentStreak: Int
        let totalGames: Int
        let winRate: Double
        let highestScoreWins: Int
        let lowestScoreWins: Int
        let winLossData: [WinLossData]
        let recentGames: [RecentGame]
        let achievements: [Achievement]
        
        // Dummy initializer
        init(
            playerName: String = "Player",
            level: Int = 5,
            levelProgress: Double = 0.75,
            currentStreak: Int = 7,
            totalGames: Int = 42,
            winRate: Double = 0.68,
            highestScoreWins: Int = 25,
            lowestScoreWins: Int = 17,
            winLossData: [WinLossData] = [
                WinLossData(date: Date().addingTimeInterval(-6*24*3600), wins: 3, losses: 1),
                WinLossData(date: Date().addingTimeInterval(-5*24*3600), wins: 2, losses: 2),
                WinLossData(date: Date().addingTimeInterval(-4*24*3600), wins: 4, losses: 0),
                WinLossData(date: Date().addingTimeInterval(-3*24*3600), wins: 1, losses: 3),
                WinLossData(date: Date().addingTimeInterval(-2*24*3600), wins: 3, losses: 1),
                WinLossData(date: Date().addingTimeInterval(-1*24*3600), wins: 2, losses: 2),
                WinLossData(date: Date(), wins: 4, losses: 1)
            ],

            recentGames: [RecentGame] = [
                RecentGame(id: "1", gameName: "Card Game (Highest Wins)", score: 1250, isWin: true, date: Date()),
                RecentGame(id: "2", gameName: "Board Game (Lowest Wins)", score: 780, isWin: true, date: Date().addingTimeInterval(-24*3600)),
                RecentGame(id: "3", gameName: "Strategy Game (Highest Wins)", score: 1100, isWin: true, date: Date().addingTimeInterval(-2*24*3600)),
                RecentGame(id: "4", gameName: "Puzzle Game (Lowest Wins)", score: 920, isWin: false, date: Date().addingTimeInterval(-3*24*3600)),
                RecentGame(id: "5", gameName: "Word Game (Highest Wins)", score: 650, isWin: false, date: Date().addingTimeInterval(-4*24*3600))
            ],
            achievements: [Achievement] = [
                Achievement(id: "1", title: "First Win", description: "Win your first game", icon: "trophy.fill", color: .yellow, isUnlocked: true),
                Achievement(id: "2", title: "Streak Master", description: "Win 5 games in a row", icon: "flame.fill", color: .orange, isUnlocked: true),
                Achievement(id: "3", title: "High Scorer", description: "Score 1000+ points in any game", icon: "star.fill", color: .yellow, isUnlocked: true),
                Achievement(id: "4", title: "Regular Player", description: "Play 50 games", icon: "gamecontroller.fill", color: .blue, isUnlocked: false),
                Achievement(id: "5", title: "Highest Score Master", description: "Win 10 highest-score games", icon: "arrow.up.circle.fill", color: .green, isUnlocked: true),
                Achievement(id: "6", title: "Lowest Score Master", description: "Win 10 lowest-score games", icon: "arrow.down.circle.fill", color: .blue, isUnlocked: true),
                Achievement(id: "7", title: "Versatile Player", description: "Win both highest and lowest score games", icon: "arrow.up.arrow.down.circle.fill", color: .purple, isUnlocked: true),
                Achievement(id: "8", title: "Social Butterfly", description: "Play with 10+ different players", icon: "person.3.fill", color: .orange, isUnlocked: false)
            ]
        ) {
            self.playerName = playerName
            self.level = level
            self.levelProgress = levelProgress
            self.currentStreak = currentStreak
            self.totalGames = totalGames
            self.winRate = winRate
            self.highestScoreWins = highestScoreWins
            self.lowestScoreWins = lowestScoreWins
            self.winLossData = winLossData
            self.recentGames = recentGames
            self.achievements = achievements
                 }
     }
     
     // MARK: - Real Data Factory for PlayerStats
     extension PlayerStats {
         static func from(games: [Game], scores: [Score], userId: String) -> PlayerStats? {
             guard !games.isEmpty, !scores.isEmpty else {
                 return nil // Return nil instead of dummy data
             }
             
             print("🔍 DEBUG: PlayerStats.from - Processing \(games.count) games and \(scores.count) scores for user \(userId)")
             print("🔍 DEBUG: Scores details: \(scores.map { "Player: \($0.playerID), Score: \($0.score), Round: \($0.roundNumber)" })")

             // 1. Total games played
             let totalGames = games.count

             // 2. Win/loss calculation with proper win condition handling
             var wins = 0
             var losses = 0
             var highestScoreWins = 0
             var lowestScoreWins = 0
             var winLossData: [WinLossData] = []
             var recentGames: [RecentGame] = []

             // Group scores by game
             let scoresByGame = Dictionary(grouping: scores, by: { $0.gameID })

             for game in games {
                 let gameScores = scoresByGame[game.id] ?? []
                 guard let myScore = gameScores.first(where: { $0.playerID == userId }) else { continue }
                 
                 // Determine winner based on game's win condition
                 let isWin: Bool
                 let winCondition = game.winCondition ?? .highestScore
                 
                 switch winCondition {
                 case .highestScore:
                     let maxScore = gameScores.map { $0.score }.max() ?? 0
                     isWin = myScore.score == maxScore && maxScore > 0
                 case .lowestScore:
                     let minScore = gameScores.map { $0.score }.min() ?? 0
                     isWin = myScore.score == minScore && minScore > 0
                 }
                 
                 if isWin {
                     wins += 1
                     // Track wins by win condition type
                     switch winCondition {
                     case .highestScore:
                         highestScoreWins += 1
                     case .lowestScore:
                         lowestScoreWins += 1
                     }
                 } else {
                     losses += 1
                 }
                 
                 // Use game.createdAt for all analytics dates
                 let date = game.createdAt.foundationDate ?? Date()
                 winLossData.append(WinLossData(date: date, wins: isWin ? 1 : 0, losses: isWin ? 0 : 1))
                 
                 // Create more descriptive game name with win condition
                 let otherPlayers = game.playerIDs.compactMap { $0 }.filter { $0 != userId }
                 let gameName: String
                 if otherPlayers.isEmpty {
                     gameName = "Solo Game"
                 } else {
                     let winConditionText = winCondition == .lowestScore ? "Lowest Wins" : "Highest Wins"
                     gameName = "Game vs \(otherPlayers.joined(separator: ", ")) (\(winConditionText))"
                 }
                 
                 recentGames.append(RecentGame(
                     id: game.id,
                     gameName: gameName,
                     score: myScore.score,
                     isWin: isWin,
                     date: date
                 ))
             }

             // 3. Streak calculation (by day)
             let playedDates = Set(games.map { ($0.createdAt.foundationDate ?? Date()).startOfDay })
             let streak = calculateStreak(dates: playedDates)



             // 5. Win rate
             let winRate = totalGames > 0 ? Double(wins) / Double(totalGames) : 0

             // 6. Achievements with win condition awareness
             let achievements: [Achievement] = [
                 Achievement(id: "1", title: "First Win", description: "Win your first game", icon: "trophy.fill", color: .yellow, isUnlocked: wins > 0),
                 Achievement(id: "2", title: "Streak Master", description: "Win 5 games in a row", icon: "flame.fill", color: .orange, isUnlocked: streak >= 5),

                 Achievement(id: "3", title: "Regular Player", description: "Play 50 games", icon: "gamecontroller.fill", color: .blue, isUnlocked: totalGames >= 50),
                 Achievement(id: "4", title: "Highest Score Master", description: "Win 10 highest-score games", icon: "arrow.up.circle.fill", color: .green, isUnlocked: highestScoreWins >= 10),
                 Achievement(id: "5", title: "Lowest Score Master", description: "Win 10 lowest-score games", icon: "arrow.down.circle.fill", color: .blue, isUnlocked: lowestScoreWins >= 10),
                 Achievement(id: "6", title: "Versatile Player", description: "Win both highest and lowest score games", icon: "arrow.up.arrow.down.circle.fill", color: .purple, isUnlocked: highestScoreWins > 0 && lowestScoreWins > 0),
                 Achievement(id: "7", title: "Social Butterfly", description: "Play with 10+ different players", icon: "person.3.fill", color: .orange, isUnlocked: Set(games.flatMap { $0.playerIDs.compactMap { $0 } ?? [] }).count >= 10)
             ]

             // 7. Level/Progress (simple: 1 level per 10 games)
             let level = 1 + totalGames / 10
             let levelProgress = Double(totalGames % 10) / 10.0

             return PlayerStats(
                 playerName: "You",
                 level: level,
                 levelProgress: levelProgress,
                 currentStreak: streak,
                 totalGames: totalGames,
                 winRate: winRate,
                 highestScoreWins: highestScoreWins,
                 lowestScoreWins: lowestScoreWins,
                 winLossData: winLossData,
                 recentGames: recentGames.sorted { $0.date > $1.date },
                 achievements: achievements
             )
         }
     }
     
     // MARK: - Helper Functions
     private func calculateStreak(dates: Set<Date>) -> Int {
         let sortedDates = dates.sorted()
         var currentStreak = 0
         var maxStreak = 0
         
         for date in sortedDates {
             let dayStart = date.startOfDay
             let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: dayStart) ?? dayStart
             
             if currentStreak == 0 || Calendar.current.isDate(dayStart, inSameDayAs: previousDay) {
                 currentStreak += 1
             } else {
                 currentStreak = 1
             }
             
             maxStreak = max(maxStreak, currentStreak)
         }
         
         return maxStreak
     }
     
     private extension Date {
         var startOfDay: Date {
             Calendar.current.startOfDay(for: self)
         }
     }
     
     struct WinLossData {
        let date: Date
        let wins: Int
        let losses: Int
    }
    
    struct RecentGame {
        let id: String
        let gameName: String
        let score: Int
        let isWin: Bool
        let date: Date
    }
    
    struct Achievement {
        let id: String
        let title: String
        let description: String
        let icon: String
        let color: Color
        let isUnlocked: Bool
    }
