//
//  PlayerManagementView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI
import Amplify

// MARK: - Search Registered Users Sheet
struct SearchRegisteredUsersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var searchText: String
    @Binding var searchResults: [User]
    @Binding var isSearching: Bool
    let addRegisteredPlayer: (User) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Search Registered Users")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Find and add registered users to your game")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Search Field
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        ZStack(alignment: .leading) {
                            if searchText.isEmpty {
                                Text("Search by username or email")
                                    .foregroundColor(.white.opacity(0.5))
                                    .padding(.leading, 16)
                            }
                            TextField("", text: $searchText)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                .onChange(of: searchText) { _, newValue in
                                    // Trigger search when text changes
                                    if !newValue.isEmpty {
                                        searchUsers(newValue)
                                    } else {
                                        searchResults = []
                                    }
                                }
                        }
                        
                        if isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding(.leading, 8)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Search Results
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if !searchResults.isEmpty {
                            ForEach(searchResults, id: \.id) { user in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(user.username)
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.white)
                                        Text(user.email)
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    Spacer()
                                    Button("Add") {
                                        addRegisteredPlayer(user)
                                        dismiss()
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.green)
                                    .cornerRadius(8)
                                }
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            }
                        } else if !searchText.isEmpty && !isSearching {
                            VStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("No users found")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("Try searching with a different username or email")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 40)
                        } else if searchText.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "person.2")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.5))
                                Text("Search for registered users")
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("Enter a username or email to find users")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.5))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 40)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Search Users")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white)
            )
            .gradientBackground()
        }
    }
    
    private func searchUsers(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        Task {
            do {
                let result = try await Amplify.API.query(request: .list(User.self))
                await MainActor.run {
                    switch result {
                    case .success(let users):
                        searchResults = users.filter { 
                            $0.username.lowercased().contains(query.lowercased()) || 
                            $0.email.lowercased().contains(query.lowercased())
                        }
                    case .failure(let error):
                        print("Search error: \(error)")
                        searchResults = []
                    }
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    print("Search error: \(error)")
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }
}

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
    
    @State private var showSearchSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Player List
            if !players.isEmpty {
                VStack(spacing: 8) {
                    ForEach(players) { player in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
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
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
            }
            
            // Add Player Section
            VStack(alignment: .leading, spacing: 12) {
                Text("Add Players").font(.headline)
                    .foregroundColor(.white)
                
                // Add Anonymous Player
                HStack {
                    ZStack(alignment: .leading) {
                        if newPlayerName.isEmpty {
                            Text("Enter player name")
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.leading, 16)
                        }
                        TextField("", text: $newPlayerName)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    Button("Add") {
                        addPlayer()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(8)
                    .disabled(newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                // Search Registered Users Button
                Button(action: {
                    showSearchSheet = true
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                        Text("Search Registered Users")
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding()
                    .background(Color("LightGreen"))
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
        .sheet(isPresented: $showSearchSheet) {
            SearchRegisteredUsersSheet(
                searchText: $searchText,
                searchResults: $searchResults,
                isSearching: $isSearching,
                addRegisteredPlayer: addRegisteredPlayer
            )
        }
    }
}

// MARK: - Player Management Functions
struct PlayerManagementFunctions {
    static func addPlayer(newPlayerName: Binding<String>, players: Binding<[Player]>) {
        let trimmedName = newPlayerName.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // Check if player with this name already exists
        let playerExists = players.wrappedValue.contains { player in
            player.name.lowercased() == trimmedName.lowercased()
        }
        
        guard !playerExists else {
            print("🔍 DEBUG: Player '\(trimmedName)' already exists, skipping addition")
            newPlayerName.wrappedValue = ""
            return
        }
        
        let player = Player(name: trimmedName, isRegistered: false, userId: nil)
        players.wrappedValue.append(player)
        newPlayerName.wrappedValue = ""
        print("🔍 DEBUG: Added anonymous player: \(trimmedName)")
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
        // Check if player with this user ID already exists
        let playerExists = players.wrappedValue.contains { player in
            if let playerUserId = player.userId {
                return playerUserId == user.id
            }
            return false
        }
        
        guard !playerExists else {
            print("🔍 DEBUG: Registered player '\(user.username)' (ID: \(user.id)) already exists, skipping addition")
            searchText.wrappedValue = ""
            searchResults.wrappedValue = []
            return
        }
        
        let player = Player(name: user.username, isRegistered: true, userId: user.id)
        players.wrappedValue.append(player)
        searchText.wrappedValue = ""
        searchResults.wrappedValue = []
        print("🔍 DEBUG: Added registered player: \(user.username) (ID: \(user.id))")
    }
    
    static func removePlayer(_ player: Player, players: Binding<[Player]>) {
        players.wrappedValue.removeAll { $0.id == player.id }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        // Background gradient
        GradientBackgroundView()
        
        ScrollView {
            PlayerManagementView(
                players: .constant([
                    Player(name: "John Doe", isRegistered: true, userId: "user1"),
                    Player(name: "Jane Smith", isRegistered: false, userId: nil),
                    Player(name: "Bob Johnson", isRegistered: true, userId: "user3")
                ]),
                newPlayerName: .constant(""),
                searchText: .constant(""),
                searchResults: .constant([
                    User(id: "user4", username: "alice", email: "alice@example.com", createdAt: Temporal.DateTime.now(), updatedAt: Temporal.DateTime.now()),
                    User(id: "user5", username: "charlie", email: "charlie@example.com", createdAt: Temporal.DateTime.now(), updatedAt: Temporal.DateTime.now())
                ]),
                isSearching: .constant(false),
                addPlayer: {
                    print("Add player tapped")
                },
                searchUsers: { query in
                    print("Searching for: \(query)")
                },
                addRegisteredPlayer: { user in
                    print("Adding registered player: \(user.username)")
                },
                removePlayer: { player in
                    print("Removing player: \(player.name)")
                }
            )
            .padding()
        }
    }
}
