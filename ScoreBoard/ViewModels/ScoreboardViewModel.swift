//
//  ScoreboardViewModel.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/5/24.
//
import Foundation
import SwiftUI
import Amplify

class ScoreboardViewModel: ObservableObject {
    @Published var scores: [Score] = []
    @Published var roundScores: [String: [Int: Int]] = [:]  // [playerID: [roundNumber: score]]
    @Published var isSaving = false
    @Published var hasChanges = false
    
    // Track original scores to detect changes - made internal for access from ScoreRowView
    var originalScores: [String: [Int: Int]] = [:]
    
    // DataManager for efficient data access
    private let dataManager = DataManager.shared
    
    func getScoreForPlayer(_ playerID: String, round: Int) -> Int {
        return roundScores[playerID]?[round] ?? 0
    }
    
    func setScoreForPlayer(_ playerID: String, round: Int, score: Int) {
        if roundScores[playerID] == nil {
            roundScores[playerID] = [:]
        }
        roundScores[playerID]?[round] = score
        
        // Check if this represents a change from the original
        let originalScore = originalScores[playerID]?[round] ?? 0
        if score != originalScore {
            hasChanges = true
        } else {
            // Check if there are any other changes
            hasChanges = hasAnyChanges()
        }
    }
    
    private func hasAnyChanges() -> Bool {
        for (playerID, rounds) in roundScores {
            for (round, score) in rounds {
                let originalScore = originalScores[playerID]?[round] ?? 0
                if score != originalScore {
                    return true
                }
            }
        }
        return false
    }
    
    func hasChangesForPlayer(_ playerID: String) -> Bool {
        guard let rounds = roundScores[playerID] else { return false }
        
        for (round, score) in rounds {
            let originalScore = originalScores[playerID]?[round] ?? 0
            if score != originalScore {
                return true
            }
        }
        return false
    }
    
    func numberOfChanges() -> Int {
        var count = 0
        for (playerID, rounds) in roundScores {
            for (round, score) in rounds {
                let originalScore = originalScores[playerID]?[round] ?? 0
                if score != originalScore {
                    count += 1
                }
            }
        }
        return count
    }
    
    func resetChanges() {
        roundScores = originalScores
        hasChanges = false
    }
    
    func resetForNewGame() {
        print("🔍 DEBUG: ===== RESET FOR NEW GAME =====")
        print("🔍 DEBUG: Clearing all score data")
        scores = []
        roundScores = [:]
        originalScores = [:]
        hasChanges = false
        isSaving = false
        print("🔍 DEBUG: Reset complete - scores: \(scores.count), roundScores: \(roundScores.count), originalScores: \(originalScores.count)")
    }
    
