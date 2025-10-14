//
//  PlayerHierarchyView.swift
//  ScoreBoard
//
//  Created by AI Assistant on 12/19/25.
//

import SwiftUI
import Amplify

struct PlayerHierarchyView: View {
    @Binding var parentPlayers: [String]
    @Binding var playerHierarchy: [String: [String]]
    var isEditMode: Bool = false // Whether we're editing an existing hierarchy game
    @State private var showingAddParentPlayer = false
    @State private var newParentPlayerName = ""
    @State private var selectedParentPlayer: String?
    @State private var showingSearchUsers = false
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var isSearching = false
    
    /// Extract display name from "userId:username" format, prioritizing fresh username from cache
    private func getDisplayName(for playerIdentifier: String) -> String {
        let components = playerIdentifier.components(separatedBy: ":")
        
        if components.count > 1 {
            // Has "userId:username" format
            let userId = components[0]
            let storedUsername = components[1]
            
            // Priority 1: Try to get fresh username from DataManager's in-memory cache
            if let user = DataManager.shared.getUser(userId) {
                return user.username ?? storedUsername
            }
            
            // Priority 2: Try to get from UsernameCacheService
            let cachedUsername = UsernameCacheService.shared.cachedUsernames[userId]
            if let cachedUsername = cachedUsername {
                return cachedUsername
            }
            
            // Priority 3: Use stored username as fallback
            return storedUsername
        }
        
        // Plain format - check if it's a userId that needs lookup
        if playerIdentifier.hasPrefix("guest_") || playerIdentifier.hasPrefix("user_") || 
           (playerIdentifier.count > 20 && playerIdentifier.contains("-")) {
            // Try to get username from DataManager
            if let user = DataManager.shared.getUser(playerIdentifier) {
                return user.username ?? String(playerIdentifier.prefix(8))
            }
            return String(playerIdentifier.prefix(8))
        }
        
        // Anonymous player or team name - return as-is
        return playerIdentifier
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                let totalChildPlayers = playerHierarchy.values.flatMap { $0 }.count
                Text("Players (\(totalChildPlayers))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Only show "Add Team" button if not in edit mode (parent players already exist)
                if !isEditMode {
                    Button("Add Team") {
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
                                showingSearchUsers = true
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
        .sheet(isPresented: $showingSearchUsers) {
            SearchRegisteredUsersSheet(
                searchText: $searchText,
                searchResults: $searchResults,
                isSearching: $isSearching,
                addRegisteredPlayer: { user in
                    if let selectedParent = selectedParentPlayer {
                        // Use "userId:username" format for registered users
                        let playerIdentifier = "\(user.id):\(user.username)"
                        addChildPlayer(playerIdentifier, to: selectedParent)
                        searchText = ""
                        searchResults = []
                        showingSearchUsers = false
                    }
                }
            )
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
    
    private func addChildPlayer(_ playerIdentifier: String, to parentPlayer: String) {
        let trimmedIdentifier = playerIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedIdentifier.isEmpty else { return }
        
        if playerHierarchy[parentPlayer] == nil {
            playerHierarchy[parentPlayer] = []
        }
        
        // Extract userId for comparison (handle "userId:username" format)
        let newUserId = trimmedIdentifier.components(separatedBy: ":").first ?? trimmedIdentifier
        
        // Check if this user is already a child in ANY parent team (prevent duplicate across all teams)
        let allChildPlayers = playerHierarchy.values.flatMap { $0 }
        let isDuplicate = allChildPlayers.contains { existingChild in
            let existingUserId = existingChild.components(separatedBy: ":").first ?? existingChild
            return existingUserId == newUserId
        }
        
        if !isDuplicate {
            playerHierarchy[parentPlayer]!.append(trimmedIdentifier)
            print("🔍 DEBUG: Added child player '\(trimmedIdentifier)' to '\(parentPlayer)'")
        } else {
            print("🔍 DEBUG: Player with userId '\(newUserId)' is already a child player in another team, skipping duplicate")
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
    
    /// Extract display name from "userId:username" format, prioritizing fresh username from cache
    private func getDisplayName(for playerIdentifier: String) -> String {
        let components = playerIdentifier.components(separatedBy: ":")
        
        if components.count > 1 {
            // Has "userId:username" format
            let userId = components[0]
            let storedUsername = components[1]
            
            // Priority 1: Try to get fresh username from DataManager's in-memory cache
            if let user = DataManager.shared.getUser(userId) {
                return user.username ?? storedUsername
            }
            
            // Priority 2: Try to get from UsernameCacheService
            let cachedUsername = UsernameCacheService.shared.cachedUsernames[userId]
            if let cachedUsername = cachedUsername {
                return cachedUsername
            }
            
            // Priority 3: Use stored username as fallback
            return storedUsername
        }
        
        // Plain format - check if it's a userId that needs lookup
        if playerIdentifier.hasPrefix("guest_") || playerIdentifier.hasPrefix("user_") || 
           (playerIdentifier.count > 20 && playerIdentifier.contains("-")) {
            // Try to get username from DataManager
            if let user = DataManager.shared.getUser(playerIdentifier) {
                return user.username ?? String(playerIdentifier.prefix(8))
            }
            return String(playerIdentifier.prefix(8))
        }
        
        // Anonymous player or team name - return as-is
        return playerIdentifier
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Parent player header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(parentPlayer)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(childPlayers.count) players")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Search Registered users") {
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
                            Text("• \(getDisplayName(for: childPlayer))")
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
                Text("Add Team")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                TextField("Team name (e.g., Team 1)", text: $parentPlayerName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                
                Text("Teams are the main players in the game. Players will be added to them later.")
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
