//
//  YourBoardTabView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI

// MARK: - Your Board Tab View
struct YourBoardTabView: View {
    @Binding var navigationState: NavigationState
    @Binding var selectedTab: Int
    @StateObject private var onboardingManager = OnboardingManager()
    @State private var showOnboardingTooltip = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if let selectedGame = navigationState.selectedGame {
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
                        // When a game disappears on backend, clear selection so empty state shows
                        navigationState.selectedGame = nil
                        Task { await navigationState.refreshUserGames() }
                    }

                } else if let latestGame = navigationState.latestGame {
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
                        // When latest is deleted, refresh list and allow empty state to appear
                        navigationState.selectedGame = nil
                        Task { await navigationState.refreshUserGames() }
                    }
                    .id(latestGame.id) // Prevent recreation when switching tabs
                } else {
                    // No games - show empty state
                    VStack(spacing: 20) {
                        // Replaced SF Symbol with app logo icon used in the tab
                        AppLogoIcon(isSelected: false, size: 80)
                            .padding(.top, 40)
                        
                        Text("Your Board")
                            .font(.largeTitle.bold())
                            .padding(.top, 16)
                        
                        Text("This is your main board. Use the tabs below to create or join games.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                print("🔍 DEBUG: ===== YOUR BOARD TAB ON APPEAR =====")
                print("🔍 DEBUG: selectedGame: \(navigationState.selectedGame?.id ?? "nil")")
                print("🔍 DEBUG: latestGame: \(navigationState.latestGame?.id ?? "nil")")
                print("🔍 DEBUG: userGames count: \(navigationState.userGames.count)")
                
                // Auto-select the latest game if no game is currently selected
                if navigationState.selectedGame == nil && navigationState.latestGame != nil {
                    print("🔍 DEBUG: Auto-selecting latest game: \(navigationState.latestGame!.id)")
                    navigationState.selectedGame = navigationState.latestGame
                } else {
                    print("🔍 DEBUG: No auto-selection needed")
                }
                
                // Show onboarding tooltip for new users with no games
                if !navigationState.hasGames && !onboardingManager.hasSeenOnboarding {
                    DispatchQueue.main.asyncAfter(deadline: .now() + OnboardingConstants.Animation.tooltipAppearDelay) {
                        showOnboardingTooltip = true
                    }
                }
                
                print("🔍 DEBUG: ===== YOUR BOARD TAB ON APPEAR END =====")
            }
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
