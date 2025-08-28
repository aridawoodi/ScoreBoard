//
//  YourBoardTabView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI

// MARK: - Your Board Tab View
struct YourBoardTabView: View {
    @ObservedObject var navigationState: NavigationState
    @Binding var selectedTab: Int
    @StateObject private var onboardingManager = OnboardingManager()
    @State private var showOnboardingTooltip = false
    @State private var forceViewReset = false
    @State private var viewRefreshCounter = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                if let selectedGame = navigationState.selectedGame, !forceViewReset {
                    // Show selected game with new Scoreboardview
                    Scoreboardview(game: Binding(
                        get: { navigationState.selectedGame ?? selectedGame },
                        set: { newGame in
                            navigationState.selectedGame = newGame
                        }
                    )) { updatedGame in
                        print("🔍 DEBUG: ===== GAME UPDATE IN YOUR BOARD TAB ======")
                        print("🔍 DEBUG: Updating selectedGame from \(selectedGame.id) to \(updatedGame.id)")
                        print("🔍 DEBUG: Old rounds: \(selectedGame.rounds), New rounds: \(updatedGame.rounds)")
                        
                        // Update the selectedGame in navigation state
                        navigationState.selectedGame = updatedGame
                        
                        // Also update the game in userGames array
                        if let index = navigationState.userGames.firstIndex(where: { $0.id == updatedGame.id }) {
                            navigationState.userGames[index] = updatedGame
                        }
                        
                        // Call the parent callback if provided
                        // onGameUpdated?(updatedGame) // This line was removed as per the edit hint
                    } onGameDeleted: {
                        print("🔍 DEBUG: ===== GAME DELETED CALLBACK (SELECTED) =====")
                        print("🔍 DEBUG: Before - selectedGame: \(navigationState.selectedGame?.id ?? "nil")")
                        print("🔍 DEBUG: Before - userGames count: \(navigationState.userGames.count)")
                        
                        // When a game disappears on backend, clear selection so empty state shows
                        navigationState.selectedGame = nil
                        
                        // Immediately remove the deleted game from userGames array
                        navigationState.userGames.removeAll { $0.id == selectedGame.id }
                        
                        print("🔍 DEBUG: After - selectedGame: \(navigationState.selectedGame?.id ?? "nil")")
                        print("🔍 DEBUG: After - userGames count: \(navigationState.userGames.count)")
                        
                        // Force view refresh by triggering objectWillChange
                        navigationState.objectWillChange.send()
                        
                        // Force view reset
                        forceViewReset = true
                        
                        // Then refresh from backend to ensure consistency
                        Task { await navigationState.refreshUserGames() }
                    }
                    .onAppear {
                        print("🔍 DEBUG: Showing selectedGame view for: \(selectedGame.id)")
                    }
                    
                } else if let latestGame = navigationState.latestGame, !forceViewReset, !navigationState.shouldShowMainBoard {
                    // Show latest game with new Scoreboardview
                    Scoreboardview(game: .constant(latestGame)) { updatedGame in
                        print("🔍 DEBUG: ===== GAME UPDATE IN YOUR BOARD TAB (LATEST) =====")
                        print("🔍 DEBUG: Updating latestGame from \(latestGame.id) to \(updatedGame.id)")
                        print("🔍 DEBUG: Old rounds: \(latestGame.rounds), New rounds: \(updatedGame.rounds)")
                        
                        // Update the selectedGame in navigation state instead
                        navigationState.selectedGame = updatedGame
                        
                        // Also update the game in userGames array
                        if let index = navigationState.userGames.firstIndex(where: { $0.id == updatedGame.id }) {
                            navigationState.userGames[index] = updatedGame
                            print("🔍 DEBUG: Updated game in userGames array")
                        }
                        
                        print("🔍 DEBUG: ===== GAME UPDATE IN YOUR BOARD TAB END =====")
                    } onGameDeleted: {
                        print("🔍 DEBUG: ===== GAME DELETED CALLBACK (LATEST) =====")
                        print("🔍 DEBUG: Before - selectedGame: \(navigationState.selectedGame?.id ?? "nil")")
                        print("🔍 DEBUG: Before - userGames count: \(navigationState.userGames.count)")
                        
                        // When latest is deleted, refresh list and allow empty state to appear
                        navigationState.selectedGame = nil
                        
                        // Immediately remove the deleted game from userGames array
                        navigationState.userGames.removeAll { $0.id == latestGame.id }
                        
                        print("🔍 DEBUG: After - selectedGame: \(navigationState.selectedGame?.id ?? "nil")")
                        print("🔍 DEBUG: After - userGames count: \(navigationState.userGames.count)")
                        
                        // Force view refresh by triggering objectWillChange
                        navigationState.objectWillChange.send()
                        
                        // Force view reset
                        forceViewReset = true
                        
                        // Then refresh from backend to ensure consistency
                        Task { await navigationState.refreshUserGames() }
                    }
                    .id(latestGame.id) // Prevent recreation when switching tabs
                    .onAppear {
                        print("🔍 DEBUG: Showing latestGame view for: \(latestGame.id)")
                    }
                } else {
                    // Main board view - show empty state with quick game cards and floating action button for existing games
                    ZStack {
                        VStack(spacing: 8) {
                            // Custom animated logo for main board
                            AnimatedLogoView.interactive(size: 80)
                                .padding(.top, 5)
                            
                            Text("Your Board")
                                .font(.largeTitle.bold())
                                .foregroundColor(.white)
                                .padding(.top, 2)
                            
                            Text("This is your main board. Use the tabs below to create or join games.")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            // Quick Game Cards
                            VStack(spacing: 16) {
                                // 2 Player Quick Game Card
                                QuickGameCard(playerCount: 2) { game in
                                    print("🔍 DEBUG: ===== 2 PLAYER QUICK GAME CREATED =====")
                                    print("🔍 DEBUG: Quick game created with ID: \(game.id)")
                                    
                                    // Update navigation state to show the new game
                                    navigationState.selectedGame = game
                                    
                                    // Add to user games list
                                    navigationState.userGames.append(game)
                                    
                                    // Reset force view reset flag
                                    forceViewReset = false
                                    
                                    // Force view refresh by triggering objectWillChange
                                    navigationState.objectWillChange.send()
                                    
                                    // Increment refresh counter to force view update
                                    viewRefreshCounter += 1
                                    
                                    // Add a small delay to ensure UI updates
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        // Force another refresh to ensure view updates
                                        viewRefreshCounter += 1
                                    }
                                    
                                    print("🔍 DEBUG: After 2-player creation - selectedGame: \(navigationState.selectedGame?.id ?? "nil")")
                                    print("🔍 DEBUG: After 2-player creation - userGames count: \(navigationState.userGames.count)")
                                    print("🔍 DEBUG: After 2-player creation - forceViewReset: \(forceViewReset)")
                                    
                                    print("🔍 DEBUG: ===== 2 PLAYER QUICK GAME CREATED END =====")
                                }
                                
                                // 4 Player Quick Game Card
                                QuickGameCard(playerCount: 4) { game in
                                    print("🔍 DEBUG: ===== 4 PLAYER QUICK GAME CREATED =====")
                                    print("🔍 DEBUG: Quick game created with ID: \(game.id)")
                                    
                                    // Update navigation state to show the new game
                                    navigationState.selectedGame = game
                                    
                                    // Add to user games list
                                    navigationState.userGames.append(game)
                                    
                                    // Reset force view reset flag
                                    forceViewReset = false
                                    
                                    // Force view refresh by triggering objectWillChange
                                    navigationState.objectWillChange.send()
                                    
                                    // Increment refresh counter to force view update
                                    viewRefreshCounter += 1
                                    
                                    // Add a small delay to ensure UI updates
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        // Force another refresh to ensure view updates
                                        viewRefreshCounter += 1
                                    }
                                    
                                    print("🔍 DEBUG: After 4-player creation - selectedGame: \(navigationState.selectedGame?.id ?? "nil")")
                                    print("🔍 DEBUG: After 4-player creation - userGames count: \(navigationState.userGames.count)")
                                    print("🔍 DEBUG: After 4-player creation - forceViewReset: \(forceViewReset)")
                                    
                                    print("🔍 DEBUG: ===== 4 PLAYER QUICK GAME CREATED END =====")
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .onAppear {
                            print("🔍 DEBUG: Showing main board with \(navigationState.userGames.count) games")
                        }
                        
                        // Floating action button to show existing games
                        if navigationState.hasGames {
                            DraggableFloatingButton(
                                gamesCount: navigationState.userGames.count,
                                onTap: {
                                    print("🔍 DEBUG: Floating action button tapped - showing \(navigationState.userGames.count) games")
                                    // Auto-select the latest game to show the scoreboard view
                                    if let latestGame = navigationState.latestGame {
                                        navigationState.selectedGame = latestGame
                                    }
                                }
                            )
                        }
                    }
                    
                    Spacer()
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("GradientBackground"), // Dark green from asset
                        Color.black // Very dark gray / almost black
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(.all, edges: .all)
            )
            .id("YourBoardTab-\(navigationState.selectedGame?.id ?? "nil")-\(navigationState.userGames.count)-\(viewRefreshCounter)")
            .onAppear {
                print("🔍 DEBUG: ===== YOUR BOARD TAB ON APPEAR =====")
                print("🔍 DEBUG: selectedGame: \(navigationState.selectedGame?.id ?? "nil")")
                print("🔍 DEBUG: latestGame: \(navigationState.latestGame?.id ?? "nil")")
                print("🔍 DEBUG: userGames count: \(navigationState.userGames.count)")
                print("🔍 DEBUG: forceViewReset: \(forceViewReset)")
                print("🔍 DEBUG: shouldShowMainBoard: \(navigationState.shouldShowMainBoard)")
                
                // Reset force view reset flag
                forceViewReset = false
                
                // Auto-select the latest game if no game is currently selected and user hasn't requested main board
                if navigationState.selectedGame == nil && navigationState.latestGame != nil && !navigationState.shouldShowMainBoard {
                    print("🔍 DEBUG: Auto-selecting latest game: \(navigationState.latestGame!.id)")
                    navigationState.selectedGame = navigationState.latestGame
                } else if navigationState.shouldShowMainBoard {
                    print("🔍 DEBUG: User requested main board - keeping selectedGame as nil")
                    navigationState.shouldShowMainBoard = false // Reset the flag
                } else {
                    print("🔍 DEBUG: No auto-selection needed - selectedGame: \(navigationState.selectedGame?.id ?? "nil"), latestGame: \(navigationState.latestGame?.id ?? "nil"), shouldShowMainBoard: \(navigationState.shouldShowMainBoard)")
                }
                
                // Show onboarding tooltip for new users with no games
                if !navigationState.hasGames && !onboardingManager.hasSeenOnboarding {
                    DispatchQueue.main.asyncAfter(deadline: .now() + OnboardingConstants.Animation.tooltipAppearDelay) {
                        showOnboardingTooltip = true
                    }
                }
                
                print("🔍 DEBUG: ===== YOUR BOARD TAB ON APPEAR END =====")
            }
            .overlay {
                if showOnboardingTooltip {
                    OnboardingTooltip(
                        title: OnboardingConstants.Messages.welcomeTitle,
                        message: OnboardingConstants.Messages.welcomeMessage,
                        actionText: OnboardingConstants.Buttons.createGame,
                        dismissText: OnboardingConstants.Buttons.maybeLater
                    ) {
                        // Navigate to Create Scoreboard tab
                        selectedTab = 3 // Create Scoreboard tab index
                    } onDismiss: {
                        showOnboardingTooltip = false
                        onboardingManager.markOnboardingAsSeen()
                    }
                }
            }
        }
    }
}

