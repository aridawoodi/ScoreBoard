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
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    
                    // Timeframe Picker
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases, id: \.self) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search players...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding()
                .background(Color(.systemGray6))
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
                            .foregroundColor(.secondary)
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
                                    .frame(width: 50, alignment: .leading)
                                Text("Player")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Games")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text("Points")
                                    .font(.headline)
                                    .frame(width: 80, alignment: .trailing)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            
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
            .navigationTitle("Scoreboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("X") {
                        dismiss()
                    }
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
        default: return .primary
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
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
            
            // Games
            VStack(alignment: .leading, spacing: 2) {
                ForEach(player.games.prefix(2), id: \.self) { gameName in
                    Text(gameName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                if player.games.count > 2 {
                    Text("+\(player.games.count - 2) more")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Points
            Text(formatPoints(player.points))
                .font(.body)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .trailing)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func formatPoints(_ points: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: points)) ?? "\(points)"
    }
} 