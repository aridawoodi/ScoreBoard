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
            ("High Scorer", "Score 150+ points", "star.fill", .purple, false),
            ("Perfect Game", "Win with max score", "crown.fill", .purple, false)
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
        .background(Color(.systemGroupedBackground))
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
                    .foregroundColor(.primary)
                
                Text("This shows what your analytics will look like once you start playing games. Create or join a game to see your real statistics!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}
