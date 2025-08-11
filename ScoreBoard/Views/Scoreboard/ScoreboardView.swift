//
//  ScoreboardView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/5/24.
//

// import SwiftUI
// import Amplify

// struct ScoreboardView: View {
//     @State var game: Game
//     let onBack: () -> Void
//     let onGameUpdated: ((Game) -> Void)?
    
//     init(game: Game, onBack: @escaping () -> Void, onGameUpdated: ((Game) -> Void)? = nil) {
//         self._game = State(initialValue: game)
//         self.onBack = onBack
//         self.onGameUpdated = onGameUpdated
//     }
    
//     @StateObject private var viewModel = ScoreboardViewModel()
//     @State private var playerNames: [String: String] = [:]
//     @State private var ownerUsername: String? = nil
//     @State private var showEditGame = false
//     @State private var showGameReview = false
//     @State private var currentRound = 1
//     @State private var isLoading = false
//     @State private var gameUpdated = false
//     @State private var currentUserID = ""
    
//     // Responsive sizing
//     @Environment(\.horizontalSizeClass) private var horizontalSizeClass
//     @Environment(\.verticalSizeClass) private var verticalSizeClass
    
//     private var isIPad: Bool {
//         horizontalSizeClass == .regular && verticalSizeClass == .regular
//     }
    
//     private var isLandscape: Bool {
//         horizontalSizeClass == .regular && verticalSizeClass == .compact
//     }
    
//     private var horizontalPadding: CGFloat {
//         isIPad ? 40 : 20
//     }
    
//     private var sectionSpacing: CGFloat {
//         isIPad ? 30 : 20
//     }
    
//     private var titleFont: Font {
//         isIPad ? .largeTitle : .title2
//     }
    
//     private var headlineFont: Font {
//         isIPad ? .title2 : .headline
//     }
    
//     private var bodyFont: Font {
//         isIPad ? .title3 : .body
//     }
    
//     private var captionFont: Font {
//         isIPad ? .body : .caption
//     }

//     var body: some View {
//         GeometryReader { geometry in
//             VStack(spacing: 0) {
//                 // Custom Navigation Header
//                 VStack(spacing: isIPad ? 12 : 8) {
//                     HStack {
//                         Spacer()
                        
//                         VStack(alignment: .trailing, spacing: 2) {
//                             Text("Game Code")
//                                 .font(isIPad ? .body : .caption2)
//                                 .foregroundColor(.secondary)
//                             Text(String(game.id.prefix(6)).uppercased())
//                                 .font(isIPad ? .title3.bold() : .caption.bold())
//                                 .foregroundColor(.green)
//                                 .padding(.horizontal, isIPad ? 12 : 6)
//                                 .padding(.vertical, isIPad ? 6 : 2)
//                                 .background(Color.green.opacity(0.1))
//                                 .cornerRadius(isIPad ? 8 : 4)
//                         }
//                     }
                    
//                     // Game Info
//                     VStack(spacing: isIPad ? 8 : 4) {
//                         Text("Scoreboard")
//                             .font(titleFont)
//                             .fontWeight(.bold)
                        
//                         HStack(spacing: isIPad ? 24 : 16) {
//                             Label("\(game.rounds) Rounds", systemImage: "number.circle")
//                                 .font(captionFont)
//                                 .foregroundColor(.secondary)
                            
//                             if let owner = ownerUsername {
//                                 Label("Host: \(owner)", systemImage: "person.circle")
//                                     .font(captionFont)
//                                     .foregroundColor(.secondary)
//                             }
//                         }
//                     }
//                 }
//                 .padding(isIPad ? 24 : 16)
//                 .background(Color(.systemBackground))
//                 .overlay(
//                     Rectangle()
//                         .frame(height: 1)
//                         .foregroundColor(Color(.systemGray4)),
//                     alignment: .bottom
//                 )
                
//                 // Main Content
//                 ScrollView {
//                     VStack(spacing: sectionSpacing) {
//                         // Player List with Scores
//                         VStack(alignment: .leading, spacing: isIPad ? 16 : 12) {
//                             HStack {
//                                 Text("Players & Scores")
//                                     .font(headlineFont)
//                                 Spacer()
//                                 Text("Round \(currentRound)")
//                                     .font(isIPad ? .title3 : .subheadline)
//                                     .foregroundColor(.secondary)
//                             }
                            
//                             // Player Score Table
//                             VStack(spacing: 0) {
//                                 // Header
//                                 HStack {
//                                     Text("Player")
//                                         .font(isIPad ? .title3 : .caption)
//                                         .fontWeight(.semibold)
//                                         .frame(maxWidth: .infinity, alignment: .leading)
                                    
