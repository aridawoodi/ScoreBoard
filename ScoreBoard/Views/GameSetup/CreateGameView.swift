//
//  CreateGameView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/5/24.
//

import SwiftUI
import Amplify

enum GameViewMode {
    case create
    case edit(Game)
}

struct CreateGameView: View {
    @Binding var showCreateGame: Bool
    let mode: GameViewMode
    let onGameCreated: (Game) -> Void
    let onGameUpdated: ((Game) -> Void)?
    
    @State private var gameName = ""
    @State private var rounds = 3
    @State private var hostJoinAsPlayer = true
    @State private var hostPlayerName = ""
    @State private var newPlayerName = ""
    @State private var searchText = ""
    @State private var players: [Player] = []
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showNoPlayersAlert = false
    @State private var currentUser: AuthUser?
    @State private var currentUserProfile: User?
    
    // Computed properties for mode-based behavior
    private var isEditMode: Bool {
        switch mode {
        case .create: return false
        case .edit: return true
        }
    }
    
    private var actionButtonText: String {
        switch mode {
        case .create: return "Create"
        case .edit: return "Update"
        }
    }
    
    private var navigationTitle: String {
        switch mode {
        case .create: return ""
        case .edit: return ""
        }
    }
    
    // Basic Settings

    @State private var useLastGameSettings = false
    
    // Advanced Settings
    @State private var showAdvancedSettingsSheet = false
    @State private var winCondition: WinCondition = .highestScore
    @State private var maxScore: Int = 100
    @State private var maxRounds: Int = 8
    
    // Custom Rules
    @State private var customRules: [CustomRule] = []
    @State private var newRuleLetter: String = ""
    @State private var newRuleValue: Int = 0
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var titleFont: Font {
        isIPad ? .title2 : .title3
    }
    
    private var bodyFont: Font {
        isIPad ? .title3 : .body
    }
    
    private var sectionSpacing: CGFloat {
        isIPad ? 24 : 16
    }
    
