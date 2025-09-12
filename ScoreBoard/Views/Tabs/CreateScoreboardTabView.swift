//
//  CreateScoreboardTabView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI

// MARK: - Create Scoreboard Tab View
struct CreateScoreboardTabView: View {
    @ObservedObject var navigationState: NavigationState
    @Binding var showCreateGame: Bool
    @Binding var selectedTab: Int
    @StateObject private var onboardingManager = OnboardingManager()
    @State private var showCreateGameTooltip = false
    
    // Spotlight state
    @State private var showCreateButtonSpotlight = false
    @State private var createButtonApproxRect: CGRect = .zero
    
    var body: some View {
        VStack {
            CreateGameView(
                showCreateGame: $showCreateGame,
                mode: .create,
                onGameCreated: { game in
                    // Use standardized callback handling
                    Task {
                        await GameCreationUtils.handleGameCreated(
                            game: game,
                            navigationState: navigationState,
                            selectedTab: $selectedTab
                        )
                    }
                },
                onGameUpdated: nil
            )
                .gradientBackground()
                .onAppear {
                    // Precompute an approximate rect for the top-right "Create" toolbar button
                    createButtonApproxRect = approximateTopRightNavButtonRect()
            }
            .onAppear {
                // Show create game tooltip for new users
                if !onboardingManager.hasSeenOnboarding {
                    DispatchQueue.main.asyncAfter(deadline: .now() + OnboardingConstants.Animation.tooltipDelay) {
                        showCreateGameTooltip = true
                    }
                }
            }
        }
        .overlay {
            if showCreateGameTooltip {
                OnboardingTooltip(
                    title: OnboardingConstants.Messages.createGameTitle,
                    message: OnboardingConstants.Messages.createGameMessage,
                    actionText: OnboardingConstants.Buttons.getStarted,
                    dismissText: OnboardingConstants.Buttons.skip
                ) {
                    // Dismiss tooltip and show spotlight to guide user to the Create button
                    showCreateGameTooltip = false
                    onboardingManager.markOnboardingAsSeen()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showCreateButtonSpotlight = true
                    }
                } onDismiss: {
                    showCreateGameTooltip = false
                    onboardingManager.markOnboardingAsSeen()
                }
            }
        }
        .overlay {
            // Spotlight hint highlighting the top-right Create button area
            SpotlightOverlay(
                isVisible: $showCreateButtonSpotlight,
                targetRectGlobal: createButtonApproxRect,
                message: "Tap Create in the top-right to save and start your scoreboard.",
                dimOpacity: 0.05
            ) {
                // onDismiss
                showCreateButtonSpotlight = false
            }
        }
    }
    
    private func approximateTopRightNavButtonRect() -> CGRect {
        // Estimate the nav bar button location using screen bounds and safe area insets
        let screen = UIScreen.main.bounds
        let topInset = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
        // Typical nav bar height ~ 44, add safe area
        let navBarHeight: CGFloat = 44 + topInset
        let buttonSize = CGSize(width: 44, height: 36)
        let padding: CGFloat = 12
        let origin = CGPoint(
            x: screen.width - buttonSize.width - padding,
            y: (topInset > 0 ? topInset : 20) + (navBarHeight - buttonSize.height) / 2
        )
        return CGRect(origin: origin, size: buttonSize)
    }
} 