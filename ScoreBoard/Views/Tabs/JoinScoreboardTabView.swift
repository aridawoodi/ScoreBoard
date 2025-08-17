//
//  JoinScoreboardTabView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI

// MARK: - Join Scoreboard Tab View
struct JoinScoreboardTabView: View {
    @ObservedObject var navigationState: NavigationState
    @Binding var showJoinGame: Bool
    @Binding var showGameSelection: Bool
    @Binding var selectedTab: Int
    @State private var showPlayerLeaderboard = false
    @StateObject private var onboardingManager = OnboardingManager()
    @State private var showJoinGameTooltip = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                
                // My Scoreboards Button
                let strokeColor: Color = navigationState.hasGames ? Color.green : Color.white.opacity(0.3)
                Button(action: {
                    // Force refresh user games before checking
                    Task {
                        await navigationState.refreshUserGames()
                    }
                    
                    if navigationState.gameCount == 1 {
                        navigationState.selectedGame = navigationState.userGames.first
                        selectedTab = 2 // Switch to Your Board
                    } else if navigationState.gameCount > 1 {
                        showGameSelection = true
                    } else {
                        // No games - show empty state or create new game
                        showJoinGame = true
                    }
                }) {
                    HStack {
                        Image("logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                        VStack(alignment: .leading) {
                            Text("My Scoreboards")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("\(navigationState.gameCount) Board\(navigationState.gameCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            let chevronColor: Color = navigationState.hasGames ? .green : .white.opacity(0.7)
                            let countColor: Color = navigationState.hasGames ? .green : .white.opacity(0.7)
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(chevronColor)
                            Text("\(navigationState.gameCount)")
                                .font(.caption.bold())
                                .foregroundColor(countColor)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.1), value: true)
                
                // Join a Board Button
                Button(action: {
                    showJoinGame = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Join a Board")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Enter a game code to join")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.1), value: true)
                
                // Player Leaderboard Button
                Button(action: {
                    showPlayerLeaderboard = true
                }) {
                    HStack {
                        Image(systemName: "list.number")
                            .font(.title2)
                            .foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text("Player Leaderboard")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("View all players and their scores")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.1), value: true)
                
                Spacer()
            }
            .padding()
            .gradientBackground()
            .refreshable {
                // Pull to refresh functionality
                await navigationState.refreshUserGames()
            }
            .sheet(isPresented: $showPlayerLeaderboard) {
                PlayerLeaderboardView()
            }
            .onAppear {
                // Show join game tooltip for new users with no games
                if !navigationState.hasGames && !onboardingManager.hasSeenOnboarding {
                    DispatchQueue.main.asyncAfter(deadline: .now() + OnboardingConstants.Animation.tooltipDelay) {
                        showJoinGameTooltip = true
                    }
                }
            }
        }
        .overlay {
            if showJoinGameTooltip {
                OnboardingTooltip(
                    title: OnboardingConstants.Messages.joinGameTitle,
                    message: OnboardingConstants.Messages.joinGameMessage,
                    actionText: OnboardingConstants.Buttons.joinGame,
                    dismissText: OnboardingConstants.Buttons.skip
                ) {
                    showJoinGame = true
                } onDismiss: {
                    showJoinGameTooltip = false
                    onboardingManager.markOnboardingAsSeen()
                }
            }
        }
    }
} 