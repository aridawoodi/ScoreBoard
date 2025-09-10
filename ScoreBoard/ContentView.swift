//
//  ContentView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/3/24.
//
import SwiftUI
import Amplify
import Authenticator

enum AuthStatus {
    case signedIn
    case signedOut
    case checking
}

struct ContentView: View {
    @State private var authStatus: AuthStatus = .checking
    @State private var selectedTab = 2 // Default to 'Your Board' (now tag 2)
    @State private var hasCheckedSession = false
    
    // Enhanced state management
    @State private var navigationState = NavigationState()
    @State private var showUserProfile = false
    @StateObject private var userService = UserService.shared
    
    // Navigation state management
    @State private var showJoinGame = false
    @State private var showGameSelection = false
    @State private var showCreateGame = false
    @State private var showAnalytics = false
    @State private var showProfileEdit = false
    
    // For floating tab bar animation
    @Namespace private var tabBarNamespace
    
    // Track if side navigation is open - Commented out for future use
    // @State private var isSideNavigationOpen = false
    
    
    var body: some View {
        let _ = print("🔍 DEBUG: ContentView body computed - authStatus: \(authStatus)")
        
        if authStatus == .checking {
            // Show loading screen while checking for existing session
            ZStack {
                // Background gradient covering entire screen
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("GradientBackground"), // Dark green from asset
                        Color.black // Very dark gray / almost black
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(.all, edges: .all)
                
                VStack {
                    Spacer()
                    
                    // App logo
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .padding(.bottom, 20)
                    
                    Text("ScoreBoard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                    
                    Text("Checking session...")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 40)
                    
                    // Loading indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Spacer()
                }
            }
            .onAppear {
                print("🔍 DEBUG: Loading screen onAppear called")
                print("🔍 DEBUG: Current authStatus: \(authStatus)")
                print("🔍 DEBUG: hasCheckedSession: \(hasCheckedSession)")
                
                if !hasCheckedSession {
                    hasCheckedSession = true
                    checkExistingSession()
                }
            }
        } else if authStatus == .signedOut {
            ZStack {
                // Background gradient covering entire screen
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("GradientBackground"), // Dark green from asset
                        Color.black // Very dark gray / almost black
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(.all, edges: .all)
                
                // Custom Authentication View with LightGreen theme
                CustomSignInView {
                    authStatus = .signedIn
                    // Automatically create user profile when user signs in
                    Task {
                        await userService.ensureUserProfile()
                    }
                }
                

            }
        } else {
            ZStack {
                // Background gradient covering entire screen
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("GradientBackground"), // Dark green from asset
                        Color.black // Very dark gray / almost black
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(.all, edges: .all)
                
                // Main content
                Group {
                    switch selectedTab {
                    case 0:
                        JoinScoreboardTabView(
                            navigationState: navigationState,
                            showJoinGame: $showJoinGame,
                            showGameSelection: $showGameSelection,
                            selectedTab: $selectedTab
                        )
                        .transition(.opacity)
                    case 1:
                        AnalyticsTabView(
                            navigationState: navigationState,
                            selectedTab: $selectedTab
                        )
                        .transition(.opacity)
                    case 2:
                        YourBoardTabView(
                            navigationState: navigationState,
                            selectedTab: $selectedTab
                        )
                        .transition(.opacity)
                    case 3:
                        CreateScoreboardTabView(
                            navigationState: navigationState,
                            showCreateGame: $showCreateGame,
                            selectedTab: $selectedTab
                        )
                        .transition(.opacity)
                    case 4:
                        ProfileTabView(
                            showUserProfile: $showUserProfile,
                            showProfileEdit: $showProfileEdit,
                            onSignOut: {
                                Task {
                                    await signOut()
                                }
                            }
                            // isSideNavigationOpen: $isSideNavigationOpen // Commented out for future use
                        )
                        .transition(.opacity)
                    default:
                        YourBoardTabView(
                            navigationState: navigationState,
                            selectedTab: $selectedTab
                        )
                        .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.keyboard)
                .animation(.easeInOut(duration: 0.2), value: selectedTab)
                
                // Floating Tab Bar - Restored original behavior
                VStack {
                    Spacer()
                    FloatingTabBar(selectedTab: $selectedTab, namespace: tabBarNamespace, navigationState: navigationState, isHidden: navigationState.isKeyboardActive)
                        .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 12 : 8)
                        .onChange(of: navigationState.isKeyboardActive) { _, isActive in
                            print("🔍 DEBUG: ContentView - FloatingTabBar isHidden changed to: \(isActive)")
                        }
                }
                .ignoresSafeArea(.keyboard)
                .onReceive(navigationState.$isKeyboardActive) { isActive in
                    print("🔍 DEBUG: ContentView - Received keyboard state change: \(isActive)")
                }
                .onChange(of: navigationState.isKeyboardActive) { _, isActive in
                    print("🔍 DEBUG: ContentView - onChange triggered for isKeyboardActive: \(isActive)")
                }
                

                
                // Floating Tab Bar - hide when side navigation is open - Commented out for future use
                // if !isSideNavigationOpen {
                //     VStack {
                //         Spacer()
                //         FloatingTabBar(selectedTab: $selectedTab, namespace: tabBarNamespace)
                //             .padding(.bottom, UIDevice.current.userInterfaceIdiom == .pad ? 12 : 8)
                //     }
                //     .ignoresSafeArea(.keyboard)
                //     .transition(.opacity)
                //     .animation(.easeInOut(duration: 0.3), value: isSideNavigationOpen)
                // }
            }
            .sheet(isPresented: $showUserProfile) {
                UserProfileView()
            }
            .sheet(isPresented: $showJoinGame) {
                JoinGameView(showJoinGame: $showJoinGame) { game in
                    print("🔍 DEBUG: ===== JOIN GAME CALLBACK START =====")
                    
                    // Use standardized callback handling
                    GameCreationUtils.handleGameCreated(
                        game: game,
                        navigationState: navigationState,
                        selectedTab: $selectedTab
                    )
                    
                    print("🔍 DEBUG: ===== JOIN GAME CALLBACK END =====")
                }
            }
            .sheet(isPresented: $showGameSelection) {
                GameSelectionView(
                    games: navigationState.userGames,
                    onGameSelected: { selectedGame in
                        navigationState.selectedGame = selectedGame
                        selectedTab = 2 // Switch to Your Board
                    },
                    onGameDeleted: {
                        // Refresh user games after deletion
                        loadUserGames()
                    }
                )
            }
            .sheet(isPresented: $showCreateGame) {
                CreateGameView(
                    showCreateGame: $showCreateGame,
                    mode: .create,
                    onGameCreated: { game in
                        // Use standardized callback handling
                        GameCreationUtils.handleGameCreated(
                            game: game,
                            navigationState: navigationState,
                            selectedTab: $selectedTab
                        )
                    },
                    onGameUpdated: nil
                )
            }
            .onChange(of: selectedTab) { newValue in
                print("🔍 DEBUG: selectedTab changed to: \(newValue)")
                if newValue == 2 {
                    print("🔍 DEBUG: Switched to Create Scoreboard tab - should trigger profile refresh")
                }
            }
            .sheet(isPresented: $showAnalytics) {
                PlayerAnalyticsView()
            }
            .sheet(isPresented: $showProfileEdit) {
                ProfileEditView()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                // Check session and refresh when app comes back to foreground
                print("🔍 DEBUG: App entering foreground - checking session")
                checkExistingSession()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Check session and refresh when app becomes active
                print("🔍 DEBUG: App became active - checking session")
                checkExistingSession()
            }
        }
    }
    
