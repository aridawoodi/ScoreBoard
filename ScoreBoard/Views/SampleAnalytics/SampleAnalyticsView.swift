//
//  SampleAnalyticsView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI

// MARK: - Sample Analytics View
struct SampleAnalyticsView: View {
    @State private var selectedTimeframe: Timeframe = .week
    
    enum Timeframe: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Sample data indicator
                SampleDataIndicator()
                
                // Sample analytics content
                SamplePlayerHeaderView()
                SampleQuickStatsView()
                SampleWinLossChartView(timeframe: selectedTimeframe)
                SamplePerformanceTrendsView(timeframe: selectedTimeframe)
                SampleRecentGamesView()
                SampleAchievementsView()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
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

// MARK: - Sample Data Indicator
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

// MARK: - Sample Player Header
struct SamplePlayerHeaderView: View {
    @State private var showPlayerInfo = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text("S")
                            .font(.title.bold())
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Sample Player")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            showPlayerInfo = true
                        }) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .padding(4)
                        }
                    }
                    
                    Text("Level 5")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: 0.75)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(height: 4)
                    
                    Text("75% to Level 6")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("7 day streak")
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
        .alert("Player Information", isPresented: $showPlayerInfo) {
            Button("OK") { }
        } message: {
            Text(AnalyticsHelpText.playerInfo)
        }
    }
}

// MARK: - Sample Quick Stats
struct SampleQuickStatsView: View {
    @State private var showStatsInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Stats")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showStatsInfo = true
                }) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .padding(4)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                SampleStatCard(title: "Games", value: "42", icon: "gamecontroller.fill", color: .blue, infoText: AnalyticsHelpText.gamesPlayedInfo)
                SampleStatCard(title: "Win Rate", value: "68%", icon: "trophy.fill", color: .yellow, infoText: AnalyticsHelpText.winRateInfo)
                SampleStatCard(title: "Best Score", value: "1250", icon: "star.fill", color: .orange, infoText: AnalyticsHelpText.bestScoreInfo)
            }
        }
        .alert("Quick Stats Information", isPresented: $showStatsInfo) {
            Button("OK") { }
        } message: {
            Text(AnalyticsHelpText.quickStatsInfo)
        }
    }
}

struct SampleStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let infoText: String
    @State private var showInfo = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                Button(action: {
                    showInfo = true
                }) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .padding(2)
                }
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
        .alert(title, isPresented: $showInfo) {
            Button("OK") { }
        } message: {
            Text(infoText)
        }
    }
}

// MARK: - Sample Win/Loss Chart
struct SampleWinLossChartView: View {
    let timeframe: SampleAnalyticsView.Timeframe
    @State private var showWinLossInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Win/Loss Trend")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showWinLossInfo = true
                }) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .padding(4)
                }
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Wins")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("28")
                        .font(.title2.bold())
                        .foregroundColor(.green)
                }
                
                VStack(spacing: 8) {
                    Text("Losses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("14")
                        .font(.title2.bold())
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Win Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("66.7%")
                        .font(.title2.bold())
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .alert("Win/Loss Information", isPresented: $showWinLossInfo) {
            Button("OK") { }
        } message: {
            Text(AnalyticsHelpText.winLossInfo)
        }
    }
}

// MARK: - Sample Performance Trends
struct SamplePerformanceTrendsView: View {
    let timeframe: SampleAnalyticsView.Timeframe
    @State private var showPerformanceInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Performance Trends")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showPerformanceInfo = true
                }) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .padding(4)
                }
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Average Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("850")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("Best Score")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("1250")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text("Games This \(timeframe.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("12")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .alert("Performance Trends Information", isPresented: $showPerformanceInfo) {
            Button("OK") { }
        } message: {
            Text(AnalyticsHelpText.performanceInfo)
        }
    }
}

// MARK: - Sample Recent Games
struct SampleRecentGamesView: View {
    @State private var showRecentGamesInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Games")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showRecentGamesInfo = true
                }) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .padding(4)
                }
            }
            
            VStack(spacing: 8) {
                SampleGameRow(gameName: "Card Game", score: 1250, isWin: true, date: "Today")
                SampleGameRow(gameName: "Board Game", score: 780, isWin: false, date: "Yesterday")
                SampleGameRow(gameName: "Strategy Game", score: 1100, isWin: true, date: "2 days ago")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .alert("Recent Games Information", isPresented: $showRecentGamesInfo) {
            Button("OK") { }
        } message: {
            Text(AnalyticsHelpText.recentGamesInfo)
        }
    }
}

struct SampleGameRow: View {
    let gameName: String
    let score: Int
    let isWin: Bool
    let date: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(gameName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Text(date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(score)")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: isWin ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(isWin ? .green : .red)
                        .font(.caption)
                    Text(isWin ? "Win" : "Loss")
                        .font(.caption)
                        .foregroundColor(isWin ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Sample Achievements
struct SampleAchievementsView: View {
    @State private var showAchievementsInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showAchievementsInfo = true
                }) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .padding(4)
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                SampleAchievementCard(title: "First Win", description: "Win your first game", icon: "trophy.fill", color: .yellow, isUnlocked: true)
                SampleAchievementCard(title: "Streak Master", description: "Win 5 games in a row", icon: "flame.fill", color: .orange, isUnlocked: true)
                SampleAchievementCard(title: "High Scorer", description: "Score 1000+ points", icon: "star.fill", color: .yellow, isUnlocked: true)
                SampleAchievementCard(title: "Regular Player", description: "Play 50 games", icon: "gamecontroller.fill", color: .blue, isUnlocked: false)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .alert("Achievements Information", isPresented: $showAchievementsInfo) {
            Button("OK") { }
        } message: {
            Text(AnalyticsHelpText.achievementsInfo)
        }
    }
}

struct SampleAchievementCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isUnlocked ? color : .gray)
            
            Text(title)
                .font(.caption.bold())
                .foregroundColor(isUnlocked ? .primary : .secondary)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
} 