    var body: some View {
        GeometryReader { geometry in
            NavigationStack {
                ScrollView {
                CreateGameContentView(
                    gameName: $gameName,
                    customRules: $customRules,
                    rounds: $rounds,
                    hostJoinAsPlayer: $hostJoinAsPlayer,
                    hostPlayerName: $hostPlayerName,
                    newPlayerName: $newPlayerName,
                    searchText: $searchText,
                    players: $players,
                    searchResults: $searchResults,
                    isSearching: $isSearching,
                    currentUser: $currentUser,
                    currentUserProfile: $currentUserProfile,
    
                    useLastGameSettings: $useLastGameSettings,
                    showAdvancedSettingsSheet: $showAdvancedSettingsSheet,
                    winCondition: $winCondition,
                    maxScore: $maxScore,
                    maxRounds: $maxRounds,
                    newRuleLetter: $newRuleLetter,
                    newRuleValue: $newRuleValue,
                    isIPad: isIPad,
                    titleFont: titleFont,
                    bodyFont: bodyFont,
                    sectionSpacing: sectionSpacing,
                    addPlayer: addPlayer,
                    searchUsers: searchUsers,
                    addRegisteredPlayer: addRegisteredPlayer,
                    removePlayer: removePlayer,
                    loadLastGameSettings: loadLastGameSettings,
                    addCustomRule: addCustomRule
                )
                .padding(.bottom, 100) // Add bottom padding to avoid floating tab bar
            }
            .navigationTitle(navigationTitle)
            .gradientBackground()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        clearForm()
                        showCreateGame = false
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(actionButtonText) {
                        print("🔍 DEBUG: Create button tapped")
                        print("🔍 DEBUG: Players count: \(players.count)")
                        print("🔍 DEBUG: Is loading: \(isLoading)")
                        
                        let totalPlayers = getTotalPlayerCount()
                        print("🔍 DEBUG: Total players count: \(totalPlayers) (manual players: \(players.count), host joining: \(hostJoinAsPlayer))")
                        if totalPlayers < 2 {
                            showNoPlayersAlert = true
                        } else if !isLoading {
                            if isEditMode {
                                updateGame()
                            } else {
                                createGame()
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .disabled(isLoading)
                }
            }
        }
            .alert("Error", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .alert("Add Players First", isPresented: $showNoPlayersAlert) {
                Button("OK") { }
            } message: {
                Text("Please add at least two players to the game before creating it.")
            }
            .sheet(isPresented: $showAdvancedSettingsSheet) {
                AdvancedSettingsSheet(
                    winCondition: $winCondition,
                    maxScore: $maxScore,
                    maxRounds: $maxRounds,
                    customRules: $customRules,
                    newRuleLetter: $newRuleLetter,
                    newRuleValue: $newRuleValue,
                    addCustomRule: addCustomRule
                )
            }

            .onAppear {
                print("🔍 DEBUG: CreateGameView onAppear - Mode: \(isEditMode ? "edit" : "create")")
                print("🔍 DEBUG: CreateGameView onAppear - currentUserProfile: \(currentUserProfile?.username ?? "nil")")
                print("🔍 DEBUG: CreateGameView onAppear - currentUser: \(currentUser?.userId ?? "nil")")
                
                // Delay all asynchronous operations to allow sheet presentation animation to complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    print("🔍 DEBUG: CreateGameView delayed operations starting...")
                    loadCurrentUser()
                    if isEditMode {
                        loadGameDataForEdit()
                    }
                }
            }
            .onDisappear {
                print("🔍 DEBUG: CreateGameView onDisappear - Mode: \(isEditMode ? "edit" : "create")")
            }
        }
    }
    
    private func clearForm() {
        gameName = ""
        customRules = []
        rounds = 3
        hostJoinAsPlayer = true
        hostPlayerName = ""
        newPlayerName = ""
        searchText = ""
        players = []
        searchResults = []
        isSearching = false
        isLoading = false
        showAlert = false
        alertMessage = ""
        showNoPlayersAlert = false
        
        // Reset Basic Settings

        useLastGameSettings = false
        
        // Reset Advanced Settings
        showAdvancedSettingsSheet = false
        winCondition = .highestScore
        maxScore = 100
        maxRounds = 8
    }
    
    private func getTotalPlayerCount() -> Int {
        var count = players.count
        
        // Add 1 if host is joining as player
        if hostJoinAsPlayer {
            count += 1
        }
        
        return count
    }
    
    private func loadCurrentUser() {
        print("🔍 DEBUG: loadCurrentUser() called")
        Task {
            do {
                // Check if we're in guest mode
                let isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
                print("🔍 DEBUG: loadCurrentUser() - isGuestUser: \(isGuestUser)")
                
                if isGuestUser {
                    // Handle guest user
                    let guestUserId = UserDefaults.standard.string(forKey: "current_guest_user_id") ?? ""
                    print("🔍 DEBUG: Loading guest user with ID: \(guestUserId)")
                    
                    // Create a mock AuthUser for guest
                    let guestUser = GuestUser(
                        userId: guestUserId,
                        username: "Guest User",
                        email: "guest@scoreboard.app"
                    )
                    
                    await MainActor.run {
                        print("🔍 DEBUG: Setting currentUser to guest user")
                        self.currentUser = guestUser
                    }
                    
                    // Try to fetch guest user profile
                    do {
                        print("🔍 DEBUG: Fetching guest user profile from API...")
                        let result = try await Amplify.API.query(request: .get(User.self, byId: guestUserId))
                        switch result {
                        case .success(let profile):
                            print("🔍 DEBUG: Successfully fetched guest user profile: \(profile?.username ?? "unknown")")
                            await MainActor.run {
                                self.currentUserProfile = profile
                                print("🔍 DEBUG: Updated currentUserProfile to: \(profile?.username ?? "unknown")")
                            }
                                                  case .failure(let error):
                            print("🔍 DEBUG: Failed to fetch guest user profile: \(error)")
                            await MainActor.run {
                                print("🔍 DEBUG: Setting currentUserProfile to nil due to failure")
                                self.currentUser = guestUser
                                self.currentUserProfile = nil
                            }
                        }
                    } catch {
                        print("🔍 DEBUG: Error querying guest user profile: \(error)")
                        await MainActor.run {
                            print("🔍 DEBUG: Setting currentUserProfile to nil due to error")
                            self.currentUser = guestUser
                            self.currentUserProfile = nil
                        }
                    }
                } else {
                    // Handle regular authenticated user
                    print("🔍 DEBUG: Handling regular authenticated user")
                    let user = try await Amplify.Auth.getCurrentUser()
                    await MainActor.run {
                        print("🔍 DEBUG: Setting currentUser to authenticated user")
                        self.currentUser = user
                    }
                    
                    // Try to fetch user profile
                    do {
                        print("🔍 DEBUG: Fetching authenticated user profile from API...")
                        let result = try await Amplify.API.query(request: .get(User.self, byId: user.userId))
                        switch result {
                        case .success(let profile):
                            print("🔍 DEBUG: Successfully fetched user profile: \(profile?.username ?? "unknown")")
                            await MainActor.run {
                                self.currentUserProfile = profile
                                print("🔍 DEBUG: Updated currentUserProfile to: \(profile?.username ?? "unknown")")
                            }
                        case .failure(let error):
                            print("🔍 DEBUG: Failed to fetch user profile: \(error)")
                            await MainActor.run {
                                self.currentUser = user
                                self.currentUserProfile = nil
                            }
                        }
                    } catch {
                        print("🔍 DEBUG: Error querying user profile: \(error)")
                        await MainActor.run {
                            self.currentUser = user
                            self.currentUserProfile = nil
                        }
                    }
                }
                          } catch {
                print("🔍 DEBUG: Error loading current user: \(error)")
              }
        }
    }
    
    func createGame() {
        print("🔍 DEBUG: createGame() called")
        let totalPlayers = getTotalPlayerCount()
        
        // Use shared validation
        let validation = GameCreationUtils.validateGameCreation(
            playerCount: players.count,
            hostJoinAsPlayer: hostJoinAsPlayer
        )
        
        guard validation.isValid else {
            print("🔍 DEBUG: Validation failed: \(validation.message ?? "Unknown error")")
            alertMessage = validation.message ?? "Please add at least two players to the game."
            showAlert = true
            return
        }
        
        print("🔍 DEBUG: Setting isLoading to true")
        isLoading = true
        
        Task {
            do {
                print("🔍 DEBUG: Starting game creation...")
                
                // Use shared user ID handling
                let currentUserId = try await GameCreationUtils.getCurrentUserId()
                
                var playerIDs = players.map { $0.userId ?? $0.name } // Use user ID if registered, name if anonymous
                print("🔍 DEBUG: Player IDs: \(playerIDs)")
                
                // Add host as player if option is enabled
                if hostJoinAsPlayer {
                    if let currentUser = currentUser {
                        // Check if host is already in the players array before adding
                        if !isUserAlreadyInPlayers(userId: currentUser.userId, players: players) {
                            playerIDs.append(currentUser.userId)
                            print("🔍 DEBUG: Added host as registered user with ID: \(currentUser.userId)")
                        } else {
                            print("🔍 DEBUG: Host is already in players array, skipping duplicate addition")
                        }
                    } else {
                        // Host is anonymous - use their chosen display name
                        let hostName = hostPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !hostName.isEmpty {
                            // Check if host name is already in the players array
                            if !isUserAlreadyInPlayers(userId: hostName, players: players) {
                                playerIDs.append(hostName)
                                print("🔍 DEBUG: Added host as anonymous user: \(hostName)")
                            } else {
                                print("🔍 DEBUG: Host name is already in players array, skipping duplicate addition")
                            }
                        }
                    }
                }
                
                print("🔍 DEBUG: About to create Game object")
                print("🔍 DEBUG: winCondition: \(winCondition)")
                print("🔍 DEBUG: maxScore: \(maxScore)")
                print("🔍 DEBUG: maxRounds: \(maxRounds)")
                
                // Convert custom rules array to JSON string for storage
                let customRulesJSON = CustomRulesManager.shared.rulesToJSON(customRules)
                
                // Use shared game object creation
                let game = GameCreationUtils.createGameObject(
                    gameName: gameName,
                    hostUserID: currentUserId,
                    playerIDs: playerIDs,
                    customRules: customRulesJSON,
                    winCondition: winCondition,
                    maxScore: maxScore,
                    maxRounds: maxRounds
                )
                print("🔍 DEBUG: Game object created successfully")
                
                // Use shared database creation
                let createdGame = try await GameCreationUtils.saveGameToDatabase(game)
                await MainActor.run {
                    isLoading = false
                    print("🔍 DEBUG: Game created successfully with ID: \(createdGame.id)")
                    
                    // Save current settings for next time
                    saveCurrentGameSettings()
                    
                    print("🔍 DEBUG: Calling onGameCreated callback")
                    onGameCreated(createdGame)
                    print("🔍 DEBUG: onGameCreated callback completed")
                }
            } catch {
                print("🔍 DEBUG: Error in game creation: \(error)")
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    func updateGame() {
        print("🔍 DEBUG: updateGame() called")
        let totalPlayers = getTotalPlayerCount()
        guard totalPlayers >= 2 else {
            print("🔍 DEBUG: Not enough players found, showing alert")
            alertMessage = "Please add at least two players to the game."
            showAlert = true
            return
        }
        print("🔍 DEBUG: Setting isLoading to true")
        isLoading = true
        Task {
            do {
                print("🔍 DEBUG: Starting game update...")
                
                // Get the game to update
                guard case .edit(let gameToUpdate) = mode else {
                    print("🔍 DEBUG: Error: Not in edit mode")
                    await MainActor.run {
                        isLoading = false
                        alertMessage = "Error: Invalid edit mode"
                        showAlert = true
                    }
                    return
                }
                
                // Check if we're in guest mode
                let isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
                let currentUserId: String
                
                if isGuestUser {
                    currentUserId = UserDefaults.standard.string(forKey: "current_guest_user_id") ?? ""
                    print("🔍 DEBUG: Guest user ID: \(currentUserId)")
                } else {
                    let user = try await Amplify.Auth.getCurrentUser()
                    currentUserId = user.userId
                    print("🔍 DEBUG: Current user ID: \(currentUserId)")
                }
                
                var playerIDs = players.map { $0.userId ?? $0.name }
                print("🔍 DEBUG: Player IDs: \(playerIDs)")
                
                // Handle host participation based on toggle state
                if hostJoinAsPlayer {
                    // Add host as player if option is enabled
                    if let currentUser = currentUser {
                        // Check if host is already in the players array before adding
                        if !isUserAlreadyInPlayers(userId: currentUser.userId, players: players) {
                            playerIDs.append(currentUser.userId)
                            print("🔍 DEBUG: Added host as registered user with ID: \(currentUser.userId)")
                        } else {
                            print("🔍 DEBUG: Host is already in players array, skipping duplicate addition")
                        }
                    } else {
                        let hostName = hostPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !hostName.isEmpty {
                            // Check if host name is already in the players array
                            if !isUserAlreadyInPlayers(userId: hostName, players: players) {
                                playerIDs.append(hostName)
                                print("🔍 DEBUG: Added host as anonymous user: \(hostName)")
                            } else {
                                print("🔍 DEBUG: Host name is already in players array, skipping duplicate addition")
                            }
                        }
                    }
                } else {
                    // Remove host from player list if option is disabled
                    if let currentUser = currentUser {
                        playerIDs.removeAll { $0 == currentUser.userId }
                        print("🔍 DEBUG: Removed host from player list: \(currentUser.userId)")
                    } else {
                        let hostName = hostPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !hostName.isEmpty {
                            playerIDs.removeAll { $0 == hostName }
                            print("🔍 DEBUG: Removed host from player list: \(hostName)")
                        }
                    }
                }
                
                print("🔍 DEBUG: About to update Game object")
                print("🔍 DEBUG: winCondition: \(winCondition)")
                print("🔍 DEBUG: maxScore: \(maxScore)")
                print("🔍 DEBUG: maxRounds: \(maxRounds)")
                
                // Convert custom rules array to JSON string for storage
                let customRulesJSON = CustomRulesManager.shared.rulesToJSON(customRules)
                
                // Create updated game object
                let updatedGame = Game(
                    id: gameToUpdate.id,
                    gameName: gameName.isEmpty ? nil : gameName,
                    hostUserID: currentUserId,
                    playerIDs: playerIDs,
                    rounds: gameToUpdate.rounds, // Keep existing rounds
                    customRules: customRulesJSON, // Update with new custom rules
                    finalScores: gameToUpdate.finalScores, // Keep existing scores
                    gameStatus: gameToUpdate.gameStatus, // Keep existing status
                    winCondition: winCondition,
                    maxScore: maxScore,
                    maxRounds: maxRounds,
                    createdAt: gameToUpdate.createdAt, // Keep original creation date
                    updatedAt: Temporal.DateTime.now()
                )
                
                print("🔍 DEBUG: Game object updated successfully")
                print("🔍 DEBUG: Updating game with data: hostUserID=\(updatedGame.hostUserID), playerIDs=\(updatedGame.playerIDs)")
                
                let result = try await Amplify.API.mutate(request: .update(updatedGame))
                await MainActor.run {
                    isLoading = false
                    switch result {
                    case .success(let updatedGame):
                        print("🔍 DEBUG: Game updated successfully with ID: \(updatedGame.id)")
                        
                        // Save current settings for next time
                        saveCurrentGameSettings()
                        
                        print("🔍 DEBUG: Calling onGameUpdated callback")
                        onGameUpdated?(updatedGame)
                        print("🔍 DEBUG: onGameUpdated callback completed")
                        
                        // Close the sheet
                        showCreateGame = false
                        
                    case .failure(let error):
                        print("🔍 DEBUG: Game update failed with error: \(error)")
                        alertMessage = "Failed to update game: \(error.localizedDescription)"
                        showAlert = true
                    }
                }
            } catch {
                print("🔍 DEBUG: Error in game update: \(error)")
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
    
    private func addPlayer() {
        PlayerManagementFunctions.addPlayer(newPlayerName: $newPlayerName, players: $players)
    }
    
    private func searchUsers(query: String) {
        PlayerManagementFunctions.searchUsers(query: query, searchResults: $searchResults, isSearching: $isSearching)
    }
    
    private func addRegisteredPlayer(_ user: User) {
        PlayerManagementFunctions.addRegisteredPlayer(user, players: $players, searchText: $searchText, searchResults: $searchResults)
    }
    
    private func removePlayer(_ player: Player) {
        PlayerManagementFunctions.removePlayer(player, players: $players)
    }
    
    // MARK: - Game Settings Management
    
    private func loadLastGameSettings() {
        guard let lastSettings = GameSettingsStorage.shared.loadLastGameSettings() else {
            print("🔍 DEBUG: No last game settings to load")
            return
        }
        
        print("🔍 DEBUG: Loading last game settings: \(lastSettings.gameName)")
        
        // Load all settings
        gameName = lastSettings.gameName
        rounds = lastSettings.rounds
        winCondition = lastSettings.winCondition
        maxScore = lastSettings.maxScore
        maxRounds = lastSettings.maxRounds
        
        // Load custom rules from JSON
        customRules = CustomRulesManager.shared.jsonToRules(lastSettings.customRules)
        print("🔍 DEBUG: Loaded \(customRules.count) custom rules from last settings")
        
        hostJoinAsPlayer = lastSettings.hostJoinAsPlayer
        hostPlayerName = lastSettings.hostPlayerName
        
        // Load player names
        players = lastSettings.playerNames.map { name in
            Player(name: name, isRegistered: false, userId: nil, email: nil)
        }
        
        print("🔍 DEBUG: Loaded \(players.count) players from last settings")
    }
    
    private func loadGameDataForEdit() {
        print("🔍 DEBUG: loadGameDataForEdit() called")
        guard case .edit(let game) = mode else { 
            print("🔍 DEBUG: Not in edit mode, returning")
            return 
        }
        
        print("🔍 DEBUG: Loading game data for edit mode")
        print("🔍 DEBUG: Game ID: \(game.id)")
        
        // Load basic game data from the game object (which should be updated after successful updates)
        print("🔍 DEBUG: Loading basic game data...")
        gameName = game.gameName ?? ""
        rounds = game.rounds
        winCondition = game.winCondition ?? .highestScore
        maxScore = game.maxScore ?? 100
        maxRounds = game.maxRounds ?? 8
        
        // Load custom rules from JSON
        customRules = CustomRulesManager.shared.jsonToRules(game.customRules)
        print("🔍 DEBUG: Loaded \(customRules.count) custom rules from game")
        
        print("🔍 DEBUG: Game data loaded - winCondition: \(game.winCondition?.rawValue ?? "nil"), maxScore: \(game.maxScore ?? -1), maxRounds: \(game.maxRounds ?? -1)")
        
        // Load players from game.playerIDs with username lookup
        print("🔍 DEBUG: Starting player loading task...")
        Task {
            await loadPlayersWithUsernames(from: game.playerIDs)
            
            // Wait for current user to be loaded before determining host join status
            print("🔍 DEBUG: Waiting for current user to be loaded...")
            var attempts = 0
            while currentUser == nil && attempts < 10 {
                try? await Task.sleep(nanoseconds: 100_000_000) // Wait 0.1 seconds
                attempts += 1
            }
            
            // Determine if host is joining as player
            print("🔍 DEBUG: Determining host join status...")
            // This is a bit tricky since we need to check if the current user is in the playerIDs
            if let currentUser = currentUser {
                hostJoinAsPlayer = game.playerIDs.contains(currentUser.userId)
                print("🔍 DEBUG: Current user found, hostJoinAsPlayer: \(hostJoinAsPlayer)")
            } else {
                // For guest users, we'll assume they're joining if they have a display name
                hostJoinAsPlayer = !hostPlayerName.isEmpty
                print("🔍 DEBUG: No current user, using hostPlayerName check: \(hostJoinAsPlayer)")
            }
            
            print("🔍 DEBUG: Host joining as player: \(hostJoinAsPlayer)")
            print("🔍 DEBUG: loadGameDataForEdit() completed")
        }
    }
    
    private func loadPlayersWithUsernames(from playerIDs: [String]) async {
        print("🔍 DEBUG: loadPlayersWithUsernames() called with \(playerIDs.count) player IDs")
        print("🔍 DEBUG: Player IDs: \(playerIDs)")
        
        var loadedPlayers: [Player] = []
        
        for (index, playerID) in playerIDs.enumerated() {
            print("🔍 DEBUG: Processing player \(index + 1)/\(playerIDs.count): \(playerID)")
            
            // Check if this is a registered user ID or just a name
            // Cognito user IDs are UUIDs, guest IDs start with "guest_", and email addresses contain "@"
            let isRegisteredUserID = playerID.hasPrefix("guest_") || 
                                   playerID.contains("@") || 
                                   (playerID.count == 36 && playerID.contains("-")) // UUID format
            
            if isRegisteredUserID {
                print("🔍 DEBUG: \(playerID) appears to be a registered user ID")
                // This is likely a registered user ID, try to fetch the username
                do {
                    print("🔍 DEBUG: Fetching user profile for \(playerID)...")
                    let result = try await Amplify.API.query(request: .get(User.self, byId: playerID))
                    switch result {
                    case .success(let user):
                        if let user = user {
                            let username = user.username ?? playerID
                            let email = user.email
                            print("🔍 DEBUG: Found username '\(username)' for user ID '\(playerID)'")
                            loadedPlayers.append(Player(name: username, isRegistered: true, userId: playerID, email: email))
                        } else {
                            print("🔍 DEBUG: User object is nil for user ID '\(playerID)'")
                            loadedPlayers.append(Player(name: playerID, isRegistered: true, userId: playerID, email: nil))
                        }
                    case .failure(let error):
                        print("🔍 DEBUG: Failed to fetch username for user ID '\(playerID)': \(error)")
                        // Fallback to using the ID as name
                        loadedPlayers.append(Player(name: playerID, isRegistered: true, userId: playerID, email: nil))
                    }
                } catch {
                    print("🔍 DEBUG: Error fetching username for user ID '\(playerID)': \(error)")
                    // Fallback to using the ID as name
                    loadedPlayers.append(Player(name: playerID, isRegistered: true, userId: playerID, email: nil))
                }
            } else {
                print("🔍 DEBUG: \(playerID) appears to be a display name (not registered user)")
                // This is likely a display name (not a registered user)
                print("🔍 DEBUG: Using display name '\(playerID)' (not registered user)")
                loadedPlayers.append(Player(name: playerID, isRegistered: false, userId: nil, email: nil))
            }
        }
        
        print("🔍 DEBUG: About to update players array on MainActor")
        await MainActor.run {
            print("🔍 DEBUG: Updating players array with \(loadedPlayers.count) players")
            self.players = loadedPlayers
            print("🔍 DEBUG: Players array updated successfully")
            print("🔍 DEBUG: Loaded \(loadedPlayers.count) players for edit mode")
        }
        print("🔍 DEBUG: loadPlayersWithUsernames() completed")
    }
    
    private func addCustomRule() {
        // Check if user already has one custom rule (locked feature)
        if customRules.count >= 1 {
            alertMessage = "Custom rules feature is locked. You can only create one custom rule in the free version."
            showAlert = true
            return
        }
        
        let letter = newRuleLetter.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate input
        guard !letter.isEmpty && letter.count == 1 else {
            alertMessage = "Please enter a single letter"
            showAlert = true
            return
        }
        
        guard letter.range(of: "^[A-Z]$", options: .regularExpression, range: nil, locale: nil) != nil else {
            alertMessage = "Please enter a single uppercase letter (A-Z)"
            showAlert = true
            return
        }
        
        // Check for duplicate letter
        if customRules.contains(where: { $0.letter == letter }) {
            alertMessage = "Letter '\(letter)' is already used in a custom rule"
            showAlert = true
            return
        }
        
        // Check for duplicate value
        if customRules.contains(where: { $0.value == newRuleValue }) {
            alertMessage = "Value '\(newRuleValue)' is already used in a custom rule"
            showAlert = true
            return
        }
        
        // Add the rule
        let newRule = CustomRule(letter: letter, value: newRuleValue)
        customRules.append(newRule)
        
        // Clear input fields
        newRuleLetter = ""
        newRuleValue = 0
        
        print("🔍 DEBUG: Added custom rule: \(letter) = \(newRuleValue)")
    }
    
    // MARK: - Helper Functions
    
    /// Check if a user is already in the players array
    private func isUserAlreadyInPlayers(userId: String, players: [Player]) -> Bool {
        return players.contains { player in
            // Check if the player has the same user ID
            if let playerUserId = player.userId {
                return playerUserId == userId
            }
            // For anonymous players, check if the name matches (though this is less reliable)
            return player.name == userId
        }
    }
    
    private func saveCurrentGameSettings() {
        // Convert custom rules array to JSON string
        let customRulesJSON = CustomRulesManager.shared.rulesToJSON(customRules) ?? ""
        
        let settings = GameSettings(
            gameName: gameName,
            rounds: rounds,
            winCondition: winCondition,
            maxScore: maxScore,
            maxRounds: maxRounds,
            customRules: customRulesJSON,
            playerNames: players.map { $0.name },
            hostJoinAsPlayer: hostJoinAsPlayer,
            hostPlayerName: hostPlayerName
        )
        
        GameSettingsStorage.shared.saveLastGameSettings(settings)
    }
}

// MARK: - CreateGameContentView
struct CreateGameContentView: View {
    @Binding var gameName: String
    @Binding var customRules: [CustomRule]
    @Binding var rounds: Int
    @Binding var hostJoinAsPlayer: Bool
    @Binding var hostPlayerName: String
    @Binding var newPlayerName: String
    @Binding var searchText: String
    @Binding var players: [Player]
    @Binding var searchResults: [User]
    @Binding var isSearching: Bool
    @Binding var currentUser: AuthUser?
    @Binding var currentUserProfile: User?

    @Binding var useLastGameSettings: Bool
    @Binding var showAdvancedSettingsSheet: Bool
    @Binding var winCondition: WinCondition
    @Binding var maxScore: Int
    @Binding var maxRounds: Int
    @Binding var newRuleLetter: String
    @Binding var newRuleValue: Int
    
    let isIPad: Bool
    let titleFont: Font
    let bodyFont: Font
    let sectionSpacing: CGFloat
    let addPlayer: () -> Void
    let searchUsers: (String) -> Void
    let addRegisteredPlayer: (User) -> Void
    let removePlayer: (Player) -> Void
    let loadLastGameSettings: () -> Void
    let addCustomRule: () -> Void
    
    private func getHostDisplayName(for user: AuthUser) -> String {
        // Use username if available, otherwise show loading or fallback
        guard let profile = currentUserProfile else {
            return "Loading..." // Show loading while profile is being fetched
        }
        
        // username is non-optional String, so we can use it directly
        return profile.username
    }
    
    var body: some View {
        let quickStartPadding: CGFloat = isIPad ? 24 : 16
        let quickStartSpacing: CGFloat = isIPad ? 16 : 12
        let quickStartCornerRadius: CGFloat = isIPad ? 16 : 10
        let gameSettingsPadding: CGFloat = isIPad ? 24 : 16
        let gameSettingsSpacing: CGFloat = isIPad ? 16 : 12
        let gameSettingsCornerRadius: CGFloat = isIPad ? 16 : 10
        let hostJoinPadding: CGFloat = isIPad ? 24 : 16
        let hostJoinSpacing: CGFloat = isIPad ? 16 : 12
        let hostJoinCornerRadius: CGFloat = isIPad ? 16 : 10
        let advancedSettingsPadding: CGFloat = isIPad ? 24 : 16
        let advancedSettingsSpacing: CGFloat = isIPad ? 16 : 12
        let advancedSettingsCornerRadius: CGFloat = isIPad ? 16 : 10
        let advancedSettingsInnerSpacing: CGFloat = isIPad ? 16 : 12
        let hostJoinInnerSpacing: CGFloat = isIPad ? 12 : 8
        
        let quickStartButton = Button(action: {
            loadLastGameSettings()
        }) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(.white)
                Text("Use Last Game Settings")
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding()
            .background(Color("LightGreen"))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        
        let quickStartContent = VStack(alignment: .leading, spacing: 8) {
            Text("Quick Start")
                .font(bodyFont)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            quickStartButton
        }
        
        let quickStartSection = VStack(alignment: .leading, spacing: quickStartSpacing) {
            quickStartContent
        }
        .padding(quickStartPadding)
        .background(Color.black.opacity(0.3))
        .cornerRadius(quickStartCornerRadius)
        
        let gameNameTextField = TextField("", text: $gameName)
            .modifier(AppTextFieldStyle(placeholder: "Enter game name (optional)", text: $gameName))
        
        // let roundsStepper = HStack {
        //     Text("\(rounds)")
        //         .foregroundColor(.white)
        //         .font(bodyFont)
        //     Spacer()
        //     Stepper("", value: $rounds, in: 1...50)
        //         .labelsHidden()
        //         .accentColor(Color("LightGreen"))
        // }
        // .padding()
        // .background(Color.black.opacity(0.5))
        // .cornerRadius(8)
        // .overlay(
        //     RoundedRectangle(cornerRadius: 8)
        //         .stroke(Color.white.opacity(0.3), lineWidth: 1)
        // )
        
        // let roundsSection = VStack(alignment: .leading, spacing: 8) {
        //     Text("Number of Rounds")
        //             .font(bodyFont)
        //             .fontWeight(.medium)
        //             .foregroundColor(.white)
        //     
        //     roundsStepper
        // }
        
        let gameSettingsContent = VStack(alignment: .leading, spacing: gameSettingsSpacing) {
            gameNameTextField
            
            // Commented out for dynamic rounds - rounds will be added during gameplay
            // Stepper("Number of Rounds: \(rounds)", value: $rounds, in: 1...10)
            //     .font(bodyFont)
            
            Text("Rounds can be added during gameplay")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            // Number of Rounds
            //roundsSection
        }
        .padding(gameSettingsPadding)
        .background(Color.black.opacity(0.3))
        .cornerRadius(gameSettingsCornerRadius)
        
        let toggleContent = VStack(alignment: .leading, spacing: 4) {
            Text("Join as Player")
                .font(bodyFont)
                .fontWeight(.medium)
            Text("Add yourself to the scoreboard to play")
                .font(isIPad ? .body : .caption)
                .foregroundColor(.white.opacity(0.7))
        }
        
        let hostJoinToggle = Toggle(isOn: $hostJoinAsPlayer) {
            toggleContent
        }
        .toggleStyle(SwitchToggleStyle(tint: Color("LightGreen")))
        
        let hostNameTextField = TextField("", text: $hostPlayerName)
            .modifier(AppTextFieldStyle(placeholder: "Enter your display name", text: $hostPlayerName))
        
        let hostJoinContent = VStack(alignment: .leading, spacing: hostJoinInnerSpacing) {
            if let user = currentUser {
                RegisteredUserView(
                    displayName: getHostDisplayName(for: user),
                    isIPad: isIPad,
                    currentUserProfile: currentUserProfile,
                    user: user
                )
            } else {
                hostNameTextField
            }
        }
        
        let hostJoinSection = VStack(alignment: .leading, spacing: hostJoinSpacing) {
            hostJoinToggle
            
            if hostJoinAsPlayer {
                hostJoinContent
            }
        }
        .padding(hostJoinPadding)
        .background(Color.black.opacity(0.3))
        .cornerRadius(hostJoinCornerRadius)
        
        let advancedSettingsButton = Button(action: {
            showAdvancedSettingsSheet = true
        }) {
            HStack {
                Image(systemName: "gearshape")
                    .foregroundColor(.white)
                Text("Advanced Settings")
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding()
            .background(Color("LightGreen"))
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        

        
        let advancedSettingsSection = VStack(alignment: .leading, spacing: advancedSettingsSpacing) {
            advancedSettingsButton
        }
        .padding(advancedSettingsPadding)
        .background(Color.black.opacity(0.3))
        .cornerRadius(advancedSettingsCornerRadius)
        
        return VStack(spacing: sectionSpacing) {
            // Quick Start with Last Game Settings
            if GameSettingsStorage.shared.hasLastGameSettings() {
                quickStartSection
            }
            
            // Game Settings
            gameSettingsContent
            

            
            // Host Join Option
            hostJoinSection
            
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
                removePlayer: removePlayer,
                hostJoinAsPlayer: hostJoinAsPlayer,
                currentUser: currentUser,
                onHostRemoved: {
                    // Turn off the toggle when host is removed
                    hostJoinAsPlayer = false
                }
            )
            
            // Advanced Settings
            advancedSettingsSection
        }
        .padding()
    }
}

// MARK: - RegisteredUserView
struct RegisteredUserView: View {
    let displayName: String
    let isIPad: Bool
    let currentUserProfile: User?
    let user: AuthUser
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: isIPad ? 20 : 16))
            Text("Registered User")
                .font(isIPad ? .body : .caption)
                .foregroundColor(.green)
            Spacer()
            Text(displayName)
                .font(isIPad ? .body : .caption)
                .foregroundColor(.white)
                .onAppear {
                    print("🔍 DEBUG: RegisteredUserView onAppear - Displaying username: \(displayName)")
                    print("🔍 DEBUG: RegisteredUserView onAppear - currentUserProfile: \(currentUserProfile?.username ?? "nil")")
                    print("🔍 DEBUG: RegisteredUserView onAppear - user ID: \(user.userId)")
                }
        }
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            print("🔍 DEBUG: RegisteredUserView body onAppear")
        }
    }
}

// MARK: - Preview
struct CreateGameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CreateGameView(
                showCreateGame: .constant(true),
                mode: .create,
                onGameCreated: { game in
                    print("Preview: Game created with ID: \(game.id)")
                },
                onGameUpdated: nil
            )
        }
        .previewDisplayName("Create Game View")
        
        // iPad Preview
        NavigationView {
            CreateGameView(
                showCreateGame: .constant(true),
                mode: .create,
                onGameCreated: { game in
                    print("Preview: Game created with ID: \(game.id)")
                },
                onGameUpdated: nil
            )
        }
        .previewDevice(PreviewDevice(rawValue: "iPad Pro (11-inch)"))
        .previewDisplayName("Create Game View - iPad")
    }
}

