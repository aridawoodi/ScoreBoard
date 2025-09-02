//
//  SampleAnalyticsView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI

// MARK: - Sample Analytics View
struct SampleAnalyticsView: View {
    @State private var selectedTimeframe: AnalyticsTimeframe = .week
    
    // Alert states for help text
    @State private var showingPlayerInfo = false
    @State private var showingStatsInfo = false
    @State private var showingWinLossInfo = false
    @State private var showingPerformanceInfo = false
    @State private var showingRecentGamesInfo = false
    @State private var showingAchievementsInfo = false
    @State private var showingStatInfo = false
    @State private var currentStatInfo = ""
    
    // Computed properties to break down complex expressions
    private var sampleQuickStatsData: [(String, String, Color, String)] {
        return [
            ("Games Played", "12", .blue, AnalyticsHelpText.gamesPlayedInfo),
            ("Win Rate", "75%", .green, AnalyticsHelpText.winRateInfo),
            ("Avg Score", "85.2", .orange, AnalyticsHelpText.avgScoreInfo),
            ("Best Score", "150", .purple, AnalyticsHelpText.bestScoreInfo)
        ]
    }
    
    private var sampleRecentGamesData: [(String, Int, String, String)] {
        return [
            ("Falcon", 120, "Won", "2 days ago"),
            ("Eagles", 95, "Lost", "1 week ago"),
            ("Hawks", 135, "Won", "2 weeks ago")
        ]
    }
    
    private var sampleAchievementsData: [(String, String, String, Color, Bool)] {
        return [
            ("First Win", "Win your first game", "trophy.fill", .yellow, true),
            ("Streak Master", "Win 5 games in a row", "flame.fill", .orange, true),
            ("High Scorer", "Score 150+ points in any game", "star.fill", .purple, false),
            ("Highest Score Master", "Win 10 highest-score games", "arrow.up.circle.fill", .green, false),
            ("Lowest Score Master", "Win 10 lowest-score games", "arrow.down.circle.fill", .blue, false),
            ("Versatile Player", "Win both highest and lowest score games", "arrow.up.arrow.down.circle.fill", .purple, true)
        ]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Sample data indicator
                SampleDataIndicator()
                
                // Sample analytics content using shared components
                SharedPlayerHeaderView(
                    playerName: "Sample Player",
                    level: 5,
                    levelProgress: 0.75,
                    currentStreak: 7,
                    isSampleData: true,
                    onTap: { showingPlayerInfo = true }
                )
                
                SharedQuickStatsView(
                    stats: sampleQuickStatsData,
                    isSampleData: true,
                    onStatTap: { info in
                        currentStatInfo = info
                        showingStatInfo = true
                    },
                    onHeaderTap: { showingStatsInfo = true }
                )
                
                SharedWinLossChartView(
                    wins: 9,
                    losses: 3,
                    timeframe: selectedTimeframe,
                    isSampleData: true,
                    onTap: { showingWinLossInfo = true }
                )
                
                // Sample Win Condition Breakdown
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
                            Text("6")
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
                            Text("3")
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
                
                SharedPerformanceTrendsView(
                    averageScore: 85.2,
                    bestScore: 150,
                    timeframe: selectedTimeframe,
                    isSampleData: true,
                    onTap: { showingPerformanceInfo = true }
                )
                
                SharedRecentGamesView(
                    recentGames: sampleRecentGamesData,
                    isSampleData: true,
                    onTap: { showingRecentGamesInfo = true }
                )
                
                SharedAchievementsView(
                    achievements: sampleAchievementsData,
                    isSampleData: true,
                    onTap: { showingAchievementsInfo = true }
                )
            }
            .padding()
        }
        .background(Color.clear)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                AnalyticsTimeframeSegmentedPicker(selection: $selectedTimeframe)
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
        .gradientBackground()
    }
}

// MARK: - Sample Data Indicator (Keep this as it's unique to sample view)
struct SampleDataIndicator: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Sample Analytics Data")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("This shows what your analytics will look like once you start playing games. Create or join a game to see your real statistics!")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}
