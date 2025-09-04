//
//  DefaultGameSettings.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 12/19/25.
//

import Foundation

// MARK: - Default Game Settings Model
struct DefaultGameSettings: Codable {
    var winCondition: WinCondition
    var maxScore: Int
    var maxRounds: Int
    var customRules: String
    var hostJoinAsPlayer: Bool
    var useAsDefault: Bool
    var lastUpdated: Date
    
    init(
        winCondition: WinCondition = .highestScore,
        maxScore: Int = 100,
        maxRounds: Int = 8,
        customRules: String = "",
        hostJoinAsPlayer: Bool = true,
        useAsDefault: Bool = false,
        lastUpdated: Date = Date()
    ) {
        self.winCondition = winCondition
        self.maxScore = maxScore
        self.maxRounds = maxRounds
        self.customRules = customRules
        self.hostJoinAsPlayer = hostJoinAsPlayer
        self.useAsDefault = useAsDefault
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Default Game Settings Storage Service
class DefaultGameSettingsStorage {
    static let shared = DefaultGameSettingsStorage()
    
    private let defaultGameSettingsKey = "default_game_settings"
    
    private init() {}
    
    // MARK: - Save Default Settings
    
    /// Save default game settings to UserDefaults
    func saveDefaultGameSettings(_ settings: DefaultGameSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: defaultGameSettingsKey)
            print("🔍 DEBUG: Saved default game settings - winCondition: \(settings.winCondition), maxScore: \(settings.maxScore), useAsDefault: \(settings.useAsDefault)")
        } catch {
            print("🔍 DEBUG: Failed to save default game settings: \(error)")
        }
    }
    
    // MARK: - Load Default Settings
    
    /// Load default game settings from UserDefaults
    func loadDefaultGameSettings() -> DefaultGameSettings? {
        guard let data = UserDefaults.standard.data(forKey: defaultGameSettingsKey) else {
            print("🔍 DEBUG: No default game settings found")
            return nil
        }
        
        do {
            let settings = try JSONDecoder().decode(DefaultGameSettings.self, from: data)
            print("🔍 DEBUG: Loaded default game settings - winCondition: \(settings.winCondition), maxScore: \(settings.maxScore), useAsDefault: \(settings.useAsDefault)")
            return settings
        } catch {
            print("🔍 DEBUG: Failed to load default game settings: \(error)")
            return nil
        }
    }
    
    // MARK: - Check Default Settings
    
    /// Check if there are saved default game settings
    func hasDefaultGameSettings() -> Bool {
        return UserDefaults.standard.data(forKey: defaultGameSettingsKey) != nil
    }
    
    /// Check if default settings are enabled and available
    func hasEnabledDefaultSettings() -> Bool {
        guard let settings = loadDefaultGameSettings() else { return false }
        return settings.useAsDefault
    }
    
    // MARK: - Clear Default Settings
    
    /// Clear the default game settings
    func clearDefaultGameSettings() {
        UserDefaults.standard.removeObject(forKey: defaultGameSettingsKey)
        print("🔍 DEBUG: Cleared default game settings")
    }
    
    /// Disable default settings without clearing them
    func disableDefaultSettings() {
        guard var settings = loadDefaultGameSettings() else { return }
        settings.useAsDefault = false
        saveDefaultGameSettings(settings)
        print("🔍 DEBUG: Disabled default game settings")
    }
    
    // MARK: - Update Default Settings
    
    /// Update default settings with new values
    func updateDefaultSettings(
        winCondition: WinCondition? = nil,
        maxScore: Int? = nil,
        maxRounds: Int? = nil,
        customRules: String? = nil,
        hostJoinAsPlayer: Bool? = nil,
        useAsDefault: Bool? = nil
    ) {
        var settings = loadDefaultGameSettings() ?? DefaultGameSettings()
        
        if let winCondition = winCondition {
            settings.winCondition = winCondition
        }
        if let maxScore = maxScore {
            settings.maxScore = maxScore
        }
        if let maxRounds = maxRounds {
            settings.maxRounds = maxRounds
        }
        if let customRules = customRules {
            settings.customRules = customRules
        }
        if let hostJoinAsPlayer = hostJoinAsPlayer {
            settings.hostJoinAsPlayer = hostJoinAsPlayer
        }
        if let useAsDefault = useAsDefault {
            settings.useAsDefault = useAsDefault
        }
        
        settings.lastUpdated = Date()
        saveDefaultGameSettings(settings)
    }
}
