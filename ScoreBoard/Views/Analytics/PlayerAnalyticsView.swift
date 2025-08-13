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
    @State private var showingPerformanceInfo = false
    @State private var showingRecentGamesInfo = false
    @State private var showingAchievementsInfo = false
    @State private var showingStatInfo = false
    @State private var currentStatInfo = ""
    
    // Computed properties to break down complex expressions
    private var quickStatsData: [(String, String, Color, String)] {
        guard let stats = playerStats else { return [] }
        return [
            ("Games Played", "\(stats.totalGames)", .blue, AnalyticsHelpText.gamesPlayedInfo),
            ("Win Rate", "\(Int(stats.winRate * 100))%", .green, AnalyticsHelpText.winRateInfo),
            ("Avg Score", "\(stats.averageScore)", .orange, AnalyticsHelpText.avgScoreInfo),
            ("Best Score", "\(stats.bestScore)", .purple, AnalyticsHelpText.bestScoreInfo)
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
        NavigationStack {
            Group {
                if analyticsService.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading analytics...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                } else if let error = analyticsService.error {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Error loading analytics")
                            .font(.headline)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task {
                                playerStats = await analyticsService.loadUserAnalytics()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if let stats = playerStats {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header with player info using shared component
                            SharedPlayerHeaderView(
                                playerName: stats.playerName,
                                level: stats.level,
                                levelProgress: stats.levelProgress,
                                currentStreak: stats.currentStreak,
                                isSampleData: false,
                                onTap: { showingPlayerInfo = true }
                            )
                            
                            // Quick stats cards using shared component
                            SharedQuickStatsView(
                                stats: quickStatsData,
                                isSampleData: false,
                                onStatTap: { info in
                                    currentStatInfo = info
                                    showingStatInfo = true
                                },
                                onHeaderTap: { showingStatsInfo = true }
                            )
                            
                            // Win/Loss chart using shared component
                            SharedWinLossChartView(
                                wins: stats.winLossData.last?.wins ?? 0,
                                losses: stats.winLossData.last?.losses ?? 0,
                                timeframe: selectedTimeframe,
                                isSampleData: false,
                                onTap: { showingWinLossInfo = true }
                            )
                            
                            // Performance trends using shared component
                            SharedPerformanceTrendsView(
                                averageScore: Double(stats.averageScore),
                                bestScore: stats.bestScore,
                                timeframe: selectedTimeframe,
                                isSampleData: false,
                                onTap: { showingPerformanceInfo = true }
                            )
                            
                            // Recent games using shared component
                            SharedRecentGamesView(
                                recentGames: recentGamesData,
                                isSampleData: false,
                                onTap: { showingRecentGamesInfo = true }
                            )
                            
                            // Achievements using shared component
                            SharedAchievementsView(
                                achievements: achievementsData,
                                isSampleData: false,
                                onTap: { showingAchievementsInfo = true }
                            )
                        }
                        .padding()
                    }
                    .background(Color(.systemGroupedBackground))
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.bar.fill")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No analytics data available")
                            .font(.headline)
                        Text("Play some games to see your statistics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
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
            .alert("Performance Information", isPresented: $showingPerformanceInfo) {
                Button("OK") { }
            } message: {
                Text(AnalyticsHelpText.performanceInfo)
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
    let bestScore: Int
    let averageScore: Int
    let winLossData: [WinLossData]
    let performanceData: [PerformanceData]
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
        bestScore: Int = 1250,
        averageScore: Int = 850,
        winLossData: [WinLossData] = [
            WinLossData(date: Date().addingTimeInterval(-6*24*3600), wins: 3, losses: 1),
            WinLossData(date: Date().addingTimeInterval(-5*24*3600), wins: 2, losses: 2),
            WinLossData(date: Date().addingTimeInterval(-4*24*3600), wins: 4, losses: 0),
            WinLossData(date: Date().addingTimeInterval(-3*24*3600), wins: 1, losses: 3),
            WinLossData(date: Date().addingTimeInterval(-2*24*3600), wins: 3, losses: 1),
            WinLossData(date: Date().addingTimeInterval(-1*24*3600), wins: 2, losses: 2),
            WinLossData(date: Date(), wins: 4, losses: 1)
        ],
        performanceData: [PerformanceData] = [
            PerformanceData(date: Date().addingTimeInterval(-6*24*3600), score: 850),
            PerformanceData(date: Date().addingTimeInterval(-5*24*3600), score: 920),
            PerformanceData(date: Date().addingTimeInterval(-4*24*3600), score: 1100),
            PerformanceData(date: Date().addingTimeInterval(-3*24*3600), score: 780),
            PerformanceData(date: Date().addingTimeInterval(-2*24*3600), score: 950),
            PerformanceData(date: Date().addingTimeInterval(-1*24*3600), score: 890),
            PerformanceData(date: Date(), score: 1050)
        ],
        recentGames: [RecentGame] = [
            RecentGame(id: "1", gameName: "Card Game", score: 1250, isWin: true, date: Date()),
            RecentGame(id: "2", gameName: "Board Game", score: 780, isWin: false, date: Date().addingTimeInterval(-24*3600)),
            RecentGame(id: "3", gameName: "Strategy Game", score: 1100, isWin: true, date: Date().addingTimeInterval(-2*24*3600)),
            RecentGame(id: "4", gameName: "Puzzle Game", score: 920, isWin: true, date: Date().addingTimeInterval(-3*24*3600)),
            RecentGame(id: "5", gameName: "Word Game", score: 650, isWin: false, date: Date().addingTimeInterval(-4*24*3600))
        ],
        achievements: [Achievement] = [
            Achievement(id: "1", title: "First Win", description: "Win your first game", icon: "trophy.fill", color: .yellow, isUnlocked: true),
            Achievement(id: "2", title: "Streak Master", description: "Win 5 games in a row", icon: "flame.fill", color: .orange, isUnlocked: true),
            Achievement(id: "3", title: "High Scorer", description: "Score 1000+ points", icon: "star.fill", color: .yellow, isUnlocked: true),
            Achievement(id: "4", title: "Regular Player", description: "Play 50 games", icon: "gamecontroller.fill", color: .blue, isUnlocked: false),
            Achievement(id: "5", title: "Perfect Game", description: "Win with max score", icon: "crown.fill", color: .purple, isUnlocked: false),
            Achievement(id: "6", title: "Social Butterfly", description: "Play with 10+ players", icon: "person.3.fill", color: .green, isUnlocked: false)
        ]
    ) {
        self.playerName = playerName
        self.level = level
        self.levelProgress = levelProgress
        self.currentStreak = currentStreak
        self.totalGames = totalGames
        self.winRate = winRate
        self.bestScore = bestScore
        self.averageScore = averageScore
        self.winLossData = winLossData
        self.performanceData = performanceData
        self.recentGames = recentGames
        self.achievements = achievements
    }
}

struct WinLossData {
    let date: Date
    let wins: Int
    let losses: Int
}

struct PerformanceData {
    let date: Date
    let score: Int
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

// MARK: - Real Data Factory for PlayerStats
extension PlayerStats {
    static func from(games: [Game], scores: [Score], userId: String) -> PlayerStats {
        guard !games.isEmpty, !scores.isEmpty else {
            return PlayerStats() // fallback to dummy
        }

        // 1. Total games played
        let totalGames = games.count

        // 2. Win/loss calculation
        var wins = 0
        var losses = 0
        var winLossData: [WinLossData] = []
        var performanceData: [PerformanceData] = []
        var recentGames: [RecentGame] = []

        // Group scores by game
        let scoresByGame = Dictionary(grouping: scores, by: { $0.gameID })

        for game in games {
            let gameScores = scoresByGame[game.id] ?? []
            guard let myScore = gameScores.first(where: { $0.playerID == userId }) else { continue }
            let maxScore = gameScores.map { $0.score }.max() ?? 0
            let isWin = myScore.score == maxScore && maxScore > 0
            if isWin {
                wins += 1
            } else {
                losses += 1
            }
            // Use game.createdAt for all analytics dates
            let date = game.createdAt.foundationDate ?? Date()
            winLossData.append(WinLossData(date: date, wins: isWin ? 1 : 0, losses: isWin ? 0 : 1))
            performanceData.append(PerformanceData(date: date, score: myScore.score))
            recentGames.append(RecentGame(
                id: game.id,
                gameName: "Game vs \(game.playerIDs.compactMap { $0 }.filter { $0 != userId }.joined(separator: ", ") ?? "Unknown Players")",
                score: myScore.score,
                isWin: isWin,
                date: date
            ))
        }

        // 3. Streak calculation (by day)
        let playedDates = Set(games.map { ($0.createdAt.foundationDate ?? Date()).startOfDay })
        let streak = calculateStreak(dates: playedDates)

        // 4. Best/Average score
        let bestScore = scores.map { $0.score }.max() ?? 0
        let averageScore = scores.isEmpty ? 0 : scores.map { $0.score }.reduce(0, +) / scores.count

        // 5. Win rate
        let winRate = totalGames > 0 ? Double(wins) / Double(totalGames) : 0

        // 6. Achievements (simple example)
        let achievements: [Achievement] = [
            Achievement(id: "1", title: "First Win", description: "Win your first game", icon: "trophy.fill", color: .yellow, isUnlocked: wins > 0),
            Achievement(id: "2", title: "Streak Master", description: "Win 5 games in a row", icon: "flame.fill", color: .orange, isUnlocked: streak >= 5),
            Achievement(id: "3", title: "High Scorer", description: "Score 1000+ points", icon: "star.fill", color: .yellow, isUnlocked: bestScore >= 1000),
            Achievement(id: "4", title: "Regular Player", description: "Play 50 games", icon: "gamecontroller.fill", color: .blue, isUnlocked: totalGames >= 50),
            Achievement(id: "5", title: "Perfect Game", description: "Win with max score", icon: "crown.fill", color: .purple, isUnlocked: scores.contains { $0.score == 1500 }),
            Achievement(id: "6", title: "Social Butterfly", description: "Play with 10+ players", icon: "person.3.fill", color: .green, isUnlocked: Set(games.flatMap { $0.playerIDs.compactMap { $0 } ?? [] }).count >= 10)
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
            bestScore: bestScore,
            averageScore: averageScore,
            winLossData: winLossData,
            performanceData: performanceData,
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
