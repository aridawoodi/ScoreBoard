//
//  QuickHierarchyGameCard.swift
//  ScoreBoard
//
//  Created by AI Assistant on 12/30/25.
//

import SwiftUI
import Amplify

struct QuickHierarchyGameCard: View {
    let onQuickGameCreated: (Game) -> Void
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Card Header
            HStack {
                Image(systemName: "person.3.sequence.fill")
                    .font(.title2)
                    .foregroundColor(Color("LightBlue"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Team Hierarchy")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("2 Parent Teams • Add Players Later")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Create Button
                Button(action: createQuickHierarchyGame) {
                    HStack(spacing: 6) {
                        if isCreating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color("LightBlue"))
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
                            .fill(isCreating ? Color.gray : Color.black.opacity(0.3))
                    )
                }
                .disabled(isCreating)
            }
            
            // Card Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.2.badge.gearshape.fill")
                        .foregroundColor(Color("LightBlue"))
                        .font(.caption)
                    Text("Team 1 & Team 2 with hierarchy")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                HStack {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Players can join teams after creation")
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
                .stroke(Color("LightBlue").opacity(0.5), lineWidth: 1)
        )
        .alert("Quick Game Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func createQuickHierarchyGame() {
        guard !isCreating else { return }
        
        isCreating = true
        
        Task {
            do {
                print("🔍 DEBUG: Starting quick hierarchy game creation...")
                
                // Use shared user ID handling
                let currentUserId = try await GameCreationUtils.getCurrentUserId()
                
                // Create parent player IDs
                let playerIDs = ["Team 1", "Team 2"]
                
                // Create player hierarchy with empty child arrays
                let playerHierarchy: [String: [String]] = [
                    "Team 1": [],
                    "Team 2": []
                ]
                
                print("🔍 DEBUG: Parent player IDs: \(playerIDs)")
                print("🔍 DEBUG: Player hierarchy: \(playerHierarchy)")
                
                // Load default settings for quick games
                let defaultSettings = DefaultGameSettingsStorage.shared.loadDefaultGameSettings()
                
                // Use shared game object creation with hierarchy
                let game = GameCreationUtils.createGameObject(
                    gameName: nil, // No custom name for quick games
                    hostUserID: currentUserId,
                    playerIDs: playerIDs,
                    customRules: defaultSettings?.useAsDefault == true ? defaultSettings?.customRules : nil,
                    winCondition: defaultSettings?.useAsDefault == true ? defaultSettings?.winCondition : nil,
                    maxScore: defaultSettings?.useAsDefault == true ? defaultSettings?.maxScore : nil,
                    maxRounds: defaultSettings?.useAsDefault == true ? defaultSettings?.maxRounds : nil,
                    playerHierarchy: playerHierarchy
                )
                
                // Use shared database creation
                let createdGame = try await GameCreationUtils.saveGameToDatabase(game)
                
                print("🔍 DEBUG: Quick hierarchy game created successfully with ID: \(createdGame.id)")
                print("🔍 DEBUG: Game has hierarchy: \(createdGame.hasPlayerHierarchy)")
                
                await MainActor.run {
                    isCreating = false
                    onQuickGameCreated(createdGame)
                }
                
            } catch {
                print("🔍 DEBUG: Error creating quick hierarchy game: \(error)")
                await MainActor.run {
                    isCreating = false
                    errorMessage = "Error creating game: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

// MARK: - Preview
struct QuickHierarchyGameCard_Previews: PreviewProvider {
    static var previews: some View {
        QuickHierarchyGameCard { game in
            print("Preview: Quick hierarchy game created with ID: \(game.id)")
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .previewDisplayName("Quick Hierarchy Game Card")
    }
}