// MARK: - Custom Stepper View
struct CustomStepperView: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    
    init(value: Binding<Int>, in range: ClosedRange<Int>, step: Int = 1) {
        self._value = value
        self.range = range
        self.step = step
    }
    
    var body: some View {
        HStack(spacing: 4) {
            // Minus button
            Button(action: {
                let newValue = value - step
                if range.contains(newValue) {
                    value = newValue
                }
            }) {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
            }
            .disabled(value - step < range.lowerBound)
            
            // Plus button
            Button(action: {
                let newValue = value + step
                if range.contains(newValue) {
                    value = newValue
                }
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(6)
            }
            .disabled(value + step > range.upperBound)
        }
    }
}

// MARK: - Advanced Settings Sheet
struct AdvancedSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var winCondition: WinCondition
    @Binding var maxScore: Int
    @Binding var maxRounds: Int
    @Binding var customRules: [CustomRule]
    @Binding var newRuleLetter: String
    @Binding var newRuleValue: Int
    let addCustomRule: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Configure game rules and scoring options")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Custom Score Rules
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Custom Score Rules")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Define custom letters that represent specific scores (e.g., X=0, D=100)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        // Existing rules list
                        if !customRules.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Current Rules:")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                ForEach(customRules) { rule in
                                    HStack {
                                        Text("\(rule.letter) = \(rule.value)")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Button(action: {
                                            customRules.removeAll { $0.id == rule.id }
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(4)
                                }
                            }
                        }
                        
                        // Add new rule
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Add New Rule:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            // Check if feature is locked (user already has one rule)
                            if customRules.count >= 1 {
                                // Show locked state
                                HStack(spacing: 8) {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    
                                    Text("Feature Locked - Free version limited to 1 custom rule")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    
                                    Spacer()
                                }
                                .padding(8)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                            } else {
                                // Show normal input fields
                                HStack(spacing: 8) {
                                    TextField("", text: $newRuleLetter)
                                        .modifier(AppTextFieldStyle(placeholder: "Letter", text: $newRuleLetter))
                                        .frame(width: 60)
                                        .textInputAutocapitalization(.characters)
                                        .onChange(of: newRuleLetter) { _, newValue in
                                            newRuleLetter = newValue.uppercased()
                                        }
                                    
                                    Text("=")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                    
                                    TextField("", value: $newRuleValue, format: .number)
                                        .modifier(AppTextFieldStyle(placeholder: "Value", text: Binding(
                                            get: { String(newRuleValue) },
                                            set: { newValue in
                                                if let intValue = Int(newValue) {
                                                    newRuleValue = intValue
                                                }
                                            }
                                        )))
                                        .frame(width: 80)
                                        .keyboardType(.numbersAndPunctuation)
                                    
                                    Button(action: addCustomRule) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(Color("LightGreen"))
                                            .font(.system(size: 20))
                                    }
                                    .disabled(newRuleLetter.isEmpty || newRuleLetter.count != 1)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                    
                    // Win Condition
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Win Condition")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        GeometryReader { geometry in
                            ZStack {
                                // Background container
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.black.opacity(0.3))
                                
                                // Sliding background
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color("LightGreen"))
                                    .frame(width: geometry.size.width / 2 - 2)
                                    .offset(x: winCondition == .highestScore ? -geometry.size.width / 4 + 1 : geometry.size.width / 4 - 1)
                                    .animation(.easeInOut(duration: 0.3), value: winCondition)
                                
                                // Buttons
                                HStack(spacing: 0) {
                                    // Highest Score Wins option
                                    Button(action: {
                                        winCondition = .highestScore
                                    }) {
                                        Text("Highest Score Wins")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(winCondition == .highestScore ? .white : .white.opacity(0.7))
                                            .frame(maxWidth: .infinity)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    // Lowest Score Wins option
                                    Button(action: {
                                        winCondition = .lowestScore
                                    }) {
                                        Text("Lowest Score Wins")
                                            .font(.caption2)
                                            .fontWeight(.medium)
                                            .foregroundColor(winCondition == .lowestScore ? .white : .white.opacity(0.7))
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
                    
                    // Max Score
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Max Score (Optional)")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("\(maxScore)")
                                .foregroundColor(.white)
                                .font(.body)
                            Spacer()
                            CustomStepperView(value: $maxScore, in: 10...1000, step: 10)
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Max Rounds
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Max Rounds (Optional)")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("\(maxRounds)")
                                .foregroundColor(.white)
                                .font(.body)
                            Spacer()
                            CustomStepperView(value: $maxRounds, in: 1...8, step: 1)
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 100)
            }
            .navigationTitle("Advanced Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white)
            )
            .gradientBackground()
        }
    }
}