    func saveAllScores(gameID: String, rounds: Int) {
        guard !isSaving && hasChanges else { return }
        
        isSaving = true
        
        Task {
            do {
                var updatedScores: [Score] = []
                var createdScores: [Score] = []
                
                // Prepare all changes
                for (playerID, roundDict) in roundScores {
                    for round in 1...rounds {
                        let score = roundDict[round] ?? 0
                        let originalScore = originalScores[playerID]?[round] ?? 0
                        
                        // Only save if there's an actual change
                        if score != originalScore {
                            if let existingScore = scores.first(where: { $0.gameID == gameID && $0.playerID == playerID && $0.roundNumber == round }) {
                                if score == 0 {
                                    // Delete the score if it's set to 0
                                    Task {
                                        do {
                                            let result = try await Amplify.API.mutate(request: .delete(existingScore))
                                            switch result {
                                            case .success:
                                                await MainActor.run {
                                                    self.scores.removeAll { $0.id == existingScore.id }
                                                }
                                            case .failure(let error):
                                                print("Error deleting score: \(error)")
                                            }
                                        } catch {
                                            print("Error deleting score: \(error)")
                                        }
                                    }
                                } else {
                                    // Update existing score
                                    let updatedScore = Score(
                                        id: existingScore.id,
                                        gameID: gameID,
                                        playerID: playerID,
                                        roundNumber: round,
                                        score: score,
                                        createdAt: existingScore.createdAt,
                                        updatedAt: Temporal.DateTime.now()
                                    )
                                    updatedScores.append(updatedScore)
                                }
                            } else if score > 0 {
                                // Create new score only if score > 0
                                let newScore = Score(
                                    gameID: gameID,
                                    playerID: playerID,
                                    roundNumber: round,
                                    score: score,
                                    createdAt: Temporal.DateTime.now(),
                                    updatedAt: Temporal.DateTime.now()
                                )
                                createdScores.append(newScore)
                            }
                        }
                    }
                }
                
                // Perform all updates
                for score in updatedScores {
                    let result = try await Amplify.API.mutate(request: .update(score))
                    switch result {
                    case .success(let updated):
                        await MainActor.run {
                            if let idx = self.scores.firstIndex(where: { $0.id == updated.id }) {
                                self.scores[idx] = updated
                            }
                        }
                    case .failure(let error):
                        print("Error updating score: \(error)")
                    }
                }
                
                // Perform all creates
                for score in createdScores {
                    let result = try await Amplify.API.mutate(request: .create(score))
                    switch result {
                    case .success(let createdScore):
                        await MainActor.run {
                            self.scores.append(createdScore)
                        }
                    case .failure(let error):
                        print("Error creating score: \(error)")
                    }
                }
                
                await MainActor.run {
                    // Update original scores to reflect current state
                    self.originalScores = self.roundScores
                    self.hasChanges = false
                    self.isSaving = false
                }
                
                // Update DataManager with ALL scores for this game for reactive leaderboard calculation
                // This ensures the leaderboard has complete data for the game
                let allGameScores = self.scores.filter { $0.gameID == gameID }
                await MainActor.run {
                    self.dataManager.onScoresUpdated(allGameScores)
                }
                
            } catch {
                print("Error saving scores: \(error)")
                await MainActor.run {
                    self.isSaving = false
                }
            }
        }
    }

    func totalScore(for playerID: String, currentRound: Int?) -> Int {
        if let currentRound = currentRound {
            // 1. Get all backend scores for this player, except the current round
            let backendTotal = scores.filter { $0.playerID == playerID && $0.roundNumber != currentRound }.map { $0.score }.reduce(0, +)
            // 2. Get the UI value for the current round (if any)
            let currentRoundScore = roundScores[playerID]?[currentRound] ?? scores.first(where: { $0.playerID == playerID && $0.roundNumber == currentRound })?.score ?? 0
            // 3. Return the sum
            return backendTotal + currentRoundScore
        } else {
            // Sum all rounds
            let backendTotal = scores.filter { $0.playerID == playerID }.map { $0.score }.reduce(0, +)
            let uiTotal = roundScores[playerID]?.values.reduce(0, +) ?? 0
            return max(backendTotal, uiTotal)
        }
    }
    
    func subscribeToScoreUpdates(gameID: String) {
        let subscription = Amplify.API.subscribe(request: .subscription(of: Score.self, type: .onCreate))
        Task {
            do {
                for try await subscriptionEvent in subscription {
                    switch subscriptionEvent {
                    case .connection(let state):
                        print("Connection state: \(state)")
                    case .data(let result):
                        switch result {
                        case .success(let score):
                            DispatchQueue.main.async {
                                // Only add scores for this game
                                if score.gameID == gameID {
                                    self.scores.append(score)
                                }
                            }
                        case .failure(let error):
                            print("Subscription error: \(error)")
                        }
                    }
                }
            } catch {
                print("Subscription has terminated with \(error)")
            }
        }
    }
    
