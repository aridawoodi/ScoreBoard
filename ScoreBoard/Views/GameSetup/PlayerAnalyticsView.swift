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
    @State private var selectedTimeframe: Timeframe = .week
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
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
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
                            // Header with player info
                            PlayerHeaderView(stats: stats, showingPlayerInfo: $showingPlayerInfo)
                            
                            // Quick stats cards
                            QuickStatsView(
                                stats: stats,
                                showingStatsInfo: $showingStatsInfo,
                                showingStatInfo: $showingStatInfo,
                                currentStatInfo: $currentStatInfo
                            )
                            
                            // Win/Loss chart
                            WinLossChartView(stats: stats, timeframe: selectedTimeframe, showingWinLossInfo: $showingWinLossInfo)
                            
                            // Performance trends
                            PerformanceTrendsView(stats: stats, timeframe: selectedTimeframe, showingPerformanceInfo: $showingPerformanceInfo)
                            
                            // Recent games
                            RecentGamesView(stats: stats, showingRecentGamesInfo: $showingRecentGamesInfo)
                            
                            // Achievements
                            AchievementsView(stats: stats, showingAchievementsInfo: $showingAchievementsInfo)
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
                        Picker("Timeframe", selection: $selectedTimeframe) {
                            ForEach(Timeframe.allCases, id: \.self) { timeframe in
                                Text(timeframe.rawValue).tag(timeframe)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
            }
        }
        .onAppear {
            Task {
                playerStats = await analyticsService.loadUserAnalytics()
            }
        }
        // Help alerts
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
}

// MARK: - Player Header
struct PlayerHeaderView: View {
    let stats: PlayerStats
    
    @Binding var showingPlayerInfo: Bool
    
    @State private var isPressed = false
    @State private var animatePulse = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Player avatar and name
            HStack(spacing: 16) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(String(stats.playerName.prefix(1)).uppercased())
                            .font(.title.bold())
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(stats.playerName)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    Text("Level \(stats.level)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Progress bar to next level
                    ProgressView(value: stats.levelProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(height: 4)
                    
                    Text("\(Int(stats.levelProgress * 100))% to Level \(stats.level + 1)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Streak info
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(stats.currentStreak) day streak")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .scaleEffect(isPressed ? 0.97 : (animatePulse ? 1.025 : 1.0))
        .shadow(color: animatePulse ? Color.blue.opacity(0.10) : Color.clear, radius: 8, x: 0, y: 4)
        .opacity(animatePulse ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.12)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                isPressed = false
                showingPlayerInfo = true
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }
}

// MARK: - Quick Stats
struct QuickStatsView: View {
    let stats: PlayerStats
    
    @Binding var showingStatsInfo: Bool
    @Binding var showingStatInfo: Bool
    @Binding var currentStatInfo: String
    
    @State private var isPressed = false
    @State private var animatePulse = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Games Played",
                    value: "\(stats.totalGames)",
                    icon: "gamecontroller.fill",
                    color: .blue,
                    infoText: AnalyticsHelpText.gamesPlayedInfo,
                    showingStatInfo: $showingStatInfo,
                    currentStatInfo: $currentStatInfo
                )
                
                StatCard(
                    title: "Win Rate",
                    value: "\(Int(stats.winRate * 100))%",
                    icon: "trophy.fill",
                    color: .yellow,
                    infoText: AnalyticsHelpText.winRateInfo,
                    showingStatInfo: $showingStatInfo,
                    currentStatInfo: $currentStatInfo
                )
                
                StatCard(
                    title: "Best Score",
                    value: "\(stats.bestScore)",
                    icon: "star.fill",
                    color: .orange,
                    infoText: AnalyticsHelpText.bestScoreInfo,
                    showingStatInfo: $showingStatInfo,
                    currentStatInfo: $currentStatInfo
                )
                
                StatCard(
                    title: "Avg Score",
                    value: "\(stats.averageScore)",
                    icon: "chart.bar.fill",
                    color: .green,
                    infoText: AnalyticsHelpText.avgScoreInfo,
                    showingStatInfo: $showingStatInfo,
                    currentStatInfo: $currentStatInfo
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .scaleEffect(isPressed ? 0.97 : (animatePulse ? 1.025 : 1.0))
        .shadow(color: animatePulse ? Color.blue.opacity(0.10) : Color.clear, radius: 8, x: 0, y: 4)
        .opacity(animatePulse ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.12)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                isPressed = false
                showingStatsInfo = true
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let infoText: String
    
    @Binding var showingStatInfo: Bool
    @Binding var currentStatInfo: String
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
            }
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.12)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                isPressed = false
                currentStatInfo = infoText
                showingStatInfo = true
            }
        }
    }
}

