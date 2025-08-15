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
                            Text("\(navigationState.gameCount) Board\(navigationState.gameCount == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(navigationState.hasGames ? .green : .secondary)
                            Text("\(navigationState.gameCount)")
                                .font(.caption.bold())
                                .foregroundColor(navigationState.hasGames ? .green : .secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(navigationState.hasGames ? Color.green : Color(.systemGray4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
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
                            Text("Enter a game code to join")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.blue)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
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
                            Text("View all players and their scores")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.purple)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.purple, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Join Scoreboard")
            .navigationBarTitleDisplayMode(.inline)
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