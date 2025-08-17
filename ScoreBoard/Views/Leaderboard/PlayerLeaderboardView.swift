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
    @StateObject private var dataManager = DataManager.shared
    
    enum Timeframe: String, CaseIterable {
        case weekly = "Weekly"
        case allTime = "All Time"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Section
                VStack(spacing: 12) {
                    HStack {
                        Text("Everyone")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    
                    // Timeframe Picker
                    LeaderboardTimeframeSegmentedPicker(selection: $selectedTimeframe)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.7))
                    ZStack(alignment: .leading) {
                        if searchText.isEmpty {
                            Text("Search players...")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.body)
                        }
                        TextField("", text: $searchText)
                            .foregroundColor(.white)
                            .textFieldStyle(.plain)
                    }
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
                                Text("Games")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Points")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 80, alignment: .trailing)
                            }
                            .padding()
                            .background(Color.black.opacity(0.3))
                            
                            // Player Rows
                            ForEach(filteredPlayers.indices, id: \.self) { index in
                                let player = filteredPlayers[index]
                                PlayerLeaderboardRow(
                                    rank: index + 1,
                                    player: player
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
                    await dataManager.loadAllData()
                }
            }
            .onChange(of: selectedTimeframe) { _ in
                Task {
                    await dataManager.refreshData()
                }
            }
            .gradientBackground()
        }
    }
    
    private var filteredPlayers: [PlayerLeaderboardEntry] {
        let players = dataManager.leaderboardData
        
        if searchText.isEmpty {
            return players
        } else {
            return players.filter { player in
                player.nickname.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Player Leaderboard Row
struct PlayerLeaderboardRow: View {
    let rank: Int
    let player: PlayerLeaderboardEntry
    
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
    
    var body: some View {
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
            
            // Nickname
            Text(player.nickname)
                .font(.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            
            // Games
            VStack(alignment: .leading, spacing: 2) {
                ForEach(player.games.prefix(2), id: \.self) { gameName in
                    Text(gameName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                if player.games.count > 2 {
                    Text("+\(player.games.count - 2) more")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Points
            Text(formatPoints(player.points))
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 80, alignment: .trailing)
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
    
    private func formatPoints(_ points: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: points)) ?? "\(points)"
    }
} 