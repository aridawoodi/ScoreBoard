//
//  EditGameView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/5/24.
//

// import Foundation
// import SwiftUI
// import Amplify

// struct EditGameView: View {
//     let game: Game
//     private let originalPlayerIDs: Set<String>
//     @State private var players: [Player] = []
//     @State private var newPlayerName: String = ""
//     @State private var searchText: String = ""
//     @State private var searchResults: [User] = []
//     @State private var isSearching = false
//     @State private var searchDebounceTimer: Timer?
//     @State private var cachedSearchResults: [String: [User]] = [:]
//     @State private var rounds: Int
//     @State private var customRules: String
//     @State private var isLoading = false
//     @State private var showAlert = false
//     @State private var alertMessage = ""
//     @Environment(\.dismiss) private var dismiss
//     let onGameUpdated: (Game) -> Void
    
//     init(game: Game, onGameUpdated: @escaping (Game) -> Void) {
//         self.game = game
//         self.onGameUpdated = onGameUpdated
//         self.originalPlayerIDs = Set(game.playerIDs)
//         self._rounds = State(initialValue: game.rounds)
//         self._customRules = State(initialValue: game.customRules ?? "")
        
//         // Initialize players from existing game
//         let initialPlayers: [Player] = game.playerIDs.compactMap { playerID in
//             if playerID.contains(":") {
//                 // Anonymous user with format "userID:displayName"
//                 let components = playerID.split(separator: ":", maxSplits: 1)
//                 if components.count == 2 {
//                     let displayName = String(components[1])
//                     return Player(
//                         name: displayName,
//                         isRegistered: false,
//                         userId: String(components[0]),
//                         email: nil
//                     )
//                 }
//             }
//             // Registered user or fallback
//             return Player(
//                 name: playerID,
//                 isRegistered: true,
//                 userId: playerID,
//                 email: nil
//             )
//         }
//         self._players = State(initialValue: initialPlayers)
//     }
    
//     var body: some View {
//         NavigationView {
//             ScrollView {
//                 VStack(spacing: 20) {
//                     Text("Edit Game Settings")
//                         .font(.title)
//                         .fontWeight(.bold)

//                     // Game Settings
//                     VStack(alignment: .leading, spacing: 12) {
//                         Text("Game Settings").font(.headline)
                        
//                         TextField("Enter custom rules (optional)", text: $customRules)
//                             .textFieldStyle(RoundedBorderTextFieldStyle())

//                         Stepper("Number of Rounds: \(rounds)", value: $rounds, in: 1...10)
//                     }
//                     .padding()
//                     .background(Color(.systemGray6))
//                     .cornerRadius(10)

//                     // Player Management
//                     VStack(alignment: .leading, spacing: 12) {
//                         Text("Players (\(players.count))").font(.headline)
                        
//                         // Search for registered users
//                         VStack(alignment: .leading, spacing: 8) {
//                             Text("Search Registered Users").font(.subheadline)
//                                 .foregroundColor(.secondary)
                            
//                             HStack {
//                                 TextField("Search by username or email", text: $searchText)
//                                     .textFieldStyle(RoundedBorderTextFieldStyle())
//                                     .onChange(of: searchText) { _, newValue in
//                                         // Cancel previous timer
//                                         searchDebounceTimer?.invalidate()
                                        
//                                         if newValue.count >= 2 {
//                                             // Debounce the search with 0.5 second delay
//                                             searchDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
//                                                 searchUsers()
//                                             }
//                                         } else {
//                                             searchResults = []
//                                         }
//                                     }
                                
//                                 if isSearching {
//                                     ProgressView()
//                                         .scaleEffect(0.8)
//                                 }
//                             }
//                         }

//                         // Search results
//                         if !searchResults.isEmpty {
//                             VStack(alignment: .leading, spacing: 8) {
//                                 Text("Found Users:").font(.subheadline)
//                                     .foregroundColor(.secondary)
                                
