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
    
    /// Sign in as a guest user
    static func signInAsGuest() async -> AuthUser? {
        do {
            print("🔍 DEBUG: Starting guest sign-in...")
            
            // For guest access, we'll use a simple approach with a temporary user
            // In a production app, you'd want to use Cognito Identity Pool with unauthenticated identities
            let guestUserId = "guest_\(UUID().uuidString)"
            
            // Create a temporary guest user
            let guestUser = GuestUser(
                userId: guestUserId,
                username: "Guest_\(String(guestUserId.prefix(8)))",
                email: "guest@temp.com"
            )
            
            print("🔍 DEBUG: Created guest user with ID: \(guestUserId)")
            return guestUser
            
        } catch {
            print("🔍 DEBUG: Error signing in as guest: \(error)")
            return nil
        }
    }
    
    /// Check if current user is a guest
    static func isGuestUser(_ user: AuthUser) -> Bool {
        return user.userId.hasPrefix("guest_")
    }
    
    /// Check if a User object is a guest user
    static func isGuestUser(_ user: User) -> Bool {
        return user.id.hasPrefix("guest_")
    }
    
    /// Create guest profile in database
    static func createGuestProfile(identityId: String) async -> User? {
        do {
            print("🔍 DEBUG: Creating guest profile for ID: \(identityId)")
            
            let guestUsername = "Guest_" + String(identityId.prefix(8))
            
            let guestUser = User(
                id: identityId,
                username: guestUsername,
                email: "guest@temp.com",
                createdAt: Temporal.DateTime.now(),
                updatedAt: Temporal.DateTime.now()
            )
            
            let result = try await Amplify.API.mutate(request: .create(guestUser))
            
            switch result {
            case .success(let createdUser):
                print("🔍 DEBUG: Successfully created guest profile: \(createdUser.username)")
                return createdUser
            case .failure(let error):
                print("🔍 DEBUG: Failed to create guest profile: \(error)")
                return nil
            }
        } catch {
            print("🔍 DEBUG: Error creating guest profile: \(error)")
            return nil
        }
    }
    
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

