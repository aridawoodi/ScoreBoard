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
    @ObservedObject var navigationState: NavigationState
    let onGameSelected: (Game) -> Void
    let onGameDeleted: ((Game) -> Void)?
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
    
    // Edit mode state
    @State private var isEditMode = false
    @State private var selectedGames: Set<String> = []
    @State private var showMultiDeleteConfirmation = false
    @State private var gamesToDelete: [Game] = []
    @State private var refreshTrigger = 0 // Force UI refresh when games are deleted
    
    // Filter games by selected status
    var filteredGames: [Game] {
        navigationState.userGames.filter { $0.gameStatus == selectedGameStatus }
    }
    
    // Count games by status
    var activeGameCount: Int {
        navigationState.userGames.filter { $0.gameStatus == .active }.count
    }
    
    var completedGameCount: Int {
        navigationState.userGames.filter { $0.gameStatus == .completed }.count
    }
    
    // Edit mode computed properties - works for both Active and Completed segments
    var deletableGames: [Game] {
        filteredGames.filter { GameService.shared.isGameCreator($0, currentUserId: currentUserId) }
    }
    
    var selectedGamesCount: Int {
        selectedGames.count
    }
    
    var isAllSelected: Bool {
        !deletableGames.isEmpty && selectedGames.count == deletableGames.count
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    HStack {
                        Spacer()
                        
                        if isEditMode {
                            Button("Done") {
                                exitEditMode()
                            }
                            .foregroundColor(.white)
                            .font(.body)
                        } else {
                            Button("Cancel") {
                                dismiss()
                            }
                            .foregroundColor(.white)
                            .font(.body)
                        }
                    }
                    .padding(.horizontal)
                    
                    Text(isEditMode ? "Select \(selectedGameStatus == .active ? "active" : "completed") games to delete" : "Choose which game you'd like to view")
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
                    
                    // Edit button (only show if there are deletable games for current segment)
                    if !isEditMode && !deletableGames.isEmpty {
                        HStack {
                            Spacer()
                            Button(action: {
                                enterEditMode()
                            }) {
                                Image(systemName: "pencil")
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.bottom, 10)
                
                // Game List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(isEditMode ? deletableGames : filteredGames, id: \.id) { game in
                            if isEditMode {
                                EditModeGameCardView(
                                    game: game,
                                    usernameCache: usernameCache,
                                    isSelected: selectedGames.contains(game.id),
                                    isCreator: GameService.shared.isGameCreator(game, currentUserId: currentUserId),
                                    onToggleSelection: {
                                        toggleGameSelection(game.id)
                                    }
                                )
                            } else {
                                GameCardView(
                                    game: game, 
                                    usernameCache: usernameCache,
                                    isSelected: selectedGame?.id == game.id,
                                    isCreator: GameService.shared.isGameCreator(game, currentUserId: currentUserId),
                                    onTap: {
                                        selectedGame = game
                                        if game.gameStatus == .completed {
                                            // Show ScoreboardView in readCompleted mode for completed games
                                            navigationState.showScoreboardForGame(game, mode: .readCompleted)
                                        } else {
                                            // Active games use existing logic
                                            onGameSelected(game)
                                            dismiss()
                                        }
                                    },
                                    onDelete: {
                                        gameToDelete = game
                                        showDeleteAlert = true
                                    }
                                )
                                .id("\(game.id)_\(refreshTrigger)") // Force refresh when games are deleted
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Multi-delete action bar (only in edit mode)
                if isEditMode {
                    MultiDeleteActionBar(
                        selectedCount: selectedGamesCount,
                        isAllSelected: isAllSelected,
                        onSelectAll: selectAllGames,
                        onDeselectAll: deselectAllGames,
                        onDeleteSelected: showDeleteConfirmation,
                        onCancel: exitEditMode
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                } else {
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .gradientBackground()
            .onAppear {
                loadUsernamesFromCache()
                loadCurrentUser()
            }
            .onChange(of: navigationState.userGames) { oldGames, newGames in
                print("🔍 DEBUG: GameSelectionView - Games updated! Old count: \(oldGames.count), New count: \(newGames.count)")
                print("🔍 DEBUG: GameSelectionView - New game IDs: \(newGames.map { $0.id })")
                // Reload usernames when games change
                loadUsernamesFromCache()
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
            .alert("Delete Games", isPresented: $showMultiDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteSelectedGames()
                }
            } message: {
                if selectedGamesCount == 1 {
                    Text("Are you sure you want to delete this game? This action cannot be undone.")
                } else {
                    Text("Are you sure you want to delete \(selectedGamesCount) games? This action cannot be undone.")
                }
            }
            .sheet(isPresented: $navigationState.showScoreboardView) {
                scoreboardSheetContent
            }
        }
    }
    
    // MARK: - Computed Properties
    
    @ViewBuilder
    private var scoreboardSheetContent: some View {
        if let game = navigationState.selectedGameForScoreboard {
            ScoreboardView(
                game: .constant(game),
                mode: navigationState.scoreboardMode,
                onGameUpdated: { _ in
                    // Game updated callback - no action needed for read-only mode
                },
                onGameDeleted: {
                    // Game deleted callback - dismiss the sheet
                    navigationState.showScoreboardView = false
                    navigationState.selectedGameForScoreboard = nil
                    navigationState.scoreboardMode = .edit
                },
                onKeyboardStateChanged: { _ in
                    // Keyboard state changed callback - no action needed
                }
            )
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
                    // Immediately remove from navigationState.userGames for instant UI update
                    let beforeCount = navigationState.userGames.count
                    navigationState.userGames.removeAll { $0.id == game.id }
                    let afterCount = navigationState.userGames.count
                    print("🔍 DEBUG: GameSelectionView - Immediately removed single game \(game.id) from UI. Count: \(beforeCount) → \(afterCount)")
                    
                    // Force UI refresh
                    refreshTrigger += 1
                    
                    // Game deleted successfully - notify parent and dismiss the view
                    onGameDeleted?(game)
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
            let allPlayerIDs = Set(navigationState.userGames.flatMap { $0.playerIDs })
            print("🔍 DEBUG: GameSelectionView - Loading usernames for \(allPlayerIDs.count) player IDs: \(Array(allPlayerIDs))")
            
            // Use the cache service to get usernames
            let usernames = await usernameCache.getUsernames(for: Array(allPlayerIDs))
            print("🔍 DEBUG: GameSelectionView - Retrieved usernames: \(usernames)")
        }
    }
    
    // MARK: - Edit Mode Functions
    
    func enterEditMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isEditMode = true
            selectedGames.removeAll()
            
            // Debug logging to verify only deletable games are shown
            print("🔍 DEBUG: GameSelectionView - Entering edit mode")
            print("🔍 DEBUG: GameSelectionView - Total games in current segment: \(filteredGames.count)")
            print("🔍 DEBUG: GameSelectionView - Deletable games: \(deletableGames.count)")
            print("🔍 DEBUG: GameSelectionView - Deletable game IDs: \(deletableGames.map { $0.id })")
            
            for game in deletableGames {
                let isCreator = GameService.shared.isGameCreator(game, currentUserId: currentUserId)
                print("🔍 DEBUG: GameSelectionView - Game \(game.id) isCreator: \(isCreator)")
            }
        }
    }
    
    func exitEditMode() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isEditMode = false
            selectedGames.removeAll()
        }
    }
    
    func toggleGameSelection(_ gameId: String) {
        print("🔍 DEBUG: GameSelectionView - toggleGameSelection called for game: \(gameId)")
        print("🔍 DEBUG: GameSelectionView - Current selectedGames before: \(selectedGames)")
        
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedGames.contains(gameId) {
                selectedGames.remove(gameId)
                print("🔍 DEBUG: GameSelectionView - Deselected game: \(gameId)")
            } else {
                selectedGames.insert(gameId)
                print("🔍 DEBUG: GameSelectionView - Selected game: \(gameId)")
            }
        }
        
        print("🔍 DEBUG: GameSelectionView - Current selectedGames after: \(selectedGames)")
    }
    
    func selectAllGames() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedGames = Set(deletableGames.map { $0.id })
        }
    }
    
    func deselectAllGames() {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedGames.removeAll()
        }
    }
    
    func showDeleteConfirmation() {
        gamesToDelete = deletableGames.filter { selectedGames.contains($0.id) }
        showMultiDeleteConfirmation = true
    }
    
    func deleteSelectedGames() {
        guard !gamesToDelete.isEmpty else { return }
        
        isDeleting = true
        
        Task {
            var successCount = 0
            var failedGames: [String] = []
            
            for game in gamesToDelete {
                let success = await GameService.shared.deleteGame(game, currentUserId: currentUserId)
                if success {
                    successCount += 1
                    // Immediately remove from navigationState.userGames for instant UI update
                    await MainActor.run {
                        let beforeCount = navigationState.userGames.count
                        navigationState.userGames.removeAll { $0.id == game.id }
                        let afterCount = navigationState.userGames.count
                        print("🔍 DEBUG: GameSelectionView - Immediately removed game \(game.id) from UI. Count: \(beforeCount) → \(afterCount)")
                        
                        // Force UI refresh
                        refreshTrigger += 1
                        
                        // Notify parent of successful deletion (for backend sync)
                        onGameDeleted?(game)
                    }
                } else {
                    failedGames.append(game.gameName ?? "Untitled Game")
                }
            }
            
            await MainActor.run {
                isDeleting = false
                
                if successCount > 0 {
                    // Clear selections and exit edit mode
                    selectedGames.removeAll()
                    isEditMode = false
                    
                    // Notify parent of successful deletions (for backend sync)
                    // Note: Individual game deletions are already handled in the loop above
                    // This is just for cleanup, the reactive system will handle the updates
                }
                
                if !failedGames.isEmpty {
                    deleteErrorMessage = "Failed to delete \(failedGames.count) game(s): \(failedGames.joined(separator: ", "))"
                    showDeleteError = true
                }
            }
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
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Game icon - Animated Logo
                AppLogoIcon(isSelected: isSelected, size: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(game.gameName?.isEmpty != false ? "Untitled Game" : (game.gameName ?? "Untitled Game"))
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        // Creator indicator
                        if isCreator {
                            Text("Created by you")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.blue)
                                .cornerRadius(3)
                        }
                        
                        // Game status indicator
                        Text(game.gameStatus == .active ? "Active" : "Completed")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(game.gameStatus == .active ? Color.green : Color.orange)
                            .cornerRadius(3)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(game.playerIDs.count) players • \(game.rounds) rounds")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        if !usernameCache.isLoading {
                            let playerList = game.playerIDs.map { playerID in
                                let displayName = usernameCache.getDisplayName(for: playerID)
                                print("🔍 DEBUG: GameCardView - Player ID: \(playerID) -> Display Name: \(displayName)")
                                return displayName
                            }
                            
                            Text(playerList.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color("LightGreen"))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color("LightGreen").opacity(0.2) : Color.black.opacity(0.3))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            Task {
                await usernameCache.getUsernames(for: game.playerIDs)
            }
        }
        .contextMenu {
            // Delete option for creators (long press)
            if isCreator {
                Button(action: onDelete) {
                    Label("Delete Game", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Edit Mode Game Card View
struct EditModeGameCardView: View {
    let game: Game
    let usernameCache: UsernameCacheService
    let isSelected: Bool
    let isCreator: Bool
    let onToggleSelection: () -> Void
    
    var body: some View {
        Button(action: {
            print("🔍 DEBUG: EditModeGameCardView - Button tapped for game: \(game.id)")
            onToggleSelection()
        }) {
            HStack(spacing: 12) {
                // Selection checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Color("LightGreen") : .white.opacity(0.6))
                    .font(.title2)
                    .background(
                        Circle()
                            .fill(isSelected ? Color("LightGreen").opacity(0.2) : Color.clear)
                            .frame(width: 32, height: 32)
                    )
                
                // Game icon - Animated Logo
                AppLogoIcon(isSelected: isSelected, size: 20)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(game.gameName?.isEmpty != false ? "Untitled Game" : (game.gameName ?? "Untitled Game"))
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        // Creator indicator
                        if isCreator {
                            Text("Created by you")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.blue)
                                .cornerRadius(3)
                        }
                        
                        // Game status indicator
                        Text(game.gameStatus == .active ? "Active" : "Completed")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(game.gameStatus == .active ? Color.green : Color.orange)
                            .cornerRadius(3)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(game.playerIDs.count) players • \(game.rounds) rounds")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        if !usernameCache.isLoading {
                            let playerList = game.playerIDs.map { playerID in
                                usernameCache.getDisplayName(for: playerID)
                            }
                            
                            Text(playerList.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color("LightGreen").opacity(0.2) : Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color("LightGreen") : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle()) // Ensure entire area is tappable
        .onAppear {
            Task {
                await usernameCache.getUsernames(for: game.playerIDs)
            }
        }
    }
}

// MARK: - Multi Delete Action Bar
struct MultiDeleteActionBar: View {
    let selectedCount: Int
    let isAllSelected: Bool
    let onSelectAll: () -> Void
    let onDeselectAll: () -> Void
    let onDeleteSelected: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Select All / Deselect All button
            Button(action: isAllSelected ? onDeselectAll : onSelectAll) {
                Text(isAllSelected ? "Deselect All" : "Select All")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(6)
            }
            
            Spacer()
            
            // Delete Selected button
            Button(action: onDeleteSelected) {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                        .font(.caption)
                    Text("Delete (\(selectedCount))")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selectedCount > 0 ? Color.red : Color.gray)
                .cornerRadius(6)
            }
            .disabled(selectedCount == 0)
            
            // Cancel button
            Button(action: onCancel) {
                Text("Cancel")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray)
                    .cornerRadius(6)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
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