    func signOut() async {
        // Check if current user is a guest using UserDefaults
        let isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
        
        if isGuestUser {
            // For guest users, clear the state but keep the persistent guest ID
            // This allows the same guest user to sign back in with the same profile
            print("Guest user signing out")
            // Don't remove persistent_guest_id - keep it for future sign-ins
            UserDefaults.standard.removeObject(forKey: "current_guest_user_id")
            UserDefaults.standard.removeObject(forKey: "is_guest_user")
            await MainActor.run {
                authStatus = .signedOut
                navigationState.clear()
            }
        } else {
            // For regular users, use Amplify sign out
            do {
                let result = try await Amplify.Auth.signOut()
                print("Signed out successfully: \(result)")
                
                // Clear authenticated user ID
                UserDefaults.standard.removeObject(forKey: "authenticated_user_id")
                UserDefaults.standard.removeObject(forKey: "is_guest_user")
                
                await MainActor.run {
                    authStatus = .signedOut
                    navigationState.clear()
                }
            } catch {
                print("Error signing out: \(error)")
                // Even if there's an error, clear the state
                await MainActor.run {
                    authStatus = .signedOut
                    navigationState.clear()
                }
            }
        }
        
        // Clear username cache on sign out
        UsernameCacheService.shared.clearCurrentUserUsername()
    }
    
