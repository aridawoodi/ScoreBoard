//
//  ProfileSetupManager.swift
//  ScoreBoard
//
//  Created by AI Assistant
//

import Foundation

/// Manages first-time profile setup state and tracking
class ProfileSetupManager {
    static let shared = ProfileSetupManager()
    
    private init() {}
    
    // MARK: - UserDefaults Keys
    
    private func profileSetupKey(for userId: String) -> String {
        return "has_completed_profile_setup_\(userId)"
    }
    
    private func profileSkippedKey(for userId: String) -> String {
        return "has_skipped_profile_setup_\(userId)"
    }
    
    private func usernameValidatedKey(for userId: String) -> String {
        return "profile_username_validated_\(userId)"
    }
    
    // MARK: - Setup Completion Tracking
    
    /// Checks if user has completed profile setup
    func hasCompletedSetup(userId: String) -> Bool {
        let key = profileSetupKey(for: userId)
        return UserDefaults.standard.bool(forKey: key)
    }
    
    /// Marks profile setup as completed for a user
    func markSetupCompleted(userId: String) {
        print("🔍 DEBUG: ProfileSetupManager - Marking setup completed for user: \(userId)")
        let key = profileSetupKey(for: userId)
        UserDefaults.standard.set(true, forKey: key)
        
        // Also mark username as validated
        let usernameKey = usernameValidatedKey(for: userId)
        UserDefaults.standard.set(true, forKey: usernameKey)
        
        // Clear skip flag if it was set
        let skipKey = profileSkippedKey(for: userId)
        UserDefaults.standard.removeObject(forKey: skipKey)
        
        UserDefaults.standard.synchronize()
        print("🔍 DEBUG: ProfileSetupManager - Setup marked as completed")
    }
    
    /// Checks if user has skipped profile setup
    func hasSkippedSetup(userId: String) -> Bool {
        let key = profileSkippedKey(for: userId)
        return UserDefaults.standard.bool(forKey: key)
    }
    
    /// Marks profile setup as skipped for a user
    func markSetupSkipped(userId: String) {
        print("🔍 DEBUG: ProfileSetupManager - Marking setup skipped for user: \(userId)")
        let key = profileSkippedKey(for: userId)
        UserDefaults.standard.set(true, forKey: key)
        UserDefaults.standard.synchronize()
        print("🔍 DEBUG: ProfileSetupManager - Setup marked as skipped")
    }
    
    /// Checks if username has been validated
    func isUsernameValidated(userId: String) -> Bool {
        let key = usernameValidatedKey(for: userId)
        return UserDefaults.standard.bool(forKey: key)
    }
    
    /// Clears all setup flags for a user (useful for logout)
    func clearSetupFlags(userId: String) {
        print("🔍 DEBUG: ProfileSetupManager - Clearing setup flags for user: \(userId)")
        let setupKey = profileSetupKey(for: userId)
        let skipKey = profileSkippedKey(for: userId)
        let usernameKey = usernameValidatedKey(for: userId)
        
        UserDefaults.standard.removeObject(forKey: setupKey)
        UserDefaults.standard.removeObject(forKey: skipKey)
        UserDefaults.standard.removeObject(forKey: usernameKey)
        UserDefaults.standard.synchronize()
        print("🔍 DEBUG: ProfileSetupManager - Setup flags cleared")
    }
    
    // MARK: - Setup Requirement Check
    
    /// Determines if user needs to see the profile setup screen
    /// - Parameter userId: The user ID to check
    /// - Returns: True if setup is required, false otherwise
    func needsProfileSetup(userId: String) async -> Bool {
        print("🔍 DEBUG: ProfileSetupManager - Checking if setup needed for user: \(userId)")
        
        // Check if already completed
        if hasCompletedSetup(userId: userId) {
            print("🔍 DEBUG: ProfileSetupManager - Setup already completed")
            return false
        }
        
        // Check if user has skipped setup
        if hasSkippedSetup(userId: userId) {
            print("🔍 DEBUG: ProfileSetupManager - Setup was skipped previously")
            return false
        }
        
        // Check if user has a valid custom username in the database
        if let user = await fetchUserProfile(userId: userId) {
            print("🔍 DEBUG: ProfileSetupManager - Found user profile with username: \(user.username)")
            
            // Check if username is default for authenticated users (starts with "Player")
            if user.username.hasPrefix("Player") {
                print("🔍 DEBUG: ProfileSetupManager - Username is default (Player prefix), setup required")
                return true
            }
            
            // Check if username is default for guest users (starts with "Yourself")
            if user.username.hasPrefix("Yourself") {
                print("🔍 DEBUG: ProfileSetupManager - Username is default (Yourself prefix), setup required")
                return true
            }
            
            // Check if username is the auto-generated format (Player + 5 chars)
            if user.username.count == 11 && user.username.hasPrefix("Player") {
                print("🔍 DEBUG: ProfileSetupManager - Username is auto-generated (Player format), setup required")
                return true
            }
            
            // Check if username is the auto-generated guest format (Yourself + 3 chars)
            if user.username.count == 11 && user.username.hasPrefix("Yourself") {
                print("🔍 DEBUG: ProfileSetupManager - Username is auto-generated (Yourself format), setup required")
                return true
            }
            
            // Username looks custom, automatically mark as complete
            print("🔍 DEBUG: ProfileSetupManager - Username is custom, auto-marking as complete")
            markSetupCompleted(userId: userId)
            return false
        }
        
        // No user profile found, needs setup
        print("🔍 DEBUG: ProfileSetupManager - No user profile found, setup required")
        return true
    }
    
    /// Fetches user profile from the database
    private func fetchUserProfile(userId: String) async -> User? {
        let userService = UserService.shared
        
        // Use UserService to load the profile
        await userService.loadCurrentUserProfile()
        
        // Check if the loaded user matches our userId on the main actor
        let user = await MainActor.run { userService.currentUser }
        
        if let user = user, user.id == userId {
            return user
        }
        
        return nil
    }
    
    // MARK: - Debug Helpers
    
    /// Prints current setup state for debugging
    func printSetupState(userId: String) {
        print("🔍 DEBUG: ===== PROFILE SETUP STATE =====")
        print("🔍 DEBUG: User ID: \(userId)")
        print("🔍 DEBUG: Has completed setup: \(hasCompletedSetup(userId: userId))")
        print("🔍 DEBUG: Has skipped setup: \(hasSkippedSetup(userId: userId))")
        print("🔍 DEBUG: Username validated: \(isUsernameValidated(userId: userId))")
        print("🔍 DEBUG: ================================")
    }
    
    /// Resets all setup states (for testing/debugging)
    func resetAllSetupStates() {
        print("🔍 DEBUG: ProfileSetupManager - Resetting ALL setup states")
        
        // Get all keys that match our patterns
        let defaults = UserDefaults.standard
        let allKeys = defaults.dictionaryRepresentation().keys
        
        for key in allKeys {
            if key.contains("has_completed_profile_setup_") ||
               key.contains("has_skipped_profile_setup_") ||
               key.contains("profile_username_validated_") {
                defaults.removeObject(forKey: key)
                print("🔍 DEBUG: ProfileSetupManager - Removed key: \(key)")
            }
        }
        
        defaults.synchronize()
        print("🔍 DEBUG: ProfileSetupManager - All setup states reset")
    }
}