//                                     Text("Score")
//                                         .font(isIPad ? .title3 : .caption)
//                                         .fontWeight(.semibold)
//                                         .frame(width: isIPad ? 120 : 80, alignment: .trailing)
//                                 }
//                                 .padding(.horizontal, isIPad ? 20 : 12)
//                                 .padding(.vertical, isIPad ? 16 : 12)
//                                 .background(Color(.systemGray6))
                                
//                                 // Player Rows
//                                 ForEach(game.playerIDs, id: \.self) { playerID in
//                                     ScoreRowView(
//                                         playerID: playerID,
//                                         playerName: playerNames[playerID] ?? "Unknown",
//                                         score: viewModel.getScoreForPlayer(playerID, round: currentRound),
//                                         onScoreChanged: { newScore in
//                                             viewModel.setScoreForPlayer(playerID, round: currentRound, score: newScore)
//                                         },
//                                         isIPad: isIPad
//                                     )
//                                 }
//                             }
//                             .background(Color(.systemBackground))
//                             .cornerRadius(isIPad ? 16 : 12)
//                             .shadow(color: Color.black.opacity(0.1), radius: isIPad ? 8 : 4, x: 0, y: 2)
//                         }
                        
//                         // Round Navigation
//                         VStack(spacing: isIPad ? 16 : 12) {
//                             HStack {
//                                 Button(action: {
//                                     if currentRound > 1 {
//                                         currentRound -= 1
//                                     }
//                                 }) {
//                                     Image(systemName: "chevron.left")
//                                         .font(.system(size: isIPad ? 20 : 16, weight: .semibold))
//                                         .foregroundColor(currentRound > 1 ? .blue : .gray)
//                                 }
//                                 .disabled(currentRound <= 1)
                                
//                                 Spacer()
                                
//                                 Text("Round \(currentRound) of \(game.rounds)")
//                                     .font(isIPad ? .title2 : .headline)
//                                     .fontWeight(.semibold)
                                
//                                 Spacer()
                                
//                                 Button(action: {
//                                     if currentRound < game.rounds {
//                                         currentRound += 1
//                                     }
//                                 }) {
//                                     Image(systemName: "chevron.right")
//                                         .font(.system(size: isIPad ? 20 : 16, weight: .semibold))
//                                         .foregroundColor(currentRound < game.rounds ? .blue : .gray)
//                                 }
//                                 .disabled(currentRound >= game.rounds)
//                             }
//                             .padding(isIPad ? 20 : 16)
//                             .background(Color(.systemGray6))
//                             .cornerRadius(isIPad ? 16 : 12)
//                         }
                        
//                         // Action Buttons
//                         VStack(spacing: isIPad ? 16 : 12) {
//                             HStack(spacing: isIPad ? 20 : 12) {
//                                 Button(action: {
//                                     showEditGame = true
//                                 }) {
//                                     HStack {
//                                         Image(systemName: "pencil")
//                                             .font(.system(size: isIPad ? 20 : 16))
//                                         Text("Edit Game")
//                                             .fontWeight(.semibold)
//                                     }
//                                     .frame(maxWidth: .infinity)
//                                     .padding(isIPad ? 16 : 12)
//                                     .background(canUserEditGame() ? Color.blue : Color.gray)
//                                     .foregroundColor(.white)
//                                     .cornerRadius(isIPad ? 12 : 8)
//                                 }
//                                 .disabled(!canUserEditGame())
                                
//                                 Button(action: {
//                                     showGameReview = true
//                                 }) {
//                                     HStack {
//                                         Image(systemName: "chart.bar.fill")
//                                             .font(.system(size: isIPad ? 20 : 16))
//                                         Text("Game Review")
//                                             .fontWeight(.semibold)
//                                     }
//                                     .frame(maxWidth: .infinity)
//                                     .padding(isIPad ? 16 : 12)
//                                     .background(Color.green)
//                                     .foregroundColor(.white)
//                                     .cornerRadius(isIPad ? 12 : 8)
//                                 }
//                             }
                            
//                             Button(action: {
//                                 onBack()
//                             }) {
//                                 HStack {
//                                     Image(systemName: "arrow.left")
//                                         .font(.system(size: isIPad ? 20 : 16))
//                                     Text("Back to Games")
//                                         .fontWeight(.semibold)
//                                 }
//                                 .frame(maxWidth: .infinity)
//                                 .padding(isIPad ? 16 : 12)
//                                 .background(Color.gray)
//                                 .foregroundColor(.white)
//                                 .cornerRadius(isIPad ? 12 : 8)
//                             }
//                         }
//                     }
//                     .padding(.horizontal, horizontalPadding)
//                     .padding(.vertical, isIPad ? 24 : 16)
//                     .frame(maxWidth: isIPad ? 800 : .infinity)
//                 }
//             }
//             .navigationBarHidden(true)
//             .sheet(isPresented: $showEditGame) {
//                 EditGameView(game: game) { updatedGame in
//                     game = updatedGame
//                     onGameUpdated?(updatedGame)
//                 }
//             }
//             .sheet(isPresented: $showGameReview) {
//                 // Convert Game to GameDetails
//                 let rounds = (1...game.rounds).map { roundNumber in
//                     Round(
//                         id: roundNumber,
//                         number: roundNumber,
//                         scores: game.playerIDs.enumerated().map { index, playerID in
//                             let scoreValue = index < game.finalScores.count ? 
//                                 Int(game.finalScores[index]) ?? 0 : 0
//                             return PlayerScore(
//                                 id: "\(playerID)_round_\(roundNumber)",
//                                 playerName: playerNames[playerID] ?? "Unknown",
//                                 value: scoreValue
//                             )
//                         }
//                     )
//                 }
                