// MARK: - Draggable Floating Button
struct DraggableFloatingButton: View {
    let gamesCount: Int
    let onTap: () -> Void
    
    @State private var position: CGPoint
    @State private var isDragging = false
    
    init(gamesCount: Int, onTap: @escaping () -> Void) {
        self.gamesCount = gamesCount
        self.onTap = onTap
        
        // Load saved position or use default
        let savedX = UserDefaults.standard.double(forKey: "FloatingButtonPositionX")
        let savedY = UserDefaults.standard.double(forKey: "FloatingButtonPositionY")
        
        let defaultX = UIScreen.main.bounds.width - 80
        let defaultY = UIScreen.main.bounds.height - 200
        
        // Use saved position if valid, otherwise use default
        if savedX > 0 && savedY > 0 {
            self._position = State(initialValue: CGPoint(x: savedX, y: savedY))
        } else {
            self._position = State(initialValue: CGPoint(x: defaultX, y: defaultY))
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                AppLogoIcon(isSelected: false, size: 24)
                
                Text("\(gamesCount)")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color("LightGreen"))
            .clipShape(Capsule())
            .shadow(color: Color.black.opacity(isDragging ? 0.5 : 0.3), radius: isDragging ? 12 : 8, x: 0, y: isDragging ? 6 : 4)
            .scaleEffect(isDragging ? 1.1 : 1.0)
        }
        .position(position)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    // Use the drag location to make button follow finger directly
                    let newPosition = value.location
                    
                    // Keep button within screen bounds
                    let buttonRadius: CGFloat = 50 // Approximate button radius
                    let screenWidth = UIScreen.main.bounds.width
                    let screenHeight = UIScreen.main.bounds.height
                    let tabBarHeight: CGFloat = 180 // Increased height to avoid floating tab bar completely
                    
                    position.x = max(buttonRadius, min(screenWidth - buttonRadius, newPosition.x))
                    position.y = max(buttonRadius, min(screenHeight - buttonRadius - tabBarHeight, newPosition.y)) // Avoid floating tab bar
                }
                .onEnded { _ in
                    isDragging = false
                    // Don't snap to edges - let user position it anywhere
                    
                    // Save the new position to UserDefaults
                    UserDefaults.standard.set(position.x, forKey: "FloatingButtonPositionX")
                    UserDefaults.standard.set(position.y, forKey: "FloatingButtonPositionY")
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
    }
    

}