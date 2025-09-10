//
//  GameSettingsStorage.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation

// MARK: - Game Settings Model
struct GameSettings: Codable {
    var gameName: String
    var rounds: Int
    var winCondition: WinCondition
    var maxScore: Int
    var maxRounds: Int
    var customRules: String
    var playerNames: [String]
    var hostJoinAsPlayer: Bool
    var hostPlayerName: String
    
    init(
        gameName: String = "",
        rounds: Int = 3,
        winCondition: WinCondition = .highestScore,
        maxScore: Int = 100,
        maxRounds: Int = 10,
        customRules: String = "",
        playerNames: [String] = [],
        hostJoinAsPlayer: Bool = true,
        hostPlayerName: String = ""
    ) {
        self.gameName = gameName
        self.rounds = rounds
        self.winCondition = winCondition
        self.maxScore = maxScore
        self.maxRounds = maxRounds
        self.customRules = customRules
        self.playerNames = playerNames
        self.hostJoinAsPlayer = hostJoinAsPlayer
        self.hostPlayerName = hostPlayerName
    }
}

// MARK: - Game Settings Storage Service
class GameSettingsStorage {
    static let shared = GameSettingsStorage()
    
    private let lastGameSettingsKey = "last_game_settings"
    private let savedTemplatesKey = "saved_game_templates"
    
    private init() {
        // Migrate existing data to user-specific storage on first access
        UserSpecificStorageManager.shared.migrateExistingData()
    }
    
    // MARK: - Last Game Settings
    
    /// Save the last used game settings
    func saveLastGameSettings(_ settings: GameSettings) {
        // Use UserSpecificStorageManager for user-specific storage
        UserSpecificStorageManager.shared.saveData(settings, forKey: lastGameSettingsKey)
        print("🔍 DEBUG: Saved last game settings: \(settings.gameName)")
    }
    
    /// Load the last used game settings
    func loadLastGameSettings() -> GameSettings? {
        // Use UserSpecificStorageManager for user-specific storage
        let settings = UserSpecificStorageManager.shared.loadData(GameSettings.self, forKey: lastGameSettingsKey)
        if let settings = settings {
            print("🔍 DEBUG: Loaded last game settings: \(settings.gameName)")
        } else {
            print("🔍 DEBUG: No last game settings found")
        }
        return settings
    }
    
    /// Check if there are saved last game settings
    func hasLastGameSettings() -> Bool {
        return UserSpecificStorageManager.shared.hasData(forKey: lastGameSettingsKey)
    }
    
    /// Clear the last game settings
    func clearLastGameSettings() {
        UserSpecificStorageManager.shared.clearData(forKey: lastGameSettingsKey)
        print("🔍 DEBUG: Cleared last game settings")
    }
    
    // MARK: - Game Templates
    
    /// Save a game template
    func saveGameTemplate(_ settings: GameSettings, name: String) {
        var templates = loadGameTemplates()
        templates[name] = settings
        
        // Use UserSpecificStorageManager for user-specific storage
        UserSpecificStorageManager.shared.saveData(templates, forKey: savedTemplatesKey)
        print("🔍 DEBUG: Saved game template: \(name)")
    }
    
    /// Load all game templates
    func loadGameTemplates() -> [String: GameSettings] {
        // Use UserSpecificStorageManager for user-specific storage
        let templates = UserSpecificStorageManager.shared.loadData([String: GameSettings].self, forKey: savedTemplatesKey) ?? [:]
        print("🔍 DEBUG: Loaded \(templates.count) game templates")
        return templates
    }
    
    /// Delete a game template
    func deleteGameTemplate(_ name: String) {
        var templates = loadGameTemplates()
        templates.removeValue(forKey: name)
        
        // Use UserSpecificStorageManager for user-specific storage
        UserSpecificStorageManager.shared.saveData(templates, forKey: savedTemplatesKey)
        print("🔍 DEBUG: Deleted game template: \(name)")
    }
    
    /// Get template names
    func getTemplateNames() -> [String] {
        return Array(loadGameTemplates().keys).sorted()
    }
}

// MARK: - WinCondition Codable Extension
extension WinCondition: Codable {
    // This should already be handled by Amplify, but we'll add it here for safety
}