//                 GameReviewView(gameDetails: GameDetails(rounds: rounds))
//             }
//             .onAppear {
//                 loadPlayerNames()
//                 loadOwnerUsername()
//                 loadCurrentUser()
//             }
//         }
//     }
    
//     func loadPlayerNames() {
//         loadPlayerNamesForGame(game)
//     }
    
//     func loadPlayerNamesForGame(_ gameToLoad: Game) {
//         Task {
//             print("🔍 DEBUG: ===== LOAD PLAYER NAMES START =====")
//             print("🔍 DEBUG: Loading player names for game: \(gameToLoad.id)")
//             print("🔍 DEBUG: Player IDs: \(gameToLoad.playerIDs)")
//             print("🔍 DEBUG: Game rounds: \(gameToLoad.rounds)")
            
//             // First, try to fetch all users to see what's available
//             let allUsers = await AmplifyService.fetchAllUsers()
//             print("🔍 DEBUG: Available users in database: \(allUsers.map { "\($0.username) (ID: \($0.id))" })")
            
//             var names: [String: String] = [:]
            
//             // Process player IDs to extract display names
//             for playerID in gameToLoad.playerIDs {
//                 print("🔍 DEBUG: Processing player ID: \(playerID)")
                
//                 if playerID.contains(":") {
//                     // Anonymous user with format "userID:displayName"
//                     let components = playerID.split(separator: ":", maxSplits: 1)
//                     if components.count == 2 {
//                         let displayName = String(components[1])
//                         names[playerID] = displayName
//                         print("🔍 DEBUG: Anonymous user - using display name: \(displayName)")
//                     }
//                 } else {
//                     // Try to find matching user by ID first
//                     if let user = allUsers.first(where: { $0.id == playerID }) {
//                         names[playerID] = user.username
//                         print("🔍 DEBUG: Found registered user by ID - using username: \(user.username)")
//                     } else {
//                         // Try to find by partial ID match (for cases where IDs don't match exactly)
//                         let shortID = String(playerID.prefix(8))
//                         if let user = allUsers.first(where: { $0.id.hasPrefix(shortID) || shortID.hasPrefix($0.id.prefix(8)) }) {
//                             names[playerID] = user.username
//                             print("🔍 DEBUG: Found user by partial ID match - using username: \(user.username)")
//                         } else {
//                             // Try to use UserService to get user by AuthUserId
//                             let userService = UserService.shared
//                             if let user = await userService.getUserByAuthUserId(playerID) {
//                                 names[playerID] = user.username
//                                 print("🔍 DEBUG: Found user via UserService - using username: \(user.username)")
//                             } else {
//                                 // NEW: Try to find user by email if the playerID looks like an AuthUser ID
//                                 // This is the key fix for the ID mismatch issue
//                                 if playerID.contains("-") && playerID.count > 20 {
//                                     // This looks like an AuthUser ID, try to find user by email
//                                     print("🔍 DEBUG: PlayerID looks like AuthUser ID, trying email matching...")
                                    
//                                     // Get current user's email to match against
//                                     do {
//                                         _ = try await Amplify.Auth.getCurrentUser()
//                                         let attributes = try await Amplify.Auth.fetchUserAttributes()
//                                         let currentUserEmail = attributes.first(where: { $0.key.rawValue == "email" })?.value ?? ""
                                        
//                                         if !currentUserEmail.isEmpty {
//                                             // Look for user with matching email
//                                             if let userByEmail = allUsers.first(where: { $0.email == currentUserEmail }) {
//                                                 names[playerID] = userByEmail.username
//                                                 print("🔍 DEBUG: Found user by email matching - using username: \(userByEmail.username)")
//                                             } else {
//                                                 // Fallback to short ID
//                                                 names[playerID] = shortID
//                                                 print("🔍 DEBUG: No user found by email - using short ID: \(shortID)")
//                                             }
//                                         } else {
//                                             // Fallback to short ID
//                                             names[playerID] = shortID
//                                             print("🔍 DEBUG: No email available - using short ID: \(shortID)")
//                                         }
//                                     } catch {
//                                         // Fallback to short ID
//                                         names[playerID] = shortID
//                                         print("🔍 DEBUG: Error getting user email - using short ID: \(shortID)")
//                                     }
//                                 } else {
//                                     // Fallback to short ID
//                                     names[playerID] = shortID
//                                     print("🔍 DEBUG: No user found - using short ID: \(shortID)")
//                                 }
//                             }
//                         }
//                     }
//                 }
//             }
            
