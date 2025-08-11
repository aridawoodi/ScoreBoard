import Foundation
import SwiftUI

class UsernameCacheService: ObservableObject {
    static let shared = UsernameCacheService()
    
    @Published var isLoading = false
    @Published var cachedUsernames: [String: String] = [:]
    
    private init() {}
    
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
        return cachedUsernames[playerID] ?? "Player \(String(playerID.prefix(6)))"
    }
    
    private func fetchUsernames(for playerIDs: [String]) async -> [String: String] {
        // For now, return a simple mapping
        // In a real app, this would fetch from your backend
        var usernames: [String: String] = [:]
        
        for playerID in playerIDs {
            // Generate a simple display name based on the player ID
            let displayName = "Player \(String(playerID.prefix(6)))"
            usernames[playerID] = displayName
        }
        
        return usernames
    }
} 