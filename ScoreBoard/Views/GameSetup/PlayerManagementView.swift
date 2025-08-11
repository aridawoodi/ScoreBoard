//
//  PlayerManagementView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI
import Amplify

// MARK: - Player Management View
struct PlayerManagementView: View {
    @Binding var players: [Player]
    @Binding var newPlayerName: String
    @Binding var searchText: String
    @Binding var searchResults: [User]
    @Binding var isSearching: Bool
    
    let addPlayer: () -> Void
    let searchUsers: (String) -> Void
    let addRegisteredPlayer: (User) -> Void
    let removePlayer: (Player) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Players (\(players.count))").font(.headline)
            
            // Player List
            if !players.isEmpty {
                VStack(spacing: 8) {
                    ForEach(players) { player in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                HStack {
                                    if player.isRegistered {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Registered")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    } else {
                                        Image(systemName: "person.circle")
                                            .foregroundColor(.orange)
                                        Text("Anonymous")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            Spacer()
                            Button(action: { removePlayer(player) }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                }
            } else {
                Text("No players added yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            }
            
            // Add Player Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Add Players").font(.headline)
                
                // Add Anonymous Player
                HStack {
                    TextField("Enter player name", text: $newPlayerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Add") {
                        addPlayer()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                // Search Registered Users
                VStack(alignment: .leading, spacing: 8) {
                    Text("Search Registered Users")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("Search by username or email", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onChange(of: searchText) { _, newValue in
                                searchUsers(newValue)
                            }
                        
                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    
                    if !searchResults.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Search Results")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(searchResults, id: \.id) { user in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(user.username)
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Text(user.email)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button("Add") {
                                        addRegisteredPlayer(user)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemBackground))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Player Management Functions
struct PlayerManagementFunctions {
    static func addPlayer(newPlayerName: Binding<String>, players: Binding<[Player]>) {
        let trimmedName = newPlayerName.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let player = Player(name: trimmedName, isRegistered: false, userId: nil)
        players.wrappedValue.append(player)
        newPlayerName.wrappedValue = ""
    }
    
    static func searchUsers(query: String, searchResults: Binding<[User]>, isSearching: Binding<Bool>) {
        guard !query.isEmpty else {
            searchResults.wrappedValue = []
            return
        }
        
        isSearching.wrappedValue = true
        Task {
            do {
                let result = try await Amplify.API.query(request: .list(User.self))
                await MainActor.run {
                    switch result {
                    case .success(let users):
                        searchResults.wrappedValue = users.filter { 
                            $0.username.lowercased().contains(query.lowercased()) || 
                            $0.email.lowercased().contains(query.lowercased())
                        }
                    case .failure(let error):
                        print("Search error: \(error)")
                        searchResults.wrappedValue = []
                    }
                    isSearching.wrappedValue = false
                }
            } catch {
                await MainActor.run {
                    print("Search error: \(error)")
                    searchResults.wrappedValue = []
                    isSearching.wrappedValue = false
                }
            }
        }
    }
    
    static func addRegisteredPlayer(_ user: User, players: Binding<[Player]>, searchText: Binding<String>, searchResults: Binding<[User]>) {
        let player = Player(name: user.username, isRegistered: true, userId: user.id)
        players.wrappedValue.append(player)
        searchText.wrappedValue = ""
        searchResults.wrappedValue = []
    }
    
    static func removePlayer(_ player: Player, players: Binding<[Player]>) {
        players.wrappedValue.removeAll { $0.id == player.id }
    }
}
