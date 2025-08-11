//
//  OnboardingManager.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation
import SwiftUI

// MARK: - Onboarding Manager
class OnboardingManager: ObservableObject {
    @Published var showCreateGameTooltip = false
    @Published var showJoinGameTooltip = false
    @Published var showAnalyticsTooltip = false
    
    // UserDefaults key for tracking if user has seen onboarding
    private let hasSeenOnboardingKey = OnboardingConstants.hasSeenOnboardingKey
    
    var hasSeenOnboarding: Bool {
        UserDefaults.standard.bool(forKey: hasSeenOnboardingKey)
    }
    
    func markOnboardingAsSeen() {
        UserDefaults.standard.set(true, forKey: hasSeenOnboardingKey)
    }
    
    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: hasSeenOnboardingKey)
    }
}