    func loadScoresForGame(gameID: String) {
        print("🔍 DEBUG: ===== LOAD SCORES FOR GAME START =====")
        print("🔍 DEBUG: Loading scores for gameID: \(gameID)")
        
        Task {
            // Use DataManager to get scores efficiently
            await dataManager.loadScores()
            
            await MainActor.run {
                // Filter scores for this game using DataManager
                let gameScores = dataManager.getScoresForGame(gameID)
                print("🔍 DEBUG: Found \(gameScores.count) scores for game \(gameID)")
                
                // Print all scores for debugging
                for score in gameScores {
                    print("🔍 DEBUG: Score - PlayerID: \(score.playerID), Round: \(score.roundNumber), Value: \(score.score)")
                }
                
                self.scores = gameScores
                
                // Clear existing roundScores before populating
                self.roundScores = [:]
                
                // Populate roundScores from backend data
                for score in gameScores {
                    if roundScores[score.playerID] == nil {
                        roundScores[score.playerID] = [:]
                    }
                    roundScores[score.playerID]?[score.roundNumber] = score.score
                }
                
                // Set original scores to track changes
                self.originalScores = self.roundScores
                self.hasChanges = false
                
                // Update DataManager with all loaded scores for reactive leaderboard calculation
                self.dataManager.onScoresUpdated(gameScores)
                
                print("🔍 DEBUG: ===== LOAD SCORES FOR GAME END =====")
                print("🔍 DEBUG: Final roundScores: \(self.roundScores)")
                print("🔍 DEBUG: Passed \(gameScores.count) scores to DataManager for leaderboard calculation")
            }
        }
    }
    
    func addScore(gameID: String, playerID: String, roundNumber: Int, score: Int) {
        let newScore = Score(
            gameID: gameID,
            playerID: playerID,
            roundNumber: roundNumber,
            score: score,
            createdAt: Temporal.DateTime.now(),
            updatedAt: Temporal.DateTime.now()
        )
        
        Task {
            do {
                let result = try await Amplify.API.mutate(request: .create(newScore))
                await MainActor.run {
                    switch result {
                    case .success(let createdScore):
                        self.scores.append(createdScore)
                        // Update DataManager for reactive leaderboard calculation
                        self.dataManager.onScoresUpdated([createdScore])
                    case .failure(let error):
                        print("Error creating score: \(error)")
                    }
                }
            } catch {
                print("Error creating score: \(error)")
            }
        }
    }
    
    func saveScoresForCurrentRound(gameID: String, roundNumber: Int) {
        for (playerID, rounds) in roundScores {
            if let score = rounds[roundNumber], score > 0 {
                // Check if a score already exists for this gameID, playerID, and roundNumber
                if let existingScore = scores.first(where: { $0.gameID == gameID && $0.playerID == playerID && $0.roundNumber == roundNumber }) {
                    // Update existing score
                    let updatedScore = Score(
                        id: existingScore.id,
                        gameID: gameID,
                        playerID: playerID,
                        roundNumber: roundNumber,
                        score: score,
                        createdAt: existingScore.createdAt,
                        updatedAt: Temporal.DateTime.now()
                    )
                    Task {
                        do {
                            let result = try await Amplify.API.mutate(request: .update(updatedScore))
                            await MainActor.run {
                                switch result {
                                case .success(let updated):
                                    if let idx = self.scores.firstIndex(where: { $0.id == updated.id }) {
                                        self.scores[idx] = updated
                                    }
                                    // Update DataManager for reactive leaderboard calculation
                                    self.dataManager.onScoresUpdated([updated])
                                case .failure(let error):
                                    print("Error updating score: \(error)")
                                }
                            }
                        } catch {
                            print("Error updating score: \(error)")
                        }
                    }
                } else {
                    // Create new score
                    let newScore = Score(
                        gameID: gameID,
                        playerID: playerID,
                        roundNumber: roundNumber,
                        score: score,
                        createdAt: Temporal.DateTime.now(),
                        updatedAt: Temporal.DateTime.now()
                    )
                    Task {
                        do {
                            let result = try await Amplify.API.mutate(request: .create(newScore))
                            await MainActor.run {
                                switch result {
                                case .success(let createdScore):
                                    self.scores.append(createdScore)
                                    // Update DataManager for reactive leaderboard calculation
                                    self.dataManager.onScoresUpdated([createdScore])
                                case .failure(let error):
                                    print("Error saving score: \(error)")
                                }
                            }
                        } catch {
                            print("Error saving score: \(error)")
                        }
                    }
                }
            }
        }
    }
}

