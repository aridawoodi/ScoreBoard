//
//  UserSpecificStorageManager.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 12/19/25.
//

import Foundation
import Amplify

// MARK: - User-Specific Storage Manager
class UserSpecificStorageManager {
    static let shared = UserSpecificStorageManager()
    
    private init() {}
    
    // MARK: - Current User Management
    
    /// Get the current user ID for storage operations
    private func getCurrentUserId() -> String? {
        // Check if we're in guest mode
        let isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
        
        if isGuestUser {
            // Handle guest user
            let guestUserId = UserDefaults.standard.string(forKey: "current_guest_user_id") ?? ""
            return guestUserId.isEmpty ? nil : guestUserId
        } else {
            // For authenticated users, get from UserDefaults (set during sign-in)
            let authUserId = UserDefaults.standard.string(forKey: "authenticated_user_id")
            if let userId = authUserId, !userId.isEmpty {
                return userId
            }
            
            // If not found in UserDefaults, return nil
            // The async fallback should be handled by the calling code
            return nil
        }
    }
    
    /// Get the current user ID asynchronously (with fallback to auth session)
    private func getCurrentUserIdAsync() async -> String? {
        // First try the synchronous method
        if let userId = getCurrentUserId() {
            return userId
        }
        
        // If not found, try to get from Amplify Auth session
        do {
            let user = try await Amplify.Auth.getCurrentUser()
            let userId = user.userId
            // Store it in UserDefaults for future use
            UserDefaults.standard.set(userId, forKey: "authenticated_user_id")
            return userId
        } catch {
            print("🔍 DEBUG: UserSpecificStorageManager - Failed to get current user: \(error)")
        }
        
        return nil
    }
    
    // MARK: - User-Specific Key Generation
    
    /// Generate a user-specific key for storage
    private func getUserSpecificKey(_ baseKey: String, userId: String) -> String {
        return "\(baseKey)_\(userId)"
    }
    
    /// Generate a user-specific key for the current user
    private func getCurrentUserSpecificKey(_ baseKey: String) -> String? {
        guard let userId = getCurrentUserId() else {
            print("🔍 DEBUG: UserSpecificStorageManager - No current user ID found for key: \(baseKey)")
            return nil
        }
        return getUserSpecificKey(baseKey, userId: userId)
    }
    
    // MARK: - Generic Storage Operations
    
