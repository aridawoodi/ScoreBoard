//
//  PlayerLeaderboardView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI
import Amplify

// MARK: - Player Leaderboard View
struct PlayerLeaderboardView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedTimeframe: Timeframe = .allTime
    @State private var selectedWinCondition: WinConditionFilter = .allGames
    @State private var selectedPlayerType: PlayerTypeFilter = .allPlayers
    @State private var selectedPlayer: PlayerLeaderboardEntry?
    @State private var showPlayerDetail = false
    @StateObject private var dataManager = DataManager.shared
    
    enum Timeframe: String, CaseIterable {
        case allTime = "All Time"
        case thisMonth = "This Month"
    }
    
    enum WinConditionFilter: String, CaseIterable {
        case allGames = "All Games"
        case highestScore = "Highest Score"
        case lowestScore = "Lowest Score"
    }
    
    enum PlayerTypeFilter: String, CaseIterable {
        case allPlayers = "All Players"
        case registered = "Registered"
        case anonymous = "Anonymous"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Section
                VStack(spacing: 12) {
                    HStack {
                        Text("Player Leaderboard")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    // Timeframe Picker
                    LeaderboardTimeframeSegmentedPicker(selection: $selectedTimeframe)
                    
                    // Win Condition Filter
                    HStack(spacing: 8) {
                        ForEach(WinConditionFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                selectedWinCondition = filter
                            }) {
                                Text(filter.rawValue)
                                    .font(.caption)
                                    .foregroundColor(selectedWinCondition == filter ? .white : .white.opacity(0.7))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedWinCondition == filter ? Color("LightGreen") : Color.black.opacity(0.3))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Player Type Filter
                    HStack(spacing: 8) {
                        ForEach(PlayerTypeFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                selectedPlayerType = filter
                            }) {
                                Text(filter.rawValue)
                                    .font(.caption)
                                    .foregroundColor(selectedPlayerType == filter ? .white : .white.opacity(0.7))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedPlayerType == filter ? Color("LightGreen") : Color.black.opacity(0.3))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))
                    TextField("", text: $searchText)
                        .modifier(AppTextFieldStyle(placeholder: "Search players...", text: $searchText))
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Leaderboard Table
                if dataManager.isLoadingLeaderboard {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading leaderboard...")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Header
                            HStack {
                                Text("Rank")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 50, alignment: .leading)
                                Text("Player")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Wins")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 60, alignment: .center)
                                Text("Games")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 60, alignment: .center)
                                Text("Win%")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 60, alignment: .trailing)
                            }
                            .padding()
                            .background(Color.black.opacity(0.3))
                            
                            // Player Rows
                            ForEach(filteredPlayers.indices, id: \.self) { index in
                                let player = filteredPlayers[index]
                                PlayerLeaderboardRow(
                                    rank: index + 1,
                                    player: player,
                                    onTap: {
                                        selectedPlayer = player
                                        showPlayerDetail = true
                                    }
                                )
                                
                                if index < filteredPlayers.count - 1 {
                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("X") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear {
                Task {
                    // Get current user ID and load user-specific leaderboard data
                    print("🔍 DEBUG: PlayerLeaderboardView onAppear - attempting to load leaderboard")
                    if let currentUserId = getCurrentUserId() {
                        print("🔍 DEBUG: PlayerLeaderboardView - found current user ID: \(currentUserId)")
                        await dataManager.loadUserLeaderboard(for: currentUserId)
                    } else {
                        print("🔍 DEBUG: PlayerLeaderboardView - no current user ID found")
                    }
                }
            }
            .onChange(of: selectedTimeframe) { _ in
                // Filter is applied in computed property, no need to refresh data
            }
            .onChange(of: selectedWinCondition) { _ in
                // Filter is applied in computed property, no need to refresh data
            }
            .onChange(of: selectedPlayerType) { _ in
                // Filter is applied in computed property, no need to refresh data
            }
            .sheet(isPresented: $showPlayerDetail) {
                if let player = selectedPlayer {
                    PlayerDetailView(player: player)
                }
            }
            .gradientBackground()
        }
    }
    
    private var filteredPlayers: [PlayerLeaderboardEntry] {
        var players = dataManager.userLeaderboardData
        
        // Apply search filter
        if !searchText.isEmpty {
            players = players.filter { player in
                player.nickname.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply win condition filter
        switch selectedWinCondition {
        case .highestScore:
            players = players.filter { player in
                player.gamesPlayed.contains { game in
                    game.winCondition == .highestScore
                }
            }
        case .lowestScore:
            players = players.filter { player in
                player.gamesPlayed.contains { game in
                    game.winCondition == .lowestScore
                }
            }
        case .allGames:
            break // No filtering
        }
        
        // Apply player type filter
        switch selectedPlayerType {
        case .registered:
            // Registered players: both guest users (guest_ prefix) and Cognito authenticated users (UUID format)
            players = players.filter { player in
                player.playerID.hasPrefix("guest_") || 
                (player.playerID.count > 20 && player.playerID.contains("-"))
            }
        case .anonymous:
            // Anonymous players: simple display names (like "Team 1", "Team 2") or anonymous users with format "userID:displayName"
            players = players.filter { player in
                !player.playerID.hasPrefix("guest_") && 
                !(player.playerID.count > 20 && player.playerID.contains("-"))
            }
        case .allPlayers:
            break // No filtering
        }
        
        // Apply timeframe filter
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeframe {
        case .thisMonth:
            // Month-to-date: from the first day of current month to now
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            players = players.filter { player in
                player.gamesPlayed.contains { game in
                    game.date >= startOfMonth
                }
            }
        case .allTime:
            break // No filtering
        }
        
        return players
    }
    
    // Helper function to get current user ID
    private func getCurrentUserId() -> String? {
        // Check if we're in guest mode
        let isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
        
        if isGuestUser {
            // Handle guest user
            let guestUserId = UserDefaults.standard.string(forKey: "current_guest_user_id") ?? ""
            print("🔍 DEBUG: getCurrentUserId - found guest user ID: \(guestUserId)")
            return guestUserId
        } else {
            // Handle regular authenticated user
            let authUserId = UserDefaults.standard.string(forKey: "authenticated_user_id")
            if let userId = authUserId, !userId.isEmpty {
                print("🔍 DEBUG: getCurrentUserId - found authenticated user ID: \(userId)")
                return userId
            }
            print("🔍 DEBUG: getCurrentUserId - no authenticated user ID found")
            return nil
        }
    }
}

// MARK: - Player Leaderboard Row
struct PlayerLeaderboardRow: View {
    let rank: Int
    let player: PlayerLeaderboardEntry
    let onTap: () -> Void
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .white
        }
    }
    
    private var rankIcon: String {
        switch rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return ""
        }
    }
    
    private var winRateColor: Color {
        if player.winRate >= 0.7 { return .green }
        else if player.winRate >= 0.5 { return .orange }
        else { return .red }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Rank
                HStack(spacing: 4) {
                    Text("\(rank)")
                        .font(.headline)
                        .foregroundColor(rankColor)
                        .frame(width: 50, alignment: .leading)
                    
                    if !rankIcon.isEmpty {
                        Text(rankIcon)
                            .font(.title2)
                    }
                }
                
                // Player Name
                Text(player.nickname)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                
                // Wins
                Text("\(player.totalWins)")
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .center)
                
                // Games
                Text("\(player.totalGames)")
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(width: 60, alignment: .center)
                
                // Win Rate
                Text("\(Int(player.winRate * 100))%")
                    .font(.body)
                    .foregroundColor(winRateColor)
                    .frame(width: 60, alignment: .trailing)
            }
            .padding()
            .background(Color.black.opacity(0.3))
        }
        .buttonStyle(PlainButtonStyle())
    }
} 