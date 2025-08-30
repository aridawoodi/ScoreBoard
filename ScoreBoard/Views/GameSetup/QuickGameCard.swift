//
//  QuickGameCard.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 12/19/25.
//

import SwiftUI
import Amplify

struct QuickGameCard: View {
    let playerCount: Int
    let onQuickGameCreated: (Game) -> Void
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Card Header
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Board")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(playerCount) Players • Instant Setup")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Create Button
                Button(action: createQuickGame) {
                    HStack(spacing: 6) {
                        if isCreating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        Text(isCreating ? "Creating..." : "Create")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isCreating ? Color.gray : Color("LightGreen"))
                    )
                }
                .disabled(isCreating)
            }
            
            // Card Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: playerCount == 2 ? "person.2.fill" : "person.3.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("\(playerCount) Anonymous Players")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .alert("Quick Game Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func createQuickGame() {
        guard !isCreating else { return }
        
        isCreating = true
        
        Task {
            do {
                print("🔍 DEBUG: Starting quick game creation...")
                
                // Use shared user ID handling
                let currentUserId = try await GameCreationUtils.getCurrentUserId()
                
                // Create anonymous player IDs (using names instead of IDs for anonymous players)
                var playerIDs: [String] = []
                for i in 1...playerCount {
                    playerIDs.append("Player \(i)")
                }
                
                print("🔍 DEBUG: Player IDs: \(playerIDs)")
                
                // Use shared game object creation
                let game = GameCreationUtils.createGameObject(
                    gameName: nil, // No custom name for quick games
                    hostUserID: currentUserId,
                    playerIDs: playerIDs,
                    customRules: nil // No custom rules for quick games
                )
                
                // Use shared database creation
                let createdGame = try await GameCreationUtils.saveGameToDatabase(game)
                
                print("🔍 DEBUG: Quick game created successfully with ID: \(createdGame.id)")
                
                // Don't create initial scores - let users enter them as needed
                // await createInitialScores(for: createdGame, playerNames: playerIDs)
                
                await MainActor.run {
                    isCreating = false
                    onQuickGameCreated(createdGame)
                }
                
            } catch {
                print("🔍 DEBUG: Error creating quick game: \(error)")
                await MainActor.run {
                    isCreating = false
                    errorMessage = "Error creating game: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func createInitialScores(for game: Game, playerNames: [String]) async {
        do {
            // Create initial score entries for all players (all zeros)
            for playerName in playerNames {
                let score = Score(
                    id: "\(game.id)-\(playerName)-1",
                    gameID: game.id,
                    playerID: playerName,
                    roundNumber: 1,
                    score: 0,
                    createdAt: Temporal.DateTime.now(),
                    updatedAt: Temporal.DateTime.now()
                )
                
                // Save score to backend
                let _ = try await Amplify.API.mutate(request: .create(score))
            }
            
            print("🔍 DEBUG: Initial scores created for \(playerNames.count) players in quick game")
            
        } catch {
            print("🔍 DEBUG: Error creating initial scores: \(error)")
            // Don't throw here as the game was created successfully
        }
    }
}

// MARK: - Quick Game Errors
enum QuickGameError: Error, LocalizedError {
    case noCurrentUser
    
    var errorDescription: String? {
        switch self {
        case .noCurrentUser:
            return "Unable to get current user information"
        }
    }
}

// MARK: - Preview
struct QuickGameCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            QuickGameCard(playerCount: 2) { game in
                print("Preview: 2-player quick game created with ID: \(game.id)")
            }
            
            QuickGameCard(playerCount: 4) { game in
                print("Preview: 4-player quick game created with ID: \(game.id)")
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Quick Game Cards")
    }
}
