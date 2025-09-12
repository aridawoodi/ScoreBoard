//
//  GameSelectionView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation
import SwiftUI
import Amplify

struct GameSelectionView: View {
    let games: [Game]
    let onGameSelected: (Game) -> Void
    let onGameDeleted: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @StateObject private var usernameCache = UsernameCacheService.shared
    @State private var selectedGame: Game?
    @State private var currentUserId: String = ""
    @State private var showDeleteAlert = false
    @State private var gameToDelete: Game?
    @State private var isDeleting = false
    @State private var showDeleteError = false
    @State private var deleteErrorMessage = ""
    
    @State private var selectedGameStatus: GameStatus = .active
    
    // Filter games by selected status
    var filteredGames: [Game] {
        games.filter { $0.gameStatus == selectedGameStatus }
    }
    
    // Count games by status
    var activeGameCount: Int {
        games.filter { $0.gameStatus == .active }.count
    }
    
    var completedGameCount: Int {
        games.filter { $0.gameStatus == .completed }.count
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Spacer()
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.white)
                        .font(.body)
                    }
                    .padding(.horizontal)
                    
                    Text("Choose which game you'd like to view")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Status Slider
                VStack(spacing: 12) {
                    GameStatusSegmentedPicker(
                        selection: $selectedGameStatus,
                        activeCount: activeGameCount,
                        completedCount: completedGameCount
                    )
                    .padding(.horizontal)
                }
                .padding(.bottom, 10)
                
                // Game List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredGames, id: \.id) { game in
                            GameCardView(
                                game: game, 
                                usernameCache: usernameCache,
                                isSelected: selectedGame?.id == game.id,
                                isCreator: GameService.shared.isGameCreator(game, currentUserId: currentUserId),
                                onTap: {
                                    selectedGame = game
                                    // Automatically open the selected game and dismiss the sheet
                                    onGameSelected(game)
                                    dismiss()
                                },
                                onDelete: {
                                    gameToDelete = game
                                    showDeleteAlert = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .gradientBackground()
            .onAppear {
                loadUsernamesFromCache()
                loadCurrentUser()
            }
            .animation(.easeInOut(duration: 0.3), value: selectedGame)
            .alert("Delete Game", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let game = gameToDelete {
                        deleteGame(game)
                    }
                }
            } message: {
                if let game = gameToDelete {
                    Text("Are you sure you want to delete this game? This will permanently remove the game and all its scores. This action cannot be undone.")
                }
            }
            .alert("Delete Failed", isPresented: $showDeleteError) {
                Button("OK") { }
            } message: {
                Text(deleteErrorMessage)
            }
        }
    }
    
    func loadCurrentUser() {
        Task {
            // Get current user info using helper function that works for both guest and authenticated users
            if let currentUserInfo = await getCurrentUser() {
                let userId = currentUserInfo.userId
                let isGuest = currentUserInfo.isGuest
                
                await MainActor.run {
                    self.currentUserId = userId
                }
                print("🔍 DEBUG: Loaded current user ID: \(userId), isGuest: \(isGuest)")
            } else {
                print("🔍 DEBUG: Unable to get current user information")
            }
        }
    }
    
    func deleteGame(_ game: Game) {
        guard !isDeleting else { return }
        
        isDeleting = true
        
        Task {
            let success = await GameService.shared.deleteGame(game, currentUserId: currentUserId)
            
            await MainActor.run {
                isDeleting = false
                
                if success {
                    // Game deleted successfully - notify parent and dismiss the view
                    onGameDeleted?()
                    dismiss()
                } else {
                    // Show error message
                    deleteErrorMessage = "Failed to delete game. You may not have permission to delete this game."
                    showDeleteError = true
                }
            }
        }
    }
    
    func loadUsernamesFromCache() {
        Task {
            // Get all unique player IDs from all games (active and completed)
            let allPlayerIDs = Set(games.flatMap { $0.playerIDs })
            print("🔍 DEBUG: GameSelectionView - Loading usernames for \(allPlayerIDs.count) player IDs: \(Array(allPlayerIDs))")
            
            // Use the cache service to get usernames
            let usernames = await usernameCache.getUsernames(for: Array(allPlayerIDs))
            print("🔍 DEBUG: GameSelectionView - Retrieved usernames: \(usernames)")
        }
    }
}

struct GameCardView: View {
    let game: Game
    let usernameCache: UsernameCacheService
    let isSelected: Bool
    let isCreator: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Game header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(game.gameName?.isEmpty != false ? "Untitled Game" : (game.gameName ?? "Untitled Game"))
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if isCreator {
                            Text("Created by you")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .cornerRadius(4)
                        }
                        
                        // Game status indicator
                        Text(game.gameStatus == .active ? "Active" : "Completed")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(game.gameStatus == .active ? Color.green : Color.orange)
                            .cornerRadius(4)
                    }
                    
                    Text("\(game.rounds) Rounds")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                
                // Game code
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Code")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    Text(String(game.id.prefix(6)).uppercased())
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            
            // Players
            VStack(alignment: .leading, spacing: 4) {
                Text("Players:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                if usernameCache.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading players...")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    let playerList = game.playerIDs.map { playerID in
                        let displayName = usernameCache.getDisplayName(for: playerID)
                        print("🔍 DEBUG: GameCardView - Player ID: \(playerID) -> Display Name: \(displayName)")
                        return displayName
                    }
                    
                    Text(playerList.joined(separator: ", "))
                        .font(.body)
                        .foregroundColor(.white)
                        .lineLimit(2)
                }
            }
            
            // Action buttons
            HStack {
                Spacer()
                
                // Select button
                Button(action: onTap) {
                    HStack {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "arrow.right.circle")
                            .foregroundColor(.white)
                        Text(isSelected ? "Selected" : "Select Game")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isSelected ? Color.green : Color.blue)
                    .cornerRadius(8)
                }
                
                // Delete button (only for creators)
                if isCreator {
                    Button(action: onDelete) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.white)
                            Text("Delete")
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red)
                        .cornerRadius(8)
                    }
                    .padding(.leading, 8)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.green : Color.white.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
} 
