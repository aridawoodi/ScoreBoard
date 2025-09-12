import Foundation
import SwiftUI

class UsernameCacheService: ObservableObject {
    static let shared = UsernameCacheService()
    
    @Published var isLoading = false
    @Published var cachedUsernames: [String: String] = [:]
    @Published var currentUserUsername: String?
    
    private let storageManager = UserSpecificStorageManager.shared
    private let currentUserUsernameKey = "current_user_username"
    
    private init() {
        // Load cached username from persistent storage on init
        loadCurrentUserUsernameFromStorage()
    }
    
    func getUsernames(for playerIDs: [String]) async -> [String: String] {
        await MainActor.run {
            self.isLoading = true
        }
        
        // Filter out player IDs we already have cached
        let uncachedIDs = playerIDs.filter { !cachedUsernames.keys.contains($0) }
        
        if !uncachedIDs.isEmpty {
            // Fetch usernames for uncached IDs
            let newUsernames = await fetchUsernames(for: uncachedIDs)
            
            await MainActor.run {
                self.cachedUsernames.merge(newUsernames) { _, new in new }
                self.isLoading = false
            }
        } else {
            await MainActor.run {
                self.isLoading = false
            }
        }
        
        return cachedUsernames
    }
    
    func getDisplayName(for playerID: String) -> String {
        if let cachedName = cachedUsernames[playerID] {
            // If we have a cached username, use it as is
            print("🔍 DEBUG: UsernameCacheService - Using cached name for \(playerID): \(cachedName)")
            return cachedName
        } else {
            // Use the same logic as DataManager.getPlayerName for consistency
            let displayName = getPlayerNameFromID(playerID)
            print("🔍 DEBUG: UsernameCacheService - Generated display name for \(playerID): \(displayName)")
            return displayName
        }
    }
    
    private func getPlayerNameFromID(_ playerID: String) -> String {
        if playerID.contains(":") {
            // Anonymous user with format "userID:displayName" - use display name
            let components = playerID.split(separator: ":", maxSplits: 1)
            if components.count == 2 {
                return String(components[1])
            }
        }
        
        // For registered users, check if we have a cached username
        if let cachedUsername = cachedUsernames[playerID] {
            return cachedUsername
        }
        
        // Fallback to short ID if no cached username
        return String(playerID.prefix(8))
    }
    
    private func fetchUsernames(for playerIDs: [String]) async -> [String: String] {
        var usernames: [String: String] = [:]
        
        // Get usernames from DataManager for registered users
        let dataManager = DataManager.shared
        
        for playerID in playerIDs {
            let displayName: String
            
            if playerID.contains(":") {
                // Anonymous user with format "userID:displayName" - use display name
                let components = playerID.split(separator: ":", maxSplits: 1)
                if components.count == 2 {
                    displayName = String(components[1])
                } else {
                    displayName = String(playerID.prefix(8))
                }
            } else if playerID.hasPrefix("guest_") {
                // Guest user - try to get from DataManager first
                if let user = dataManager.getUser(playerID) {
                    displayName = user.username ?? String(playerID.prefix(8))
                } else {
                    displayName = String(playerID.prefix(8))
                }
            } else if playerID.count > 20 && playerID.contains("-") {
                // Cognito authenticated user (UUID format) - try to get from DataManager
                if let user = dataManager.getUser(playerID) {
                    displayName = user.username ?? String(playerID.prefix(8))
                } else {
                    displayName = String(playerID.prefix(8))
                }
            } else {
                // Simple display name (like "Team 1", "Team 2") - use directly
                displayName = playerID
            }
            
            usernames[playerID] = displayName
            print("🔍 DEBUG: UsernameCacheService - Fetched username for \(playerID): \(displayName)")
        }
        
        return usernames
    }
    
    // MARK: - Current User Username Management
    
    /// Get the current user's username from cache (fastest)
    func getCurrentUserUsername() -> String? {
        return currentUserUsername
    }
    
    /// Cache the current user's username both in memory and persistent storage
    func cacheCurrentUserUsername(_ username: String) {
        print("🔍 DEBUG: UsernameCacheService - Caching current user username: \(username)")
        
        // Update in-memory cache
        currentUserUsername = username
        
        // Save to persistent storage
        storageManager.saveData(username, forKey: currentUserUsernameKey)
    }
    
    /// Load current user username from persistent storage
    private func loadCurrentUserUsernameFromStorage() {
        if let cachedUsername: String = storageManager.loadData(String.self, forKey: currentUserUsernameKey) {
            print("🔍 DEBUG: UsernameCacheService - Loaded cached username from storage: \(cachedUsername)")
            currentUserUsername = cachedUsername
        } else {
            print("🔍 DEBUG: UsernameCacheService - No cached username found in storage")
        }
    }
    
    /// Clear current user username cache (useful for logout)
    func clearCurrentUserUsername() {
        print("🔍 DEBUG: UsernameCacheService - Clearing current user username cache")
        currentUserUsername = nil
        storageManager.clearData(forKey: currentUserUsernameKey)
    }
    
    /// Update current user username when profile is updated
    func updateCurrentUserUsername(_ newUsername: String) {
        print("🔍 DEBUG: UsernameCacheService - Updating current user username: \(newUsername)")
        cacheCurrentUserUsername(newUsername)
    }
} 