    func signInAsGuest() async {
        print("🔍 DEBUG: Starting guest sign-in...")
        
        do {
            // Check if there's already a user signed in (guest or authenticated)
            let currentAuthState = try await Amplify.Auth.fetchAuthSession()
            
            if currentAuthState.isSignedIn {
                print("🔍 DEBUG: User already signed in, signing out first...")
                
                // Save current user's data before switching
                UserSpecificStorageManager.shared.saveCurrentUserData()
                
                // Sign out the current user
                _ = try await Amplify.Auth.signOut()
                print("🔍 DEBUG: Successfully signed out current user")
                
                // Clear authenticated user flags if they exist
                UserDefaults.standard.removeObject(forKey: "authenticated_user_id")
                UserDefaults.standard.removeObject(forKey: "is_guest_user")
            }
        } catch {
            print("🔍 DEBUG: Error checking/signing out current user: \(error)")
            // Continue with guest sign-in even if there's an error
        }
        
        // Check if we already have a guest ID stored for this device
        let guestIdKey = "persistent_guest_id"
        let existingGuestId = UserDefaults.standard.string(forKey: guestIdKey)
        
        let guestId: String
        if let existingId = existingGuestId {
            // Reuse existing guest ID
            guestId = existingId
            print("🔍 DEBUG: Reusing existing guest ID: \(guestId)")
        } else {
            // Create new guest ID and store it
            guestId = "guest_\(UUID().uuidString)"
            UserDefaults.standard.set(guestId, forKey: guestIdKey)
            print("🔍 DEBUG: Created new guest ID: \(guestId)")
        }
        
        // Store guest authentication info for API calls
        UserDefaults.standard.set(guestId, forKey: "current_guest_user_id")
        UserDefaults.standard.set(true, forKey: "is_guest_user")
        
        print("🔍 DEBUG: Guest authentication info stored in UserDefaults")
        
        // Load the guest user's data
        UserSpecificStorageManager.shared.loadNewUserData()
        print("🔍 DEBUG: Loaded guest user's data")
        
        // Ensure API access for guest users
        await ensureGuestAPIAccess()
        
        await MainActor.run {
            print("🔍 DEBUG: Setting authStatus to .signedIn")
            authStatus = .signedIn
        }
        
        // Automatically create user profile for guest user
        print("🔍 DEBUG: Ensuring guest user profile exists...")
        await userService.ensureUserProfile()
    }
    
    // MARK: - Session Management
    
    func checkExistingSession() {
        print("🔍 DEBUG: ===== CHECK EXISTING SESSION CALLED =====")
        let startTime = Date()
        print("🔍 DEBUG: Starting session check at \(startTime)")
        
        // Debug: Print all relevant UserDefaults values
        let isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
        let guestUserId = UserDefaults.standard.string(forKey: "current_guest_user_id") ?? ""
        let authUserId = UserDefaults.standard.string(forKey: "authenticated_user_id") ?? ""
        
        print("🔍 DEBUG: UserDefaults values:")
        print("🔍 DEBUG: - is_guest_user: \(isGuestUser)")
        print("🔍 DEBUG: - current_guest_user_id: '\(guestUserId)'")
        print("🔍 DEBUG: - authenticated_user_id: '\(authUserId)'")
        
        // Check for guest user session (instant, no network)
        if isGuestUser && !guestUserId.isEmpty {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            print("🔍 DEBUG: Found existing guest session: \(guestUserId) (took \(duration * 1000)ms)")
            authStatus = .signedIn
            // Load games in background after session is restored
            Task {
                loadUserGames()
            }
            return
        }
        
        // Check for stored authenticated user ID (instant, no network)
        if !authUserId.isEmpty {
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            print("🔍 DEBUG: Found stored authenticated user ID: \(authUserId) (took \(duration * 1000)ms)")
            print("🔍 DEBUG: Restoring session from local storage")
            
            // Restore the session from local storage
            UserDefaults.standard.set(false, forKey: "is_guest_user")
            authStatus = .signedIn
            
            // Load user data and games in background after session is restored
            Task {
                UserSpecificStorageManager.shared.loadNewUserData()
                loadUserGames()
            }
            return
        }
        
        // No stored session found, show sign-in screen immediately
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        print("🔍 DEBUG: No stored session found, showing sign-in screen (took \(duration * 1000)ms)")
        authStatus = .signedOut
    }
    