//                                 ForEach(searchResults, id: \.id) { user in
//                                     HStack {
//                                         VStack(alignment: .leading, spacing: 2) {
//                                             Text(user.username)
//                                                 .font(.body)
//                                                 .fontWeight(.medium)
//                                             Text(user.email)
//                                                 .font(.caption)
//                                                 .foregroundColor(.secondary)
//                                         }
//                                         Spacer()
//                                         if players.contains(where: { $0.userId == user.id }) {
//                                             Image(systemName: "checkmark.circle.fill")
//                                                 .foregroundColor(.green)
//                                                 .font(.title2)
//                                         } else {
//                                             Button("Add") {
//                                                 addRegisteredUser(user)
//                                                 searchText = ""
//                                                 searchResults = []
//                                             }
//                                             .buttonStyle(.borderedProminent)
//                                             .controlSize(.small)
//                                         }
//                                     }
//                                     .padding(.horizontal, 12)
//                                     .padding(.vertical, 8)
//                                     .background(Color(.systemBackground))
//                                     .cornerRadius(8)
//                                     .overlay(
//                                         RoundedRectangle(cornerRadius: 8)
//                                             .stroke(Color(.systemGray4), lineWidth: 1)
//                                     )
//                                 }
//                             }
//                             .padding()
//                             .background(Color(.systemGray6))
//                             .cornerRadius(10)
//                         }
                        
//                         // Add anonymous player
//                         VStack(alignment: .leading, spacing: 8) {
//                             Text("Add Anonymous Player").font(.subheadline)
//                                 .foregroundColor(.secondary)
                            
//                             HStack {
//                                 TextField("Enter player name", text: $newPlayerName)
//                                     .textFieldStyle(RoundedBorderTextFieldStyle())
//                                     .onSubmit {
//                                         addAnonymousPlayer()
//                                     }
//                                 Button("Add") {
//                                     addAnonymousPlayer()
//                                 }
//                                 .buttonStyle(.borderedProminent)
//                                 .disabled(newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
//                             }
                            
//                             Text("For players without profiles")
//                                 .font(.caption)
//                                 .foregroundColor(.secondary)
//                         }
                        
//                         // Player List
//                         if !players.isEmpty {
//                             VStack(spacing: 8) {
//                                 ForEach(players) { player in
//                                     HStack {
//                                         VStack(alignment: .leading, spacing: 2) {
//                                             Text(player.name)
//                                                 .font(.body)
//                                                 .fontWeight(.medium)
//                                             HStack {
//                                                 if player.isRegistered {
//                                                     Image(systemName: "person.circle.fill")
//                                                         .foregroundColor(.green)
//                                                     Text("Registered")
//                                                         .font(.caption)
//                                                         .foregroundColor(.green)
//                                                 } else {
//                                                     Image(systemName: "person.circle")
//                                                         .foregroundColor(.orange)
//                                                     Text("Anonymous")
//                                                         .font(.caption)
//                                                         .foregroundColor(.orange)
//                                                 }
//                                             }
//                                         }
//                                         Spacer()
//                                         Button(action: { removePlayer(player) }) {
//                                             Image(systemName: "minus.circle.fill")
//                                                 .foregroundColor(.red)
//                                                 .font(.title2)
//                                         }
//                                     }
//                                     .padding(.horizontal, 12)
//                                     .padding(.vertical, 8)
//                                     .background(Color(.systemBackground))
//                                     .cornerRadius(8)
//                                     .overlay(
//                                         RoundedRectangle(cornerRadius: 8)
//                                             .stroke(Color(.systemGray4), lineWidth: 1)
//                                     )
//                                 }
//                             }
//                         } else {
//                             Text("No players added yet")
//                                 .font(.caption)
//                                 .foregroundColor(.secondary)
//                                 .padding()
//                         }
//                     }
//                     .padding()
//                     .background(Color(.systemGray6))
//                     .cornerRadius(10)
                    
