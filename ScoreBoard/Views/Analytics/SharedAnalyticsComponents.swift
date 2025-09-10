//
//  SharedAnalyticsComponents.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI
import Charts

// MARK: - Shared Timeframe Enum
enum AnalyticsTimeframe: String, CaseIterable {
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

// MARK: - Shared Analytics Header View
struct SharedPlayerHeaderView: View {
    let playerName: String
    let level: Int
    let levelProgress: Double
    let currentStreak: Int
    let isSampleData: Bool
    let onTap: () -> Void
    
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
                        Text(String(playerName.prefix(1)).uppercased())
                            .font(.title.bold())
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(playerName)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        if isSampleData {
                            Spacer()
                            
                            Button(action: onTap) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                    .background(Color.white.opacity(0.8))
                                    .clipShape(Circle())
                                    .padding(4)
                            }
                        }
                    }
                    
                    Text("Level \(level)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    // Progress bar to next level
                    ProgressView(value: levelProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .frame(height: 4)
                    
                    Text("\(Int(levelProgress * 100))% to Level \(level + 1)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            // Streak info
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(currentStreak) day streak")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .scaleEffect(isPressed ? 0.97 : (animatePulse ? 1.025 : 1.0))
        .shadow(color: animatePulse ? Color.blue.opacity(0.10) : Color.clear, radius: 8, x: 0, y: 4)
        .opacity(animatePulse ? 0.98 : 1.0)
        .onTapGesture {
            if !isSampleData {
                withAnimation(.easeInOut(duration: 0.12)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    isPressed = false
                    onTap()
                }
            }
        }
        .onAppear {
            if !isSampleData {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animatePulse = true
                }
            }
        }
    }
}

// MARK: - Shared Quick Stats View
struct SharedQuickStatsView: View {
    let stats: [(title: String, value: String, color: Color, info: String)]
    let isSampleData: Bool
    let onStatTap: (String) -> Void
    let onHeaderTap: () -> Void
    
    @State private var isPressed = false
    @State private var animatePulse = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Stats")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if isSampleData {
                    Spacer()
                    
                    Button(action: onHeaderTap) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .padding(4)
                    }
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(stats.indices, id: \.self) { index in
                    let stat = stats[index]
                    StatCard(
                        title: stat.title,
                        value: stat.value,
                        color: stat.color,
                        isSampleData: isSampleData,
                        onTap: { onStatTap(stat.info) }
                    )
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .scaleEffect(isPressed ? 0.97 : (animatePulse ? 1.025 : 1.0))
        .shadow(color: animatePulse ? Color.blue.opacity(0.10) : Color.clear, radius: 8, x: 0, y: 4)
        .opacity(animatePulse ? 0.98 : 1.0)
        .onTapGesture {
            if !isSampleData {
                withAnimation(.easeInOut(duration: 0.12)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    isPressed = false
                    onHeaderTap()
                }
            }
        }
        .onAppear {
            if !isSampleData {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animatePulse = true
                }
            }
        }
    }
}

// MARK: - Shared Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    let isSampleData: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.title2.bold())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onTapGesture {
            if !isSampleData {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                    onTap()
                }
            }
        }
    }
}

// MARK: - Shared Win/Loss Chart View
struct SharedWinLossChartView: View {
    let wins: Int
    let losses: Int
    let timeframe: AnalyticsTimeframe
    let isSampleData: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Win/Loss Record")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if isSampleData {
                    Spacer()
                    
                    Button(action: onTap) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .padding(4)
                    }
                }
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("\(wins)")
                        .font(.title.bold())
                        .foregroundColor(.green)
                    Text("Wins")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                VStack(spacing: 8) {
                    Text("\(losses)")
                        .font(.title.bold())
                        .foregroundColor(.red)
                    Text("Losses")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text("\(wins + losses)")
                        .font(.title.bold())
                        .foregroundColor(.white)
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .onTapGesture {
            if !isSampleData {
                withAnimation(.easeInOut(duration: 0.12)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    isPressed = false
                    onTap()
                }
            }
        }
    }
}

// MARK: - Shared Performance Trends View
struct SharedPerformanceTrendsView: View {
    let averageScore: Double
    let bestScore: Int
    let timeframe: AnalyticsTimeframe
    let isSampleData: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Performance Trends")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if isSampleData {
                    Spacer()
                    
                    Button(action: onTap) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .padding(4)
                    }
                }
            }
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Average Score")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(String(format: "%.1f", averageScore))
                            .font(.title2.bold())
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Best Score")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text("\(bestScore)")
                            .font(.title2.bold())
                            .foregroundColor(.green)
                    }
                }
                
                // Simple trend indicator
                HStack {
                    Image(systemName: "arrow.up.right")
                        .foregroundColor(.green)
                    Text("Improving")
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                }
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .onTapGesture {
            if !isSampleData {
                withAnimation(.easeInOut(duration: 0.12)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    isPressed = false
                    onTap()
                }
            }
        }
    }
}

// MARK: - Shared Recent Games View
struct SharedRecentGamesView: View {
    let recentGames: [(name: String, score: Int, result: String, date: String)]
    let isSampleData: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Games")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if isSampleData {
                    Spacer()
                    
