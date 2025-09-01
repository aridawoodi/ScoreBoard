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
    
    private init() {}
    
    // MARK: - Last Game Settings
    
    /// Save the last used game settings
    func saveLastGameSettings(_ settings: GameSettings) {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: lastGameSettingsKey)
            print("🔍 DEBUG: Saved last game settings: \(settings.gameName)")
        } catch {
            print("🔍 DEBUG: Failed to save last game settings: \(error)")
        }
    }
    
    /// Load the last used game settings
    func loadLastGameSettings() -> GameSettings? {
        guard let data = UserDefaults.standard.data(forKey: lastGameSettingsKey) else {
            print("🔍 DEBUG: No last game settings found")
            return nil
        }
        
        do {
            let settings = try JSONDecoder().decode(GameSettings.self, from: data)
            print("🔍 DEBUG: Loaded last game settings: \(settings.gameName)")
            return settings
        } catch {
            print("🔍 DEBUG: Failed to load last game settings: \(error)")
            return nil
        }
    }
    
    /// Check if there are saved last game settings
    func hasLastGameSettings() -> Bool {
        return UserDefaults.standard.data(forKey: lastGameSettingsKey) != nil
    }
    
    /// Clear the last game settings
    func clearLastGameSettings() {
        UserDefaults.standard.removeObject(forKey: lastGameSettingsKey)
        print("🔍 DEBUG: Cleared last game settings")
    }
    
    // MARK: - Game Templates
    
    /// Save a game template
    func saveGameTemplate(_ settings: GameSettings, name: String) {
        var templates = loadGameTemplates()
        templates[name] = settings
        
        do {
            let data = try JSONEncoder().encode(templates)
            UserDefaults.standard.set(data, forKey: savedTemplatesKey)
            print("🔍 DEBUG: Saved game template: \(name)")
        } catch {
            print("🔍 DEBUG: Failed to save game template: \(error)")
        }
    }
    
    /// Load all game templates
    func loadGameTemplates() -> [String: GameSettings] {
        guard let data = UserDefaults.standard.data(forKey: savedTemplatesKey) else {
            return [:]
        }
        
        do {
            let templates = try JSONDecoder().decode([String: GameSettings].self, from: data)
            print("🔍 DEBUG: Loaded \(templates.count) game templates")
            return templates
        } catch {
            print("🔍 DEBUG: Failed to load game templates: \(error)")
            return [:]
        }
    }
    
    /// Delete a game template
    func deleteGameTemplate(_ name: String) {
        var templates = loadGameTemplates()
        templates.removeValue(forKey: name)
        
        do {
            let data = try JSONEncoder().encode(templates)
            UserDefaults.standard.set(data, forKey: savedTemplatesKey)
            print("🔍 DEBUG: Deleted game template: \(name)")
        } catch {
            print("🔍 DEBUG: Failed to delete game template: \(error)")
        }
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
