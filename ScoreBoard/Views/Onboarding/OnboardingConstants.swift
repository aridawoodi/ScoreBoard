//
//  OnboardingConstants.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation

// MARK: - Onboarding Constants
struct OnboardingConstants {
    
    // MARK: - UserDefaults Keys
    static let hasSeenOnboardingKey = "hasSeenOnboarding"
    
    // MARK: - Tooltip Messages
    struct Messages {
        static let welcomeTitle = "Welcome to ScoreBoard! 🎯"
        static let welcomeMessage = "You don't have any games yet. Tap the 'Create Scoreboard' tab (the + icon) to start your first game and invite friends to play!"
        
        static let createGameTitle = "Create Your First Game! 🎮"
        static let createGameMessage = "Set up a new scoreboard game. Choose the number of rounds, add players, and customize rules. Share the game code with friends to invite them!"
        
        static let joinGameTitle = "Join a Game! 🎯"
        static let joinGameMessage = "Enter a 6-digit game code to join an existing scoreboard. Ask your friends for their game code to start playing together!"
    }
    
    // MARK: - Button Text
    struct Buttons {
        static let createGame = "Create Game"
        static let joinGame = "Join Game"
        static let getStarted = "Get Started"
        static let maybeLater = "Maybe Later"
        static let skip = "Skip"
    }
    
    // MARK: - Animation Durations
    struct Animation {
        static let tooltipDelay: TimeInterval = 0.5
        static let tooltipAppearDelay: TimeInterval = 1.0
        static let animationDuration: TimeInterval = 0.3
    }
}