                    Button(action: onTap) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .padding(4)
                    }
                }
            }
            
            VStack(spacing: 8) {
                ForEach(recentGames.indices, id: \.self) { index in
                    let game = recentGames[index]
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(game.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(game.date)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(game.score)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                            Text(game.result)
                                .font(.caption)
                                .foregroundColor(game.result == "Won" ? .green : .red)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if index < recentGames.count - 1 {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .onTapGesture {
            if !isSampleData {
                withAnimation(.easeInOut(duration: 0.12)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    isPressed = false
                    onTap()
                }
            }
        }
    }
}

// MARK: - Shared Achievements View
struct SharedAchievementsView: View {
    let achievements: [(title: String, description: String, icon: String, color: Color, isUnlocked: Bool)]
    let isSampleData: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if isSampleData {
                    Spacer()
                    
                    Button(action: onTap) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                            .padding(4)
                    }
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(achievements.indices, id: \.self) { index in
                    let achievement = achievements[index]
                    AchievementCard(
                        title: achievement.title,
                        description: achievement.description,
                        icon: achievement.icon,
                        color: achievement.color,
                        isUnlocked: achievement.isUnlocked,
                        isSampleData: isSampleData
                    )
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(16)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .onTapGesture {
            if !isSampleData {
                withAnimation(.easeInOut(duration: 0.12)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    isPressed = false
                    onTap()
                }
            }
        }
    }
}

// MARK: - Shared Achievement Card
struct AchievementCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isUnlocked: Bool
    let isSampleData: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isUnlocked ? color : .gray)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isUnlocked ? .white : .white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isUnlocked ? color.opacity(0.1) : Color.black.opacity(0.5))
        .cornerRadius(12)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - Reusable Segmented Picker Component
struct SegmentedPicker<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let options: [(String, T)]
    
    init(title: String, selection: Binding<T>, options: [(String, T)]) {
        self.title = title
        self._selection = selection
        self.options = options
    }
    
    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(options, id: \.0) { option in
                Text(option.0).tag(option.1)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - Game Status Segmented Picker
struct GameStatusSegmentedPicker: View {
    @Binding var selection: GameStatus
    let activeCount: Int
    let completedCount: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background container
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                
                // Sliding background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color("LightGreen"))
                    .frame(width: geometry.size.width / 2 - 2)
                    .offset(x: selection == .active ? -geometry.size.width / 4 + 1 : geometry.size.width / 4 - 1)
                    .animation(.easeInOut(duration: 0.3), value: selection)
                
                // Buttons
                HStack(spacing: 0) {
                    // Active option
                    Button(action: {
                        selection = .active
                    }) {
                        Text("Active (\(activeCount))")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(selection == .active ? .white : .white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Completed option
                    Button(action: {
                        selection = .completed
                    }) {
                        Text("Completed (\(completedCount))")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(selection == .completed ? .white : .white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(2)
            }
        }
        .frame(height: 32)
    }
}

// MARK: - Analytics Timeframe Segmented Picker
struct AnalyticsTimeframeSegmentedPicker: View {
    @Binding var selection: AnalyticsTimeframe
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background container
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                
                // Sliding background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color("LightGreen"))
                    .frame(width: geometry.size.width / 3 - 2)
                    .offset(x: getOffset(for: selection, in: geometry))
                    .animation(.easeInOut(duration: 0.3), value: selection)
                
                // Buttons
                HStack(spacing: 0) {
                    ForEach(AnalyticsTimeframe.allCases, id: \.self) { timeframe in
                        Button(action: {
                            selection = timeframe
                        }) {
                            Text(timeframe.rawValue)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(selection == timeframe ? .white : .white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(2)
            }
        }
        .frame(height: 32)
    }
    
    private func getOffset(for selection: AnalyticsTimeframe, in geometry: GeometryProxy) -> CGFloat {
        let segmentWidth = geometry.size.width / 3
        let centerOffset = segmentWidth / 2 - 1
        
        switch selection {
        case .week:
            return -segmentWidth + centerOffset
        case .month:
            return centerOffset
        case .year:
            return segmentWidth - centerOffset
        }
    }
}

// MARK: - Leaderboard Timeframe Segmented Picker
struct LeaderboardTimeframeSegmentedPicker: View {
    @Binding var selection: PlayerLeaderboardView.Timeframe
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background container
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                
                // Sliding background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color("LightGreen"))
                    .frame(width: geometry.size.width / 3 - 2)
                    .offset(x: getOffset(for: selection, in: geometry))
                    .animation(.easeInOut(duration: 0.3), value: selection)
                
                // Buttons
                HStack(spacing: 0) {
                    ForEach(PlayerLeaderboardView.Timeframe.allCases, id: \.self) { timeframe in
                        Button(action: {
                            selection = timeframe
                        }) {
                            Text(timeframe.rawValue)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(selection == timeframe ? .white : .white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(2)
            }
        }
        .frame(height: 32)
    }
    
    private func getOffset(for selection: PlayerLeaderboardView.Timeframe, in geometry: GeometryProxy) -> CGFloat {
        let segmentWidth = geometry.size.width / 2
        
        switch selection {
        case .allTime:
            return -segmentWidth / 2
        case .thisMonth:
            return segmentWidth / 2
        }
    }
}