    func loadUserGames() {
        Task {
            do {
                print("🔍 DEBUG: ===== LOAD USER GAMES START =====")
                print("🔍 DEBUG: Loading user games...")
                
                // Check if we're in guest mode
                let isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
                let currentUserId: String
                
                if isGuestUser {
                    // For guest users, get the stored guest user ID
                    currentUserId = UserDefaults.standard.string(forKey: "current_guest_user_id") ?? ""
                    print("🔍 DEBUG: Guest user ID: \(currentUserId)")
                } else {
                    // For regular users, get from Amplify Auth
                    let currentUser = try await Amplify.Auth.getCurrentUser()
                    currentUserId = currentUser.userId
                    print("🔍 DEBUG: Current user ID: \(currentUserId)")
                }
                
                // Use DataManager to load games efficiently (skipped for guest users)
                await DataManager.shared.loadGames()
                
                await MainActor.run {
                    // Get user games using DataManager
                    let userGames = DataManager.shared.getGamesForUser(currentUserId)
                    print("🔍 DEBUG: Successfully fetched \(userGames.count) user games efficiently")
                    
                    // Additional filtering for anonymous users (userID:displayName format)
                    let filteredUserGames = userGames.filter { game in
                            let playerIDs = game.playerIDs
                            let hostUserID = game.hostUserID
                            
                            // Check if user is the host
                            if hostUserID == currentUserId {
                                print("🔍 DEBUG: User is host of game \(game.id)")
                                return true
                            }
                            
                            // Check for registered user ID in playerIDs
                            if playerIDs.contains(currentUserId) {
                                print("🔍 DEBUG: User is player in game \(game.id)")
                                return true
                            }
                            
                            // Check for anonymous user format "userID:displayName" in playerIDs
                            let isAnonymousPlayer = playerIDs.contains { playerID in
                                playerID.hasPrefix(currentUserId)
                            }
                            if isAnonymousPlayer {
                                print("🔍 DEBUG: User is anonymous player in game \(game.id)")
                                return true
                            }
                            
                            return false
                        }
                        print("🔍 DEBUG: Final filtered to \(filteredUserGames.count) user games")
                        print("🔍 DEBUG: User games IDs: \(filteredUserGames.map { $0.id })")
                        navigationState.userGames = filteredUserGames
                        print("🔍 DEBUG: Updated navigationState.userGames count: \(navigationState.userGames.count)")
                        print("🔍 DEBUG: navigationState.latestGame: \(navigationState.latestGame?.id ?? "nil")")
                        print("🔍 DEBUG: navigationState.selectedGame: \(navigationState.selectedGame?.id ?? "nil")")
                        
                        // Clear selectedGame if it no longer exists in userGames
                        if let selectedGame = navigationState.selectedGame {
                            let gameStillExists = filteredUserGames.contains { $0.id == selectedGame.id }
                            if !gameStillExists {
                                print("🔍 DEBUG: Selected game no longer exists, clearing it")
                                navigationState.selectedGame = nil
                            } else {
                                // Update the selectedGame with the latest data from the database
                                if let updatedGame = filteredUserGames.first(where: { $0.id == selectedGame.id }) {
                                    print("🔍 DEBUG: Updating selectedGame with latest data from database")
                                    print("🔍 DEBUG: Old selectedGame rounds: \(selectedGame.rounds)")
                                    print("🔍 DEBUG: New selectedGame rounds: \(updatedGame.rounds)")
                                    print("🔍 DEBUG: Old selectedGame playerIDs: \(selectedGame.playerIDs)")
                                    print("🔍 DEBUG: New selectedGame playerIDs: \(updatedGame.playerIDs)")
                                    navigationState.selectedGame = updatedGame
                                }
                            }
                        }
                }
                print("🔍 DEBUG: ===== LOAD USER GAMES END =====")
            } catch {
                print("🔍 DEBUG: Error in loadUserGames: \(error)")
                await MainActor.run {
                    navigationState.userGames = []
                }
            }
        }
    }
} 