//                     // Quick Add Buttons
//                     VStack(alignment: .leading, spacing: 8) {
//                         Text("Quick Add Anonymous").font(.subheadline)
//                             .foregroundColor(.secondary)
                        
//                         LazyVGrid(columns: [
//                             GridItem(.flexible()),
//                             GridItem(.flexible())
//                         ], spacing: 8) {
//                             ForEach(["Player 1", "Player 2", "Player 3", "Player 4"], id: \.self) { name in
//                                 Button(name) {
//                                     addQuickPlayer(name)
//                                 }
//                                 .buttonStyle(.bordered)
//                                 .disabled(players.contains { $0.name == name })
//                             }
//                         }
//                     }
//                     .padding()
//                     .background(Color(.systemGray6))
//                     .cornerRadius(10)
                    
//                     VStack(spacing: 12) {
//                         Button(action: {
//                             updateGame()
//                         }) {
//                             if isLoading {
//                                 ProgressView()
//                                     .progressViewStyle(CircularProgressViewStyle(tint: .white))
//                             } else {
//                                 Text("Update Game")
//                             }
//                         }
//                         .disabled(isLoading || players.isEmpty)
//                         .buttonStyle(.borderedProminent)
//                         .controlSize(.large)
                        
//                         Button(action: {
//                             dismiss()
//                         }) {
//                             HStack(spacing: 8) {
//                                 Image(systemName: "house.fill")
//                                 Text("Back to Main Menu")
//                             }
//                         }
//                         .buttonStyle(.bordered)
//                         .controlSize(.large)
//                     }
//                 }
//                 .padding()
//             }
//             .navigationTitle("Edit Game")
//             .navigationBarTitleDisplayMode(.inline)
//             .navigationBarItems(
//                 leading: Button("Cancel") {
//                     dismiss()
//                 },
//                 trailing: Button("Main Menu") {
//                     dismiss()
//                 }
//             )
//             .alert("Game Update", isPresented: $showAlert) {
//                 Button("OK") { }
//             } message: {
//                 Text(alertMessage)
//             }
//         }
//     }
    
//     func addAnonymousPlayer() {
//         let trimmed = newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
//         guard !trimmed.isEmpty else { return }
        
//         if !players.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) {
//             let player = Player(
//                 name: trimmed,
//                 isRegistered: false,
//                 userId: nil,
//                 email: nil
//             )
//             players.append(player)
//             newPlayerName = ""
//         }
//     }
    
//     func addRegisteredUser(_ user: User) {
//         if !players.contains(where: { $0.userId == user.id }) {
//             let player = Player(
//                 name: user.username,
//                 isRegistered: true,
//                 userId: user.id,
//                 email: user.email
//             )
//             players.append(player)
//         }
//     }
    
//     func addQuickPlayer(_ name: String) {
//         if !players.contains(where: { $0.name == name }) {
//             let player = Player(
//                 name: name,
//                 isRegistered: false,
//                 userId: nil,
//                 email: nil
//             )
//             players.append(player)
//         }
//     }
    
//     func removePlayer(_ player: Player) {
//         players.removeAll { $0.id == player.id }
//     }
    
//     func searchUsers() {
//         guard searchText.count >= 2 else { return }
        
//         // Check cache first
//         if let cachedResults = cachedSearchResults[searchText] {
//             print("🔍 DEBUG: Using cached search results for '\(searchText)'")
//             searchResults = cachedResults
//             return
//         }
        
//         isSearching = true
//         Task {
//             let results = await AmplifyService.searchUsersByName(query: searchText)
//             await MainActor.run {
//                 // Cache the results
//                 self.cachedSearchResults[searchText] = results
//                 self.searchResults = results
//                 self.isSearching = false
//                 print("🔍 DEBUG: Cached search results for '\(searchText)' - found \(results.count) users")
//             }
//         }
//     }

