//
//  AmplifyService.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation
import Amplify
import AWSCognitoAuthPlugin

class AmplifyService {
    static func configure() {
        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.configure()
            print("Amplify configured successfully")
        } catch {
            print("Failed to configure Amplify: \(error)")
        }
    }
}

extension AmplifyService {
    // MARK: - Guest Authentication
    
    // Guest sign-in is now handled in ContentView
    // This method is no longer needed
    
    // Guest user detection is now done directly with id.hasPrefix("guest_")
    // These methods are no longer needed
    
    // Guest profile creation is now handled in UserService.ensureUserProfile()
    // This method is no longer needed since guest users work with local profiles only
    
    // MARK: - Existing Methods
    
    static func searchUsers(query: String) async -> [User] {
        // For now, return empty array since User model isn't working
        // We'll implement this differently
        print("🔍 DEBUG: User search is temporarily disabled - User model needs to be fixed")
        return []
    }

    static func fetchAllUsers() async -> [User] {
        do {
            let result = try await Amplify.API.query(request: .list(User.self))
            
            switch result {
            case .success(let allUsers):
                print("🔍 DEBUG: Successfully fetched \(allUsers.count) total users from database")
                return Array(allUsers)
            case .failure(let error):
                print("🔍 DEBUG: Error fetching all users: \(error)")
                return []
            }
        } catch {
            print("🔍 DEBUG: Exception fetching all users: \(error)")
            return []
        }
    }
    
    static func fetchUsers(for userIDs: [String]) async -> [User] {
        do {
            print("🔍 DEBUG: fetchUsers called with userIDs: \(userIDs)")
            let result = try await Amplify.API.query(request: .list(User.self))
            
            switch result {
            case .success(let allUsers):
                print("🔍 DEBUG: Successfully fetched \(allUsers.count) total users from database")
                
                // Print all users for debugging
                for (index, user) in allUsers.enumerated() {
                    print("🔍 DEBUG: User \(index): ID=\(user.id), Username=\(user.username)")
                }
                
                // Filter users to only include those with matching IDs
                let filteredUsers = allUsers.filter { user in
                    userIDs.contains(user.id)
                }
                
                print("🔍 DEBUG: Found \(filteredUsers.count) matching users out of \(allUsers.count) total users")
                print("🔍 DEBUG: Looking for user IDs: \(userIDs)")
                print("🔍 DEBUG: Found users: \(filteredUsers.map { "\($0.username) (ID: \($0.id))" })")
                
                return filteredUsers
            case .failure(let error):
                print("🔍 DEBUG: Error fetching users: \(error)")
                return []
            }
        } catch {
            print("🔍 DEBUG: Exception fetching users: \(error)")
            return []
        }
    }
    
    // Check if current user has a profile
    static func checkUserProfile() async -> User? {
        do {
            // Get current user info using helper function that works for both guest and authenticated users
            guard let currentUserInfo = await getCurrentUser() else {
                print("🔍 DEBUG: Unable to get current user information")
                return nil
            }
            
            let userId = currentUserInfo.userId
            let isGuest = currentUserInfo.isGuest
            
            print("🔍 DEBUG: Checking user profile for user: \(userId), isGuest: \(isGuest)")
            
            let result = try await Amplify.API.query(request: .get(User.self, byId: userId))
            
            switch result {
            case .success(let user):
                return user
            case .failure:
                return nil
            }
        } catch {
            print("Error checking user profile: \(error)")
            return nil
        }
    }
    
    // Get user profile by ID
    static func getUserProfile(userId: String) async -> User? {
        do {
            let result = try await Amplify.API.query(request: .get(User.self, byId: userId))
            
            switch result {
            case .success(let user):
                return user
            case .failure:
                return nil
            }
        } catch {
            print("Error getting user profile: \(error)")
            return nil
        }
    }
    
    // Search users by username or email
    static func searchUsersByName(query: String) async -> [User] {
        do {
            // Use server-side filtering with GraphQL query
            // Note: This is a placeholder for when GraphQL search is implemented
            // For now, we'll use client-side filtering but with better logging
            print("🔍 DEBUG: Searching users for query: '\(query)'")
            let result = try await Amplify.API.query(request: .list(User.self))
            
            switch result {
            case .success(let users):
                let filteredUsers = users.filter { user in
                    user.username.lowercased().contains(query.lowercased()) ||
                    user.email.lowercased().contains(query.lowercased())
                }
                print("🔍 DEBUG: Found \(filteredUsers.count) matching users out of \(users.count) total users")
                return filteredUsers
            case .failure(let error):
                print("🔍 DEBUG: Error searching users: \(error)")
                return []
            }
        } catch {
            print("🔍 DEBUG: Exception searching users: \(error)")
            return []
        }
    }
}

// MARK: - Guest User Implementation
struct GuestUser: AuthUser {
    let userId: String
    let username: String
    let email: String
}

