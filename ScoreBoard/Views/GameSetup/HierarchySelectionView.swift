//
//  HierarchySelectionView.swift
//  ScoreBoard
//
//  Created by AI Assistant on 12/19/25.
//

import SwiftUI
import Amplify

struct HierarchySelectionView: View {
    let game: Game
    let userId: String
    let playerName: String
    let onParentSelected: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedParentPlayer: String?
    @State private var parentPlayers: [ParentPlayerInfo] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color("LightGreen"))
                    
                    Text("Select Parent Player")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Choose which parent player you want to join as a child")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Parent players list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(parentPlayers, id: \.id) { parentPlayer in
                            ParentPlayerCard(
                                parentPlayer: parentPlayer,
                                isSelected: selectedParentPlayer == parentPlayer.id,
                                onTap: {
                                    selectedParentPlayer = parentPlayer.id
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Join button
                Button(action: {
                    if let selectedParent = selectedParentPlayer {
                        onParentSelected(selectedParent)
                    }
                }) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                        Text("Join as Child Player")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedParentPlayer != nil ? Color("LightGreen") : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(selectedParentPlayer == nil)
                .padding(.horizontal)
                
                Spacer()
            }
            .gradientBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            loadParentPlayers()
        }
    }
    
    private func loadParentPlayers() {
        let hierarchy = game.getPlayerHierarchy()
        
        parentPlayers = game.playerIDs.map { playerId in
            let childPlayers = hierarchy[playerId] ?? []
            return ParentPlayerInfo(
                id: playerId,
                name: playerId,
                childCount: childPlayers.count,
                childPlayers: childPlayers
            )
        }.sorted { $0.name < $1.name }
    }
}

struct ParentPlayerInfo {
    let id: String
    let name: String
    let childCount: Int
    let childPlayers: [String]
}

struct ParentPlayerCard: View {
    let parentPlayer: ParentPlayerInfo
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(parentPlayer.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(parentPlayer.childCount) child players")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    if !parentPlayer.childPlayers.isEmpty {
                        Text("Children: \(parentPlayer.childPlayers.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color("LightGreen"))
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color("LightGreen").opacity(0.3) : Color.black.opacity(0.3))
                    .stroke(isSelected ? Color("LightGreen") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    HierarchySelectionView(
        game: Game(
            hostUserID: "host123",
            playerIDs: ["Team 1", "Team 2"],
            rounds: 1,
            finalScores: [],
            gameStatus: .active,
            playerHierarchy: "{\"Team 1\": [\"user1\", \"user2\"], \"Team 2\": [\"user3\"]}",
            createdAt: Temporal.DateTime.now(),
            updatedAt: Temporal.DateTime.now()
        ),
        userId: "newuser123",
        playerName: "New Player",
        onParentSelected: { parentId in
            print("Selected parent: \(parentId)")
        }
    )
}