    /// Save data for the current user
    func saveData<T: Codable>(_ data: T, forKey baseKey: String) {
        guard let userSpecificKey = getCurrentUserSpecificKey(baseKey) else { return }
        
        do {
            let encodedData = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encodedData, forKey: userSpecificKey)
            print("🔍 DEBUG: UserSpecificStorageManager - Saved data for key: \(userSpecificKey)")
        } catch {
            print("🔍 DEBUG: UserSpecificStorageManager - Failed to save data for key: \(userSpecificKey), error: \(error)")
        }
    }
    
    /// Load data for the current user
    func loadData<T: Codable>(_ type: T.Type, forKey baseKey: String) -> T? {
        guard let userSpecificKey = getCurrentUserSpecificKey(baseKey) else { return nil }
        
        guard let data = UserDefaults.standard.data(forKey: userSpecificKey) else {
            print("🔍 DEBUG: UserSpecificStorageManager - No data found for key: \(userSpecificKey)")
            return nil
        }
        
        do {
            let decodedData = try JSONDecoder().decode(type, from: data)
            print("🔍 DEBUG: UserSpecificStorageManager - Loaded data for key: \(userSpecificKey)")
            return decodedData
        } catch {
            print("🔍 DEBUG: UserSpecificStorageManager - Failed to load data for key: \(userSpecificKey), error: \(error)")
            return nil
        }
    }
    
    /// Load data for the current user (async version with fallback)
    func loadDataAsync<T: Codable>(_ type: T.Type, forKey baseKey: String) async -> T? {
        // First try the synchronous method
        if let data = loadData(type, forKey: baseKey) {
            return data
        }
        
        // If not found and we're an authenticated user, try to get user ID from auth session
        let isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
        if !isGuestUser {
            if let userId = await getCurrentUserIdAsync() {
                let userSpecificKey = getUserSpecificKey(baseKey, userId: userId)
                
                guard let data = UserDefaults.standard.data(forKey: userSpecificKey) else {
                    print("🔍 DEBUG: UserSpecificStorageManager - No data found for key: \(userSpecificKey)")
                    return nil
                }
                
                do {
                    let decodedData = try JSONDecoder().decode(type, from: data)
                    print("🔍 DEBUG: UserSpecificStorageManager - Loaded data for key: \(userSpecificKey)")
                    return decodedData
                } catch {
                    print("🔍 DEBUG: UserSpecificStorageManager - Failed to load data for key: \(userSpecificKey), error: \(error)")
                    return nil
                }
            }
        }
        
        return nil
    }
    
    /// Check if data exists for the current user
    func hasData(forKey baseKey: String) -> Bool {
        guard let userSpecificKey = getCurrentUserSpecificKey(baseKey) else { return false }
        return UserDefaults.standard.data(forKey: userSpecificKey) != nil
    }
    
    /// Clear data for the current user
    func clearData(forKey baseKey: String) {
        guard let userSpecificKey = getCurrentUserSpecificKey(baseKey) else { return }
        UserDefaults.standard.removeObject(forKey: userSpecificKey)
        print("🔍 DEBUG: UserSpecificStorageManager - Cleared data for key: \(userSpecificKey)")
    }
    
    // MARK: - User Switching Operations
    
    /// Save current user's data before switching users
    func saveCurrentUserData() {
        guard let currentUserId = getCurrentUserId() else {
            print("🔍 DEBUG: UserSpecificStorageManager - No current user to save data for")
            return
        }
        
        print("🔍 DEBUG: UserSpecificStorageManager - Saving data for current user: \(currentUserId)")
        
        // Save default game settings if they exist
        if let defaultSettings = DefaultGameSettingsStorage.shared.loadDefaultGameSettings() {
            let key = getUserSpecificKey("default_game_settings", userId: currentUserId)
            do {
                let data = try JSONEncoder().encode(defaultSettings)
                UserDefaults.standard.set(data, forKey: key)
                print("🔍 DEBUG: UserSpecificStorageManager - Saved default game settings for user: \(currentUserId)")
            } catch {
                print("🔍 DEBUG: UserSpecificStorageManager - Failed to save default game settings for user: \(currentUserId), error: \(error)")
            }
        }
        
        // Save last game settings if they exist
        if let lastSettings = GameSettingsStorage.shared.loadLastGameSettings() {
            let key = getUserSpecificKey("last_game_settings", userId: currentUserId)
            do {
                let data = try JSONEncoder().encode(lastSettings)
                UserDefaults.standard.set(data, forKey: key)
                print("🔍 DEBUG: UserSpecificStorageManager - Saved last game settings for user: \(currentUserId)")
            } catch {
                print("🔍 DEBUG: UserSpecificStorageManager - Failed to save last game settings for user: \(currentUserId), error: \(error)")
            }
        }
        
        // Save game templates if they exist
        let templates = GameSettingsStorage.shared.loadGameTemplates()
        if !templates.isEmpty {
            let key = getUserSpecificKey("saved_game_templates", userId: currentUserId)
            do {
                let data = try JSONEncoder().encode(templates)
                UserDefaults.standard.set(data, forKey: key)
                print("🔍 DEBUG: UserSpecificStorageManager - Saved game templates for user: \(currentUserId)")
            } catch {
                print("🔍 DEBUG: UserSpecificStorageManager - Failed to save game templates for user: \(currentUserId), error: \(error)")
            }
        }
    }
    
    /// Load new user's data after switching users
    func loadNewUserData() {
        guard let newUserId = getCurrentUserId() else {
            print("🔍 DEBUG: UserSpecificStorageManager - No new user to load data for")
            return
        }
        
        print("🔍 DEBUG: UserSpecificStorageManager - Loading data for new user: \(newUserId)")
        
        // Load default game settings
        let defaultKey = getUserSpecificKey("default_game_settings", userId: newUserId)
        if let data = UserDefaults.standard.data(forKey: defaultKey) {
            do {
                let defaultSettings = try JSONDecoder().decode(DefaultGameSettings.self, from: data)
                // Temporarily store in the old key for backward compatibility
                UserDefaults.standard.set(data, forKey: "default_game_settings")
                print("🔍 DEBUG: UserSpecificStorageManager - Loaded default game settings for user: \(newUserId)")
            } catch {
                print("🔍 DEBUG: UserSpecificStorageManager - Failed to load default game settings for user: \(newUserId), error: \(error)")
            }
        } else {
            // Clear the old key if no user-specific data exists
            UserDefaults.standard.removeObject(forKey: "default_game_settings")
            print("🔍 DEBUG: UserSpecificStorageManager - No default game settings found for user: \(newUserId)")
        }
        
        // Load last game settings
        let lastKey = getUserSpecificKey("last_game_settings", userId: newUserId)
        if let data = UserDefaults.standard.data(forKey: lastKey) {
            do {
                let lastSettings = try JSONDecoder().decode(GameSettings.self, from: data)
                // Temporarily store in the old key for backward compatibility
                UserDefaults.standard.set(data, forKey: "last_game_settings")
                print("🔍 DEBUG: UserSpecificStorageManager - Loaded last game settings for user: \(newUserId)")
            } catch {
                print("🔍 DEBUG: UserSpecificStorageManager - Failed to load last game settings for user: \(newUserId), error: \(error)")
            }
        } else {
            // Clear the old key if no user-specific data exists
            UserDefaults.standard.removeObject(forKey: "last_game_settings")
            print("🔍 DEBUG: UserSpecificStorageManager - No last game settings found for user: \(newUserId)")
        }
        
        // Load game templates
        let templatesKey = getUserSpecificKey("saved_game_templates", userId: newUserId)
        if let data = UserDefaults.standard.data(forKey: templatesKey) {
            do {
                let templates = try JSONDecoder().decode([String: GameSettings].self, from: data)
                // Temporarily store in the old key for backward compatibility
                UserDefaults.standard.set(data, forKey: "saved_game_templates")
                print("🔍 DEBUG: UserSpecificStorageManager - Loaded game templates for user: \(newUserId)")
            } catch {
                print("🔍 DEBUG: UserSpecificStorageManager - Failed to load game templates for user: \(newUserId), error: \(error)")
            }
        } else {
            // Clear the old key if no user-specific data exists
            UserDefaults.standard.removeObject(forKey: "saved_game_templates")
            print("🔍 DEBUG: UserSpecificStorageManager - No game templates found for user: \(newUserId)")
        }
    }
    
    // MARK: - Migration Support
    
    /// Migrate existing data to user-specific storage
    func migrateExistingData() {
        guard let currentUserId = getCurrentUserId() else { return }
        
        print("🔍 DEBUG: UserSpecificStorageManager - Migrating existing data for user: \(currentUserId)")
        
        // Migrate default game settings
        if let data = UserDefaults.standard.data(forKey: "default_game_settings") {
            let userSpecificKey = getUserSpecificKey("default_game_settings", userId: currentUserId)
            UserDefaults.standard.set(data, forKey: userSpecificKey)
            print("🔍 DEBUG: UserSpecificStorageManager - Migrated default game settings")
        }
        
        // Migrate last game settings
        if let data = UserDefaults.standard.data(forKey: "last_game_settings") {
            let userSpecificKey = getUserSpecificKey("last_game_settings", userId: currentUserId)
            UserDefaults.standard.set(data, forKey: userSpecificKey)
            print("🔍 DEBUG: UserSpecificStorageManager - Migrated last game settings")
        }
        
        // Migrate game templates
        if let data = UserDefaults.standard.data(forKey: "saved_game_templates") {
            let userSpecificKey = getUserSpecificKey("saved_game_templates", userId: currentUserId)
            UserDefaults.standard.set(data, forKey: userSpecificKey)
            print("🔍 DEBUG: UserSpecificStorageManager - Migrated game templates")
        }
    }
}
