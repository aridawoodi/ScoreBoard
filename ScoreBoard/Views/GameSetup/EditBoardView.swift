//
//  EditBoardView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI
import Amplify

// Edit Board View
struct EditBoardView: View {
    let game: Game
    let onGameUpdated: (Game) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var players: [Player] = []
    @State private var rounds: Int
    @State private var customRules: String
    @State private var gameName: String
    @State private var newPlayerName = ""
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showDeleteAlert = false
    private let originalPlayerIDs: Set<String>
    
    // Add preview flag
    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    init(game: Game, onGameUpdated: @escaping (Game) -> Void) {
        self.game = game
        self.onGameUpdated = onGameUpdated
        self._rounds = State(initialValue: game.rounds)
        self._customRules = State(initialValue: game.customRules ?? "")
        self._gameName = State(initialValue: game.gameName ?? "")
        self.originalPlayerIDs = Set(game.playerIDs)
        
        // Initialize players from existing game - will be populated in onAppear
        self._players = State(initialValue: [])
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Game Settings
                    VStack(alignment: .leading, spacing: 12) {
                        
                        TextField("Enter game name", text: $gameName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Enter custom rules (optional)", text: $customRules)
                            .textFieldStyle(RoundedBorderTextFieldStyle())

                        Stepper("Number of Rounds: \(rounds)", value: $rounds, in: 1...10)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                    // Player Management
                    PlayerManagementView(
                        players: $players,
                        newPlayerName: $newPlayerName,
                        searchText: $searchText,
                        searchResults: $searchResults,
                        isSearching: $isSearching,
                        addPlayer: addPlayer,
                        searchUsers: searchUsers,
                        addRegisteredPlayer: addRegisteredPlayer,
                        removePlayer: removePlayer
                    )
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            updateGame()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Update Board")
                            }
                        }
                        .disabled(isLoading)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        
                        Button(action: {
                            showDeleteAlert = true
                        }) {
                            Text("Delete Board")
                        }
                        .disabled(isLoading)
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                        .controlSize(.large)
                    }
                }
                .padding()
            }
            .navigationTitle("Edit Board")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
            .alert("Board Update", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .alert("Delete Game", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteGame()
                }
            } message: {
                Text("Are you sure you want to delete this game? This action will permanently delete the game and all its scores. This action cannot be undone.")
            }
            .onAppear {
                // Ensure we have fresh data when the edit view appears
                print("🔍 DEBUG: EditBoardView appeared - refreshing data")
                loadPlayersFromGame()
            }
        }
    }

    
    func removePlayer(_ player: Player) {
        PlayerManagementFunctions.removePlayer(player, players: $players)
    }
    
    func addPlayer() {
        PlayerManagementFunctions.addPlayer(newPlayerName: $newPlayerName, players: $players)
    }
    
    func searchUsers(query: String) {
        PlayerManagementFunctions.searchUsers(query: query, searchResults: $searchResults, isSearching: $isSearching)
    }
    
    func addRegisteredPlayer(_ user: User) {
        PlayerManagementFunctions.addRegisteredPlayer(user, players: $players, searchText: $searchText, searchResults: $searchResults)
    }
    
    func deleteGame() {
        isLoading = true
        Task {
            do {
                // Use GameService to delete the game and all its scores
                let currentUser = try await Amplify.Auth.getCurrentUser()
                let success = await GameService.shared.deleteGame(game, currentUserId: currentUser.userId)
                
                await MainActor.run {
                    isLoading = false
                    if success {
                        // Game was successfully deleted, dismiss the view
                        dismiss()
                    } else {
                        // Show error message
                        alertMessage = "Failed to delete game. Only the game creator can delete the game."
                        showAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Error deleting game: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    func loadPlayersFromGame() {
        Task {
            do {
                // Get all users from the database to check which players are registered
                let usersResult = try await Amplify.API.query(request: .list(User.self))
                
                await MainActor.run {
                    switch usersResult {
                    case .success(let allUsers):
                        let userIDs = Set(allUsers.map { $0.id })
                        
                        // Process each playerID from the game
                        let processedPlayers: [Player] = game.playerIDs.compactMap { playerID in
                            if playerID.contains(":") {
                                // Anonymous user with format "userID:displayName"
                                let components = playerID.split(separator: ":", maxSplits: 1)
                                if components.count == 2 {
                                    let userId = String(components[0])
                                    let displayName = String(components[1])
                                    return Player(
                                        name: displayName,
                                        isRegistered: false,
                                        userId: userId,
                                        email: nil
                                    )
                                }
                                return nil
                            } else {
                                // Check if this userID exists in the User table
                                let isRegistered = userIDs.contains(playerID)
                                return Player(
                                    name: playerID, // Use playerID as name for now
                                    isRegistered: isRegistered,
                                    userId: playerID,
                                    email: nil
                                )
                            }
                        }
                        
                        self.players = processedPlayers
                        print("🔍 DEBUG: Loaded \(processedPlayers.count) players from game")
                        for player in processedPlayers {
                            print("🔍 DEBUG: Player - Name: \(player.name), Registered: \(player.isRegistered)")
                        }
                        
                    case .failure(let error):
                        print("🔍 DEBUG: Error loading users: \(error)")
                        // Fallback to basic processing without user verification
                        let fallbackPlayers: [Player] = game.playerIDs.compactMap { playerID in
                            if playerID.contains(":") {
                                let components = playerID.split(separator: ":", maxSplits: 1)
                                if components.count == 2 {
                                    let userId = String(components[0])
                                    let displayName = String(components[1])
                                    return Player(
                                        name: displayName,
                                        isRegistered: false,
                                        userId: userId,
                                        email: nil
                                    )
                                }
                                return nil
                            } else {
                                return Player(
                                    name: playerID,
                                    isRegistered: false, // Assume anonymous if we can't verify
                                    userId: playerID,
                                    email: nil
                                )
                            }
                        }
                        self.players = fallbackPlayers
                    }
                }
            } catch {
                print("🔍 DEBUG: Error in loadPlayersFromGame: \(error)")
            }
        }
    }
    
    func updateGame() {
        guard !players.isEmpty else {
            alertMessage = "Please keep at least one player."
            showAlert = true
            return
        }
        
        isLoading = true
        Task {
            do {
                // Convert players to proper player IDs format
                let playerIDs = players.map { player in
                    if player.isRegistered {
                        return player.userId ?? player.name
                    } else {
                        if let userId = player.userId {
                            return "\(userId):\(player.name)"
                        } else {
                            return player.name
                        }
                    }
                }
                
                let updatedGame = Game(
                    id: game.id,
                    gameName: gameName.isEmpty ? nil : gameName,
                    hostUserID: game.hostUserID,
                    playerIDs: playerIDs,
                    rounds: rounds,
                    customRules: customRules.isEmpty ? nil : customRules,
                    finalScores: game.finalScores,
                    gameStatus: game.gameStatus,
                    createdAt: game.createdAt,
                    updatedAt: Temporal.DateTime.now()
                )
                
                let result = try await Amplify.API.mutate(request: .update(updatedGame))
                switch result {
                case .success(let updatedGame):
                    // Identify removed players and delete their scores
                    let newIDs = Set(playerIDs)
                    let removedIDs = originalPlayerIDs.subtracting(newIDs)
                    if !removedIDs.isEmpty {
                        print("🔍 DEBUG: Detected removed players: \(Array(removedIDs)) - deleting their scores")
                        do {
                            // Use server-side filtering to only fetch scores for this game
                            let scoresQuery = Score.keys.gameID.eq(game.id)
                            let scoresResult = try await Amplify.API.query(request: .list(Score.self, where: scoresQuery))
                            switch scoresResult {
                            case .success(let gameScores):
                                // Since we're already filtering by gameID, we only need to filter by playerID
                                let scoresToDelete = gameScores.filter { removedIDs.contains($0.playerID) }
                                print("🔍 DEBUG: Will delete \(scoresToDelete.count) scores for removed players")
                                for score in scoresToDelete {
                                    let deleteResult = try await Amplify.API.mutate(request: .delete(score))
                                    switch deleteResult {
                                    case .success(_):
                                        print("🔍 DEBUG: Deleted score id=\(score.id) for player=\(score.playerID) round=\(score.roundNumber)")
                                    case .failure(let err):
                                        print("🔍 DEBUG: Failed to delete score id=\(score.id): \(err)")
                                    }
                                }
                            case .failure(let err):
                                print("🔍 DEBUG: Failed fetching scores for removal: \(err)")
                            }
                        } catch {
                            print("🔍 DEBUG: Error during score deletions for removed players: \(error)")
                        }
                    }
                    await MainActor.run {
                        isLoading = false
                        onGameUpdated(updatedGame)
                        dismiss()
                    }
                case .failure(let error):
                    await MainActor.run {
                        isLoading = false
                        alertMessage = "Failed to update board: \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}

// MARK: - Preview
struct EditBoardView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Create a sample game for preview
            let sampleGame = Game(
                id: "sample-game-id",
                gameName: "Sample Game",
                hostUserID: "host-user-id",
                playerIDs: ["player1", "player2"],
                rounds: 5,
                customRules: "Sample custom rules for preview",
                finalScores: [],
                gameStatus: .active,
                createdAt: Temporal.DateTime.now(),
                updatedAt: Temporal.DateTime.now()
            )
            
            // Wrap in NavigationStack for proper preview
            NavigationStack {
                EditBoardView(game: sampleGame) { updatedGame in
                    print("Preview: Game updated with ID: \(updatedGame.id)")
                }
            }
            .previewDisplayName("EditBoardView")
            .previewLayout(.sizeThatFits)
            .environment(\.colorScheme, .light) // Force light mode for consistent preview
            .previewDevice("iPhone 15 Pro") // Specify a specific device
        }
    }
}



