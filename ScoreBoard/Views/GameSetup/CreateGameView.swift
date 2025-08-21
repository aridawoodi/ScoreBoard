//
//  CreateGameView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/5/24.
//

import SwiftUI
import Amplify

struct CreateGameView: View {
    @Binding var showCreateGame: Bool
    let onGameCreated: (Game) -> Void
    
    @State private var gameName = ""
    @State private var customRules = ""
    @State private var rounds = 3
    @State private var hostJoinAsPlayer = false
    @State private var hostPlayerName = ""
    @State private var newPlayerName = ""
    @State private var searchText = ""
    @State private var players: [Player] = []
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var currentUser: AuthUser?
    @State private var currentUserProfile: User?
    
    // Basic Settings
    @State private var showBasicSettings = true
    @State private var useLastGameSettings = false
    
    // Advanced Settings
    @State private var showAdvancedSettings = false
    @State private var winCondition: WinCondition = .highestScore
    @State private var maxScore: Int = 100
    @State private var maxRounds: Int = 10
    
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
                    showBasicSettings: $showBasicSettings,
                    useLastGameSettings: $useLastGameSettings,
                    showAdvancedSettings: $showAdvancedSettings,
                    winCondition: $winCondition,
                    maxScore: $maxScore,
                    maxRounds: $maxRounds,
                    isIPad: isIPad,
                    titleFont: titleFont,
                    bodyFont: bodyFont,
                    sectionSpacing: sectionSpacing,
                    addPlayer: addPlayer,
                    searchUsers: searchUsers,
                    addRegisteredPlayer: addRegisteredPlayer,
                    removePlayer: removePlayer,
                    loadLastGameSettings: loadLastGameSettings
                )
            }
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
                    Button("Create") {
                        print("🔍 DEBUG: Create button tapped")
                        print("🔍 DEBUG: Players count: \(players.count)")
                        print("🔍 DEBUG: Is loading: \(isLoading)")
                        createGame()
                    }
                    .foregroundColor(.white)
                    .disabled(players.isEmpty || isLoading)
                }
            }
        }
            .alert("Error", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }

            .onAppear {
                loadCurrentUser()
            }
        }
    }
    
    private func clearForm() {
        gameName = ""
        customRules = ""
        rounds = 3
        hostJoinAsPlayer = false
        hostPlayerName = ""
        newPlayerName = ""
        searchText = ""
        players = []
        searchResults = []
        isSearching = false
        isLoading = false
        showAlert = false
        alertMessage = ""
        
        // Reset Basic Settings
        showBasicSettings = true
        useLastGameSettings = false
        
        // Reset Advanced Settings
        showAdvancedSettings = false
        winCondition = .highestScore
        maxScore = 100
        maxRounds = 10
    }
    
    private func loadCurrentUser() {
        Task {
            do {
                // Check if we're in guest mode
                let isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
                
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
                        self.currentUser = guestUser
                    }
                    
                    // Try to fetch guest user profile
                    do {
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
                                self.currentUser = guestUser
                                self.currentUserProfile = nil
                            }
                        }
                    } catch {
                        print("🔍 DEBUG: Error querying guest user profile: \(error)")
                        await MainActor.run {
                            self.currentUser = guestUser
                            self.currentUserProfile = nil
                        }
                    }
                } else {
                    // Handle regular authenticated user
                    let user = try await Amplify.Auth.getCurrentUser()
                    await MainActor.run {
                        self.currentUser = user
                    }
                    
                    // Try to fetch user profile
                    do {
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
                print("Error loading current user: \(error)")
            }
        }
    }
    
    func createGame() {
        print("🔍 DEBUG: createGame() called")
        guard !players.isEmpty else {
            print("🔍 DEBUG: No players found, showing alert")
            alertMessage = "Please add at least one player."
            showAlert = true
            return
        }
        print("🔍 DEBUG: Setting isLoading to true")
        isLoading = true
        Task {
            do {
                print("🔍 DEBUG: Starting game creation...")
                
                // Check if we're in guest mode
                let isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
                let currentUserId: String
                
                if isGuestUser {
                    // For guest users, get the stored guest user ID
                    currentUserId = UserDefaults.standard.string(forKey: "current_guest_user_id") ?? ""
                    print("🔍 DEBUG: Guest user ID: \(currentUserId)")
                } else {
                    // For regular users, get from Amplify Auth
                    let user = try await Amplify.Auth.getCurrentUser()
                    currentUserId = user.userId
                    print("🔍 DEBUG: Current user ID: \(currentUserId)")
                }
                
                var playerIDs = players.map { $0.userId ?? $0.name } // Use user ID if registered, name if anonymous
                print("🔍 DEBUG: Player IDs: \(playerIDs)")
                
                // Add host as player if option is enabled
                if hostJoinAsPlayer {
                    if let currentUser = currentUser {
                        // Always use the user ID for registered users, not username
                        playerIDs.append(currentUser.userId)
                        print("🔍 DEBUG: Added host as registered user with ID: \(currentUser.userId)")
                    } else {
                        // Host is anonymous - use their chosen display name
                        let hostName = hostPlayerName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !hostName.isEmpty {
                            playerIDs.append(hostName)
                            print("🔍 DEBUG: Added host as anonymous user: \(hostName)")
                        }
                    }
                }
                
                print("🔍 DEBUG: About to create Game object")
                print("🔍 DEBUG: winCondition: \(winCondition)")
                print("🔍 DEBUG: maxScore: \(maxScore)")
                print("🔍 DEBUG: maxRounds: \(maxRounds)")
                
                let game = Game(
                    gameName: gameName.isEmpty ? nil : gameName,
                    hostUserID: currentUserId,
                    playerIDs: playerIDs,
                    rounds: 1, // Start with 1 round for dynamic rounds
                    customRules: customRules.isEmpty ? nil : customRules,
                    finalScores: [],
                    gameStatus: .active,
                    winCondition: nil, // Temporarily set to nil to test
                    maxScore: nil, // Temporarily set to nil to test
                    maxRounds: nil, // Temporarily set to nil to test
                    createdAt: Temporal.DateTime.now(),
                    updatedAt: Temporal.DateTime.now()
                )
                print("🔍 DEBUG: Game object created successfully")
                print("🔍 DEBUG: Creating game with data: hostUserID=\(game.hostUserID), playerIDs=\(game.playerIDs), rounds=\(game.rounds)")
                
                let result = try await Amplify.API.mutate(request: .create(game))
                await MainActor.run {
                    isLoading = false
                    switch result {
                    case .success(let createdGame):
                        print("🔍 DEBUG: Game created successfully with ID: \(createdGame.id)")
                        
                        // Save current settings for next time
                        saveCurrentGameSettings()
                        
                        print("🔍 DEBUG: Calling onGameCreated callback")
                        onGameCreated(createdGame)
                        print("🔍 DEBUG: onGameCreated callback completed")
                    case .failure(let error):
                        print("🔍 DEBUG: Game creation failed with error: \(error)")
                        alertMessage = "Failed to create game: \(error.localizedDescription)"
                        showAlert = true
                    }
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
        customRules = lastSettings.customRules
        hostJoinAsPlayer = lastSettings.hostJoinAsPlayer
        hostPlayerName = lastSettings.hostPlayerName
        
        // Load player names
        players = lastSettings.playerNames.map { name in
            Player(name: name, isRegistered: false, userId: nil, email: nil)
        }
        
        print("🔍 DEBUG: Loaded \(players.count) players from last settings")
    }
    
    private func saveCurrentGameSettings() {
        let settings = GameSettings(
            gameName: gameName,
            rounds: rounds,
            winCondition: winCondition,
            maxScore: maxScore,
            maxRounds: maxRounds,
            customRules: customRules,
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
    @Binding var customRules: String
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
    @Binding var showBasicSettings: Bool
    @Binding var useLastGameSettings: Bool
    @Binding var showAdvancedSettings: Bool
    @Binding var winCondition: WinCondition
    @Binding var maxScore: Int
    @Binding var maxRounds: Int
    
    let isIPad: Bool
    let titleFont: Font
    let bodyFont: Font
    let sectionSpacing: CGFloat
    let addPlayer: () -> Void
    let searchUsers: (String) -> Void
    let addRegisteredPlayer: (User) -> Void
    let removePlayer: (Player) -> Void
    let loadLastGameSettings: () -> Void
    
    var body: some View {
        VStack(spacing: sectionSpacing) {
            // Game Settings
            VStack(alignment: .leading, spacing: isIPad ? 16 : 12) {
                
                ZStack(alignment: .leading) {
                    if gameName.isEmpty {
                        Text("Enter game name (optional)")
                            .foregroundColor(.white.opacity(0.5))
                            .font(bodyFont)
                            .padding(.leading, 16)
                    }
                    TextField("", text: $gameName)
                        .font(bodyFont)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
                
                // Commented out for dynamic rounds - rounds will be added during gameplay
                // Stepper("Number of Rounds: \(rounds)", value: $rounds, in: 1...10)
                //     .font(bodyFont)
                
                Text("Rounds will be added dynamically during gameplay")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(isIPad ? 24 : 16)
            .background(Color.black.opacity(0.3))
            .cornerRadius(isIPad ? 16 : 10)
            
            // Basic Settings
            VStack(alignment: .leading, spacing: isIPad ? 16 : 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showBasicSettings.toggle()
                    }
                }) {
                    HStack {
                        Text("Basic Settings")
                            .font(bodyFont)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: showBasicSettings ? "chevron.up" : "chevron.down")
                            .foregroundColor(.white)
                            .font(.system(size: isIPad ? 16 : 14))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if showBasicSettings {
                    VStack(alignment: .leading, spacing: isIPad ? 16 : 12) {
                        // Quick Start with Last Game Settings
                        let hasLastSettings = GameSettingsStorage.shared.hasLastGameSettings()
                        if hasLastSettings {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Quick Start")
                                    .font(bodyFont)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Button(action: {
                                    loadLastGameSettings()
                                }) {
                                    HStack {
                                        Image(systemName: "clock.arrow.circlepath")
                                            .foregroundColor(Color("LightGreen"))
                                        Text("Use Last Game Settings")
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        // Number of Rounds
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Number of Rounds")
                                .font(bodyFont)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("\(rounds)")
                                    .foregroundColor(.white)
                                    .font(bodyFont)
                                Spacer()
                                Stepper("", value: $rounds, in: 1...50)
                                    .labelsHidden()
                                    .accentColor(Color("LightGreen"))
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
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(isIPad ? 24 : 16)
            .background(Color.black.opacity(0.3))
            .cornerRadius(isIPad ? 16 : 10)
            
            // Host Join Option
            VStack(alignment: .leading, spacing: isIPad ? 16 : 12) {
                Toggle(isOn: $hostJoinAsPlayer) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Join as Player")
                            .font(bodyFont)
                            .fontWeight(.medium)
                        Text("Add yourself to the scoreboard to play")
                            .font(isIPad ? .body : .caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color("LightGreen")))
                
                if hostJoinAsPlayer {
                    VStack(alignment: .leading, spacing: isIPad ? 12 : 8) {
                        if let user = currentUser {
                            let displayName = currentUserProfile?.username ?? user.userId
                            RegisteredUserView(
                                displayName: displayName,
                                isIPad: isIPad,
                                currentUserProfile: currentUserProfile,
                                user: user
                            )
                        } else {
                            ZStack(alignment: .leading) {
                                if hostPlayerName.isEmpty {
                                    Text("Enter your display name")
                                        .foregroundColor(.white.opacity(0.5))
                                        .font(bodyFont)
                                        .padding(.leading, 16)
                                }
                                TextField("", text: $hostPlayerName)
                                    .font(bodyFont)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            }
            .padding(isIPad ? 24 : 16)
            .background(Color.black.opacity(0.3))
            .cornerRadius(isIPad ? 16 : 10)
            
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
            
            // Advanced Settings
            VStack(alignment: .leading, spacing: isIPad ? 16 : 12) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showAdvancedSettings.toggle()
                    }
                }) {
                    HStack {
                        Text("Advanced Settings")
                            .font(bodyFont)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: showAdvancedSettings ? "chevron.up" : "chevron.down")
                            .foregroundColor(.white)
                            .font(.system(size: isIPad ? 16 : 14))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if showAdvancedSettings {
                    VStack(alignment: .leading, spacing: isIPad ? 16 : 12) {
                        // Custom Rules
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Custom Rules (Optional)")
                                .font(bodyFont)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            ZStack(alignment: .leading) {
                                if customRules.isEmpty {
                                    Text("Enter custom rules (optional)")
                                        .foregroundColor(.white.opacity(0.5))
                                        .font(bodyFont)
                                        .padding(.leading, 16)
                                }
                                TextField("", text: $customRules)
                                    .font(bodyFont)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        
                        // Win Condition
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Win Condition")
                                .font(bodyFont)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Picker("Win Condition", selection: $winCondition) {
                                Text("Highest Score Wins").tag(WinCondition.highestScore)
                                Text("Lowest Score Wins").tag(WinCondition.lowestScore)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .accentColor(Color("LightGreen"))
                        }
                        
                        // Max Score
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Max Score (Optional)")
                                .font(bodyFont)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("\(maxScore)")
                                    .foregroundColor(.white)
                                    .font(bodyFont)
                                Spacer()
                                Stepper("", value: $maxScore, in: 10...1000, step: 10)
                                    .labelsHidden()
                                    .accentColor(Color("LightGreen"))
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
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Max Rounds (Optional)")
                                .font(bodyFont)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            HStack {
                                Text("\(maxRounds)")
                                    .foregroundColor(.white)
                                    .font(bodyFont)
                                Spacer()
                                Stepper("", value: $maxRounds, in: 1...50)
                                    .labelsHidden()
                                    .accentColor(Color("LightGreen"))
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
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(isIPad ? 24 : 16)
            .background(Color.black.opacity(0.3))
            .cornerRadius(isIPad ? 16 : 10)
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
                    print("🔍 DEBUG: Displaying username: \(displayName)")
                    print("🔍 DEBUG: currentUserProfile: \(currentUserProfile?.username ?? "nil")")
                }
        }
        .id("profile-display-\(currentUserProfile?.username ?? user.userId)")
        .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Preview
struct CreateGameView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CreateGameView(
                showCreateGame: .constant(true),
                onGameCreated: { game in
                    print("Preview: Game created with ID: \(game.id)")
                }
            )
        }
        .previewDisplayName("Create Game View")
        
        // iPad Preview
        NavigationView {
            CreateGameView(
                showCreateGame: .constant(true),
                onGameCreated: { game in
                    print("Preview: Game created with ID: \(game.id)")
                }
            )
        }
        .previewDevice(PreviewDevice(rawValue: "iPad Pro (11-inch)"))
        .previewDisplayName("Create Game View - iPad")
    }
}