//
//  GameSetupView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation
import SwiftUI
import Amplify



// Simple mutable PlayerStats for GameSetupView
struct SimplePlayerStats {
    var totalGames: Int = 0
    var totalScore: Int = 0
    var averageScore: Double = 0.0
}

struct GameSetupView: View {
    @State private var showJoinGame = false
    @State private var showCreateGame = false
    @State private var showUserProfile = false
    @StateObject private var userService = UserService.shared
    @State private var showProfileEdit = false
    @State private var allPlayers: [User] = []
    @State private var selectedPlayer: User? = nil
    @State private var playerStats = SimplePlayerStats()
    @State private var navigateToScoreboard = false
    @State private var createdGame: Game?
    @State private var userGames: [Game] = []
    @State private var showGameSelection = false
    @State private var showAnalytics = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    //Text("ScoreBoard").font(.title)

                    // Welcome Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Welcome to ScoreBoard!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Create or join ScoreBoard with friends. Players can be anonymous or registered users.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Profile Status
                    if userService.isLoading {
                        VStack(spacing: 8) {
                            HStack {
                                ProgressView()
                                Text("Loading profile...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let error = userService.error {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                    } else if let profile = userService.currentUser {
                        // User has profile
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Profile")
                                .font(.headline)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(profile.username)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    Text(profile.email)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(action: {
                                    showProfileEdit = true
                                }) {
                                    Image(systemName: "pencil.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            
                            // Show completion status
                            if !userService.hasCompleteProfile() {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("Update your profile for better experience")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    } else {
                        // User needs to create profile (fallback)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Profile Setup")
                                .font(.headline)
                            
                            if let error = userService.error {
                                Text("Error: \(error)")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                
                                Button("Retry") {
                                    Task {
                                        await userService.ensureUserProfile()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            } else {
                                Text("Setting up your profile...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    // Game Actions
                    VStack(spacing: 16) {
                        Button(action: {
                            showCreateGame = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text("Create New Scoreboard")
                                        .font(.headline)
                                    Text("Start a new scoreboard game")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            if userGames.count == 1 {
                                // Only one game - go directly to it
                                createdGame = userGames.first
                                navigateToScoreboard = true
                            } else if userGames.count > 1 {
                                // Multiple games - show selection
                                showGameSelection = true
                            } else {
                                // No games - show join interface
                                showJoinGame = true
                            }
                        }) {
                            HStack {
                                Image(systemName: userGames.isEmpty ? "person.2.circle.fill" : "gamecontroller.fill")
                                    .font(.title2)
                                    .foregroundColor(userGames.isEmpty ? .primary : .green)
                                VStack(alignment: .leading) {
                                    Text(userGames.isEmpty ? "Join Existing Game" : "My Scoreboards")
                                        .font(.headline)
                                    Text(userGames.isEmpty ? "Enter a game code to join" : "\(userGames.count) active game\(userGames.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if userGames.isEmpty {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.green)
                                        Text("\(userGames.count)")
                                            .font(.caption.bold())
                                            .foregroundColor(.green)
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(userGames.isEmpty ? Color(.systemGray4) : Color.green, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Analytics Section
                    if let profile = userService.currentUser {
                        VStack(spacing: 16) {
                            Button(action: {
                                showAnalytics = true
                            }) {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.title2)
                                        .foregroundColor(.purple)
                                    VStack(alignment: .leading) {
                                        Text("View Analytics")
                                            .font(.headline)
                                        Text("Detailed player statistics and trends")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.purple)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Simple Stats Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Player Stats").font(.headline)
                        
                        if allPlayers.isEmpty {
                            Text("No players found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            Picker("Select Player", selection: $selectedPlayer) {
                                Text("All Players").tag(nil as User?)
                                ForEach(allPlayers, id: \.id) { player in
                                    Text(player.username).tag(player as User?)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                            // Simple stats display
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Total Games:")
                                    Spacer()
                                    Text("\(playerStats.totalGames)")
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("Total Score:")
                                    Spacer()
                                    Text("\(playerStats.totalScore)")
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("Average Score:")
                                    Spacer()
                                    Text(String(format: "%.1f", playerStats.averageScore))
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    

                }
                .padding()
            }
            .sheet(isPresented: $showCreateGame) {
                CreateGameView(showCreateGame: $showCreateGame, onGameCreated: { game in
                    print("🔍 DEBUG: Game created successfully, navigating to scoreboard")
                    createdGame = game
                    navigateToScoreboard = true
                    showCreateGame = false
                })
            }
            .sheet(isPresented: $showJoinGame) {
                JoinGameView(showJoinGame: $showJoinGame, onGameJoined: { game in
                    createdGame = game
                    navigateToScoreboard = true
                    showJoinGame = false
                })
            }
            .sheet(isPresented: $showGameSelection) {
                GameSelectionView(
                    games: userGames,
                    onGameSelected: { selectedGame in
                        createdGame = selectedGame
                        navigateToScoreboard = true
                        showGameSelection = false
                    },
                    onGameDeleted: {
                        // Refresh user games after deletion
                        loadUserGames()
                    }
                )
            }
            .sheet(isPresented: $showProfileEdit) {
                ProfileEditView()
            }
            .sheet(isPresented: $showAnalytics) {
                PlayerAnalyticsView()
            }
            .navigationDestination(isPresented: $navigateToScoreboard) {
                if let game = createdGame {
                    Scoreboardviewtest(game: .constant(game)) { updatedGame in
                        // Update the createdGame if needed
                        createdGame = updatedGame
                    }
                } else {
                    EmptyView()
                }
            }
            .onAppear {
                loadAllPlayersAndStats()
                Task {
                    // Clean up any duplicate users first
                    await userService.cleanupDuplicateUsers()
                    
                    // Ensure user profile
                    await userService.ensureUserProfile()
                }
                loadUserGames()
            }
            .onChange(of: selectedPlayer) { _ in
                loadPlayerStats()
            }
        }
    }
    
    func loadAllPlayersAndStats() {
        Task {
            do {
                let result = try await Amplify.API.query(request: .list(User.self))
                switch result {
                case .success(let users):
                    await MainActor.run {
                        self.allPlayers = Array(users)
                        if let firstPlayer = Array(users).first {
                            self.selectedPlayer = firstPlayer
                        }
                    }
                case .failure(let error):
                    print("Error loading players: \(error)")
                }
            } catch {
                print("Error loading players: \(error)")
            }
        }
    }
    
    func loadPlayerStats() {
        Task {
            do {
                let result = try await Amplify.API.query(request: .list(Game.self))
                switch result {
                case .success(let games):
                    await MainActor.run {
                        self.playerStats = calculatePlayerStats(games: Array(games), selectedPlayer: selectedPlayer)
                    }
                case .failure(let error):
                    print("Error loading games: \(error)")
                }
            } catch {
                print("Error loading games: \(error)")
            }
        }
    }
    
    func calculatePlayerStats(games: [Game], selectedPlayer: User?) -> SimplePlayerStats {
        var stats = SimplePlayerStats()
        
        for game in games {
            if let selectedPlayer = selectedPlayer {
                // Filter games for specific player
                let playerIDs = game.playerIDs
                if playerIDs.contains(selectedPlayer.id) {
                    stats.totalGames += 1
                                    let finalScores = game.finalScores
                if let playerIndex = playerIDs.firstIndex(of: selectedPlayer.id),
                   playerIndex < finalScores.count {
                    let scoreString = finalScores[playerIndex]
                    if let score = Int(scoreString) {
                        stats.totalScore += score
                    }
                }
                }
            } else {
                // All players stats
                stats.totalGames += 1
                let finalScores = game.finalScores
                let totalScore = finalScores.compactMap { scoreString in
                    Int(scoreString)
                }.reduce(0, +)
                stats.totalScore += totalScore
            }
        }
        
        stats.averageScore = stats.totalGames > 0 ? Double(stats.totalScore) / Double(stats.totalGames) : 0.0
        return stats
    }
    

    
    func loadUserGames() {
        Task {
            do {
                // Get current user info using helper function that works for both guest and authenticated users
                guard let currentUserInfo = await getCurrentUser() else {
                    print("🔍 DEBUG: Unable to get current user information")
                    await MainActor.run {
                        self.userGames = []
                    }
                    return
                }
                
                let userId = currentUserInfo.userId
                let isGuest = currentUserInfo.isGuest
                
                print("🔍 DEBUG: Current user ID: \(userId), isGuest: \(isGuest)")
                
                let result = try await Amplify.API.query(request: .list(Game.self))
                
                switch result {
                case .success(let games):
                    print("🔍 DEBUG: Total games in database: \(games.count)")
                    
                    // Filter games where the current user is a player OR the host
                    let filteredGames = games.filter { game in
                        let playerIDs = game.playerIDs
                        let hostUserID = game.hostUserID
                        
                        print("🔍 DEBUG: Checking game \(game.id)")
                        print("🔍 DEBUG:   - Host User ID: \(hostUserID)")
                        print("🔍 DEBUG:   - Player IDs: \(playerIDs)")
                        
                        // Check if user is the host
                        if hostUserID == userId {
                            print("🔍 DEBUG:   - User is HOST of this game")
                            return true
                        }
                        
                        // Check for registered user ID in playerIDs
                        if playerIDs.contains(userId) {
                            print("🔍 DEBUG:   - User is PLAYER in this game (exact match)")
                            return true
                        }
                        
                        // Check for anonymous user format "userID:displayName" in playerIDs
                        let hasAnonymousMatch = playerIDs.contains { playerID in
                            playerID.hasPrefix(userId)
                        }
                        if hasAnonymousMatch {
                            print("🔍 DEBUG:   - User is PLAYER in this game (anonymous match)")
                            return true
                        }
                        
                        print("🔍 DEBUG:   - User is NOT in this game")
                        return false
                    }
                    
                    print("🔍 DEBUG: Found \(filteredGames.count) games for user")
                    for game in filteredGames {
                        print("🔍 DEBUG:   - Game ID: \(game.id)")
                    }
                    
                    await MainActor.run {
                        self.userGames = filteredGames
                    }
                    
                case .failure(let error):
                    print("🔍 DEBUG: Error loading user games: \(error)")
                    await MainActor.run {
                        self.userGames = []
                    }
                }
            } catch {
                print("🔍 DEBUG: Exception in loadUserGames: \(error)")
                await MainActor.run {
                    self.userGames = []
                }
            }
        }
    }
}