// MARK: - Win/Loss Chart
struct WinLossChartView: View {
    let stats: PlayerStats
    let timeframe: PlayerAnalyticsView.Timeframe
    
    @Binding var showingWinLossInfo: Bool
    
    @State private var isPressed = false
    @State private var animatePulse = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Win/Loss Trend")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart {
                ForEach(stats.winLossData, id: \.date) { data in
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Wins", data.wins)
                    )
                    .foregroundStyle(.green)
                    .symbol(Circle())
                    
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Losses", data.losses)
                    )
                    .foregroundStyle(.red)
                    .symbol(Circle())
                }
            }
            .frame(height: 200)
            .chartLegend(position: .bottom)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .scaleEffect(isPressed ? 0.97 : (animatePulse ? 1.025 : 1.0))
        .shadow(color: animatePulse ? Color.blue.opacity(0.10) : Color.clear, radius: 8, x: 0, y: 4)
        .opacity(animatePulse ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.12)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                isPressed = false
                showingWinLossInfo = true
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }
}

// MARK: - Performance Trends
struct PerformanceTrendsView: View {
    let stats: PlayerStats
    let timeframe: PlayerAnalyticsView.Timeframe
    
    @Binding var showingPerformanceInfo: Bool
    
    @State private var isPressed = false
    @State private var animatePulse = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Trends")
                .font(.headline)
                .foregroundColor(.primary)
            
            Chart {
                ForEach(stats.performanceData, id: \.date) { data in
                    AreaMark(
                        x: .value("Date", data.date),
                        y: .value("Score", data.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    LineMark(
                        x: .value("Date", data.date),
                        y: .value("Score", data.score)
                    )
                    .foregroundStyle(.blue)
                    .symbol(Circle())
                }
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .scaleEffect(isPressed ? 0.97 : (animatePulse ? 1.025 : 1.0))
        .shadow(color: animatePulse ? Color.blue.opacity(0.10) : Color.clear, radius: 8, x: 0, y: 4)
        .opacity(animatePulse ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.12)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                isPressed = false
                showingPerformanceInfo = true
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }
}

// MARK: - Recent Games
struct RecentGamesView: View {
    let stats: PlayerStats
    
    @Binding var showingRecentGamesInfo: Bool
    
    @State private var isPressed = false
    @State private var animatePulse = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Games")
                .font(.headline)
                .foregroundColor(.primary)
            
            ForEach(stats.recentGames.prefix(5), id: \.id) { game in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.gameName)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)
                        
                        Text(game.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(game.score)")
                            .font(.subheadline.bold())
                            .foregroundColor(game.isWin ? .green : .red)
                        
                        Text(game.isWin ? "WIN" : "LOSS")
                            .font(.caption)
                            .foregroundColor(game.isWin ? .green : .red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                (game.isWin ? Color.green : Color.red).opacity(0.1)
                            )
                            .cornerRadius(4)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .scaleEffect(isPressed ? 0.97 : (animatePulse ? 1.025 : 1.0))
        .shadow(color: animatePulse ? Color.blue.opacity(0.10) : Color.clear, radius: 8, x: 0, y: 4)
        .opacity(animatePulse ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.12)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                isPressed = false
                showingRecentGamesInfo = true
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }
}

// MARK: - Achievements
struct AchievementsView: View {
    let stats: PlayerStats
    
    @Binding var showingAchievementsInfo: Bool
    
    @State private var isPressed = false
    @State private var animatePulse = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(stats.achievements, id: \.id) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .scaleEffect(isPressed ? 0.97 : (animatePulse ? 1.025 : 1.0))
        .shadow(color: animatePulse ? Color.blue.opacity(0.10) : Color.clear, radius: 8, x: 0, y: 4)
        .opacity(animatePulse ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.12)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                isPressed = false
                showingAchievementsInfo = true
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animatePulse = true
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundColor(achievement.isUnlocked ? achievement.color : .gray)
            
            Text(achievement.title)
                .font(.caption.bold())
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text(achievement.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            achievement.isUnlocked ? 
            achievement.color.opacity(0.1) : 
            Color(.systemGray6)
        )
        .cornerRadius(12)
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
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

// Helper for streak calculation
extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

func calculateStreak(dates: Set<Date>) -> Int {
    guard !dates.isEmpty else { return 0 }
    let sorted = dates.sorted(by: >)
    var streak = 1
    var prev = sorted.first!
    for date in sorted.dropFirst() {
        if Calendar.current.dateComponents([.day], from: date, to: prev).day == 1 {
            streak += 1
            prev = date
        } else {
            break
        }
    }
    return streak
} 
