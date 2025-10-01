//
//  PlayerHierarchyView.swift
//  ScoreBoard
//
//  Created by AI Assistant on 12/19/25.
//

import SwiftUI

struct PlayerHierarchyView: View {
    @Binding var parentPlayers: [String]
    @Binding var playerHierarchy: [String: [String]]
    var isEditMode: Bool = false // Whether we're editing an existing hierarchy game
    @State private var showingAddParentPlayer = false
    @State private var newParentPlayerName = ""
    @State private var selectedParentPlayer: String?
    @State private var showingAddChildPlayer = false
    @State private var newChildPlayerName = ""
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Player Hierarchy")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Only show "Add Parent Player" button if not in edit mode (parent players already exist)
                if !isEditMode {
                    Button("Add Parent Player") {
                        showingAddParentPlayer = true
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            
            // Parent players list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(parentPlayers, id: \.self) { parentPlayer in
                        ParentPlayerRow(
                            parentPlayer: parentPlayer,
                            childPlayers: playerHierarchy[parentPlayer] ?? [],
                            onAddChild: {
                                selectedParentPlayer = parentPlayer
                                showingAddChildPlayer = true
                            },
                            onRemoveChild: { childPlayer in
                                removeChildPlayer(childPlayer, from: parentPlayer)
                            },
                            onRemoveParent: {
                                removeParentPlayer(parentPlayer)
                            },
                            canRemoveParent: !isEditMode // Don't allow removing parent players in edit mode
                        )
                    }
                }
            }
            
            // Instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("How it works:")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("• Create parent players (e.g., 'Team 1', 'Team 2')")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("• Add child players to each parent")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                
                Text("• Child players inherit parent's scores")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(10)
        }
        .padding()
        .gradientBackground()
        .sheet(isPresented: $showingAddParentPlayer) {
            AddParentPlayerSheet(
                parentPlayerName: $newParentPlayerName,
                onSave: {
                    addParentPlayer(newParentPlayerName)
                    newParentPlayerName = ""
                    showingAddParentPlayer = false
                },
                onCancel: {
                    newParentPlayerName = ""
                    showingAddParentPlayer = false
                }
            )
        }
        .sheet(isPresented: $showingAddChildPlayer) {
            if let selectedParent = selectedParentPlayer {
                AddChildPlayerSheet(
                    parentPlayer: selectedParent,
                    childPlayerName: $newChildPlayerName,
                    onSave: {
                        addChildPlayer(newChildPlayerName, to: selectedParent)
                        newChildPlayerName = ""
                        showingAddChildPlayer = false
                    },
                    onCancel: {
                        newChildPlayerName = ""
                        showingAddChildPlayer = false
                    }
                )
            }
        }
    }
    
    private func addParentPlayer(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty && !parentPlayers.contains(trimmedName) {
            parentPlayers.append(trimmedName)
            playerHierarchy[trimmedName] = []
        }
    }
    
    private func removeParentPlayer(_ parentPlayer: String) {
        parentPlayers.removeAll { $0 == parentPlayer }
        playerHierarchy.removeValue(forKey: parentPlayer)
    }
    
    private func addChildPlayer(_ name: String, to parentPlayer: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            if playerHierarchy[parentPlayer] == nil {
                playerHierarchy[parentPlayer] = []
            }
            if !playerHierarchy[parentPlayer]!.contains(trimmedName) {
                playerHierarchy[parentPlayer]!.append(trimmedName)
            }
        }
    }
    
    private func removeChildPlayer(_ childPlayer: String, from parentPlayer: String) {
        playerHierarchy[parentPlayer]?.removeAll { $0 == childPlayer }
    }
}

struct ParentPlayerRow: View {
    let parentPlayer: String
    let childPlayers: [String]
    let onAddChild: () -> Void
    let onRemoveChild: (String) -> Void
    let onRemoveParent: () -> Void
    var canRemoveParent: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Parent player header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(parentPlayer)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(childPlayers.count) child players")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Add Child") {
                        onAddChild()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    // Only show remove parent button if allowed (not in edit mode for hierarchy games)
                    if canRemoveParent {
                        Button("Remove") {
                            onRemoveParent()
                        }
                        .buttonStyle(DestructiveButtonStyle())
                    }
                }
            }
            
            // Child players list
            if !childPlayers.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(childPlayers, id: \.self) { childPlayer in
                        HStack {
                            Text("• \(childPlayer)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            Button("Remove") {
                                onRemoveChild(childPlayer)
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                    }
                }
                .padding(.leading, 16)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
    }
}

struct AddParentPlayerSheet: View {
    @Binding var parentPlayerName: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Parent Player")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                TextField("Parent player name (e.g., Team 1)", text: $parentPlayerName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                
                Text("Parent players are the main players in the game. Child players will be added to them later.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .gradientBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .foregroundColor(.white)
                    .disabled(parentPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct AddChildPlayerSheet: View {
    let parentPlayer: String
    @Binding var childPlayerName: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Child Player")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Adding to: \(parentPlayer)")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                
                TextField("Child player name or ID", text: $childPlayerName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                
                Text("Child players will inherit \(parentPlayer)'s scores and can edit them.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .gradientBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .foregroundColor(.white)
                    .disabled(childPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color("LightGreen"))
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(6)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

#Preview {
    PlayerHierarchyView(
        parentPlayers: .constant(["Team 1", "Team 2"]),
        playerHierarchy: .constant([
            "Team 1": ["Player A", "Player B"],
            "Team 2": ["Player C"]
        ])
    )
}
