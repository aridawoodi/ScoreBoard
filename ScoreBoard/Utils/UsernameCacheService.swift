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
            return cachedName
        } else {
            // For fallback, just use the first 6 characters of the playerID
            return String(playerID.prefix(6))
        }
    }
    
    private func fetchUsernames(for playerIDs: [String]) async -> [String: String] {
        // For now, return a simple mapping
        // In a real app, this would fetch from your backend
        var usernames: [String: String] = [:]
        
        for playerID in playerIDs {
            // Just use the first 6 characters of the playerID without any prefix
            let displayName = String(playerID.prefix(6))
            usernames[playerID] = displayName
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