//     func updateGame() {
//         guard !players.isEmpty else {
//             alertMessage = "Please add at least one player."
//             showAlert = true
//             return
//         }
//         isLoading = true
//         Task {
//             do {
//                 // Convert players to proper player IDs format
//                 let playerIDs = players.map { player in
//                     if player.isRegistered {
//                         // Registered user - use their user ID
//                         return player.userId ?? player.name
//                     } else {
//                         // Anonymous user - use format "userID:displayName" if we have userID
//                         if let userId = player.userId {
//                             return "\(userId):\(player.name)"
//                         } else {
//                             // Fallback for anonymous users without userID
//                             return player.name
//                         }
//                     }
//                 }
                
//                 let updatedGame = Game(
//                     id: game.id,
//                     hostUserID: game.hostUserID,
//                     playerIDs: playerIDs,
//                     rounds: rounds,
//                     customRules: customRules.isEmpty ? nil : customRules,
//                     finalScores: game.finalScores,
//                     gameStatus: game.gameStatus,
//                     createdAt: game.createdAt,
//                     updatedAt: Temporal.DateTime.now()
//                 )
//                 let result = try await Amplify.API.mutate(request: .update(updatedGame))
                
//                 // Check if any players were removed and delete their scores
//                 let newPlayerIDs = Set(playerIDs)
//                 let removedPlayerIDs = originalPlayerIDs.subtracting(newPlayerIDs)
                
//                 if !removedPlayerIDs.isEmpty {
//                     print("🔍 DEBUG: Detected removed players: \(removedPlayerIDs) - deleting their scores")
                    
//                     // Fetch scores for this game only (server-side filtering)
//                     let scoresQuery = Score.keys.gameID.eq(game.id)
//                     let scoresResult = try await Amplify.API.query(request: .list(Score.self, where: scoresQuery))
                    
//                     switch scoresResult {
//                     case .success(let gameScores):
//                         // Since we're already filtering by gameID, we only need to filter by playerID
//                         let scoresToDelete = gameScores.filter { removedPlayerIDs.contains($0.playerID) }
//                         print("🔍 DEBUG: Will delete \(scoresToDelete.count) scores for removed players")
                        
//                         // Delete scores for removed players
//                         for score in scoresToDelete {
//                             do {
//                                 try await Amplify.API.mutate(request: .delete(score))
//                                 print("🔍 DEBUG: Deleted score id=\(score.id) for player=\(score.playerID) round=\(score.roundNumber)")
//                             } catch {
//                                 print("🔍 DEBUG: Failed to delete score \(score.id): \(error)")
//                             }
//                         }
//                     case .failure(let error):
//                         print("🔍 DEBUG: Failed fetching scores for removal: \(error)")
//                     }
//                 }
                
//                 await MainActor.run {
//                     isLoading = false
//                     switch result {
//                     case .success(let updatedGame):
//                         onGameUpdated(updatedGame)
//                         dismiss()
//                     case .failure(let error):
//                         alertMessage = "Failed to update game: \(error.localizedDescription)"
//                         showAlert = true
//                     }
//                 }
//             } catch {
//                 await MainActor.run {
//                     isLoading = false
//                     alertMessage = "Error: \(error.localizedDescription)"
//                     showAlert = true
//                 }
//             }
//         }
//     }
// }

// // MARK: - Preview
// struct EditGameView_Previews: PreviewProvider {
//     static var previews: some View {
//         // Create a sample game for preview
//         let sampleGame = Game(
//             id: "sample-game-id",
//             hostUserID: "host-user-id",
//             playerIDs: ["player1", "player2", "guest_123:Anonymous Player"],
//             rounds: 5,
//             customRules: "Sample custom rules for preview",
//             finalScores: [],
//             gameStatus: .active,
//             createdAt: Temporal.DateTime.now(),
//             updatedAt: Temporal.DateTime.now()
//         )
//         EditGameView(game: sampleGame) { updatedGame in
//             print("Preview: Game updated with ID: \(updatedGame.id)")
//         }
//     }
// } 