//             print("🔍 DEBUG: Final player names: \(names)")
            
//             // Extract owner ID for lookup
//             if let ownerField = gameToLoad.owner {
//                 let ownerID = ownerField
//                 print("🔍 DEBUG: Extracted ownerID for lookup: \(ownerID) from owner field: \(ownerField)")

//                 // Look up owner username using UserService
//                 let userService = UserService.shared
//                 let ownerUser = await userService.getUserByAuthUserId(ownerID)
//                 print("🔍 DEBUG: getUserByAuthUserId returned: \(ownerUser?.username ?? "nil")")

//                 await MainActor.run {
//                     self.ownerUsername = ownerUser?.username
//                     print("🔍 DEBUG: Setting ownerUsername to: \(self.ownerUsername ?? "nil")")
//                 }
//             }
            
//             await MainActor.run {
//                 self.playerNames = names
//                 print("🔍 DEBUG: ===== LOAD PLAYER NAMES END =====")
//                 print("🔍 DEBUG: Final player names set: \(self.playerNames)")
//             }
//         }
//     }
    
//     func loadOwnerUsername() {
//         Task {
//             if let ownerField = game.owner {
//                 let userService = UserService.shared
//                 let ownerUser = await userService.getUserByAuthUserId(ownerField)
//                 await MainActor.run {
//                     self.ownerUsername = ownerUser?.username
//                 }
//             }
//         }
//     }
    
//     func loadCurrentUser() {
//         Task {
//             // Get current user info using helper function that works for both guest and authenticated users
//             if let currentUserInfo = await getCurrentUser() {
//                 let userId = currentUserInfo.userId
//                 await MainActor.run {
//                     self.currentUserID = userId
//                 }
//                 print("🔍 DEBUG: Loaded current user ID: \(userId)")
//             } else {
//                 print("🔍 DEBUG: Unable to get current user information")
//             }
//         }
//     }
    
//     func convertGameToGameDetails(_ game: Game) -> GameDetails {
//         // Convert Game to GameDetails
//         // For now, create a simple conversion with sample data
//         // In a real implementation, you would fetch the actual scores from the database
        
//         let rounds = (1...game.rounds).map { roundNumber in
//             Round(
//                 id: roundNumber,
//                 number: roundNumber,
//                 scores: game.playerIDs.enumerated().map { index, playerID in
//                     let playerName = playerNames[playerID] ?? playerID
//                     // For now, use placeholder scores - in a real app you'd fetch actual scores
//                     let score = (roundNumber * 10) + (index * 5) // Placeholder scoring
//                     return PlayerScore(
//                         id: "\(playerID)_\(roundNumber)",
//                         playerName: playerName,
//                         value: score
//                     )
//                 }
//             )
//         }
        
//         return GameDetails(rounds: rounds)
//     }
    
//     func refreshGameData() async {
//         do {
//             print("🔍 DEBUG: ===== REFRESHING GAME DATA FROM DATABASE =====")
//             let result = try await Amplify.API.query(request: .get(Game.self, byId: game.id))
            
//             switch result {
//             case .success(let updatedGame):
//                 if let updatedGame = updatedGame {
//                     print("🔍 DEBUG: Fetched updated game from database")
//                     print("🔍 DEBUG: Old game rounds: \(game.rounds)")
//                     print("🔍 DEBUG: New game rounds: \(updatedGame.rounds)")
//                     print("🔍 DEBUG: Old game playerIDs: \(game.playerIDs)")
//                     print("🔍 DEBUG: New game playerIDs: \(updatedGame.playerIDs)")
                    
//                     await MainActor.run {
//                         // Update the local game state with the latest data
//                         self.game = updatedGame
//                     }
                    
//                     print("🔍 DEBUG: Game data refreshed successfully")
//                 } else {
//                     print("🔍 DEBUG: Game not found in database")
//                 }
//             case .failure(let error):
//                 print("🔍 DEBUG: Error fetching game for refresh: \(error)")
//             }
//         } catch {
//             print("🔍 DEBUG: Exception refreshing game data: \(error)")
//         }
//     }
    
//     func canUserEditGame() -> Bool {
//         // Only the game creator (host) can edit the game
//         guard !currentUserID.isEmpty else { return false }
//         return game.hostUserID == currentUserID
//     }
// }
