//
//  UserService.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation
import Amplify

class UserService: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var error: String?
    
    static let shared = UserService()
    
    private init() {}
    
    // MARK: - User Management
    
    /// Automatically creates or retrieves a user profile for the authenticated user
    func ensureUserProfile() async -> User? {
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        do {
            print("🔍 DEBUG: Starting ensureUserProfile...")
            
            // Check if we're in guest mode
            let isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
            
            if isGuestUser {
                // Handle guest user - create profile in database with guest authentication
                let guestUserId = UserDefaults.standard.string(forKey: "current_guest_user_id") ?? ""
                print("🔍 DEBUG: Guest user with ID: \(guestUserId)")
                
                // First, try to find existing guest user profile
                print("🔍 DEBUG: Attempting to query users for guest user...")
                let listResult = try await Amplify.API.query(request: .list(User.self))
                switch listResult {
                case .success(let allUsers):
                    if let existingUser = allUsers.first(where: { $0.id == guestUserId }) {
                        print("🔍 DEBUG: Existing guest user profile found: \(existingUser.username)")
                        await MainActor.run {
                            self.currentUser = existingUser
                            self.isLoading = false
                            NotificationCenter.default.post(name: NSNotification.Name("UserProfileLoaded"), object: existingUser)
                        }
                        return existingUser
                    }
                case .failure(let error):
                    print("🔍 DEBUG: Error fetching users for guest: \(error)")
                    print("🔍 DEBUG: Query error localized description: \(error.localizedDescription)")
                    print("🔍 DEBUG: Query error error description: \(error.errorDescription)")
                    
                    // Check if this is an authentication error
                    if error.localizedDescription.contains("401") || error.localizedDescription.contains("Unauthorized") {
                        print("🔍 DEBUG: Query failed due to authentication error - API key may have expired")
                    }
                }
                
                // Create new guest user profile in database
                let idPrefix = String(guestUserId.dropFirst(6).prefix(3)) // Take first 3 characters after "guest_"
                let guestUsername = "Yourself\(idPrefix)"
                let guestEmail = "guest@scoreboard.app"
                
                print("🔍 DEBUG: Creating guest user profile in database")
                print("🔍 DEBUG: Guest username: \(guestUsername)")
                print("🔍 DEBUG: Guest email: \(guestEmail)")
                
                let newUser = User(
                    id: guestUserId,
                    username: guestUsername,
                    email: guestEmail,
                    createdAt: Temporal.DateTime.now(),
                    updatedAt: Temporal.DateTime.now()
                )
                
                let createResult = try await Amplify.API.mutate(request: .create(newUser))
                switch createResult {
                case .success(let savedUser):
                    print("🔍 DEBUG: Created new guest user profile: \(savedUser.username)")
                    await MainActor.run {
                        self.currentUser = savedUser
                        self.isLoading = false
                        NotificationCenter.default.post(name: NSNotification.Name("UserProfileCreated"), object: savedUser)
                    }
                    return savedUser
                case .failure(let error):
                    print("🔍 DEBUG: Failed to create guest user profile: \(error)")
                    print("🔍 DEBUG: Error localized description: \(error.localizedDescription)")
                    print("🔍 DEBUG: Error error description: \(error.errorDescription)")
                    print("🔍 DEBUG: Error recovery suggestion: \(error.recoverySuggestion)")
                    
                    // Check if this is a conditional check failure (profile already exists)
                    if error.localizedDescription.contains("conditional request failed") || 
                       error.localizedDescription.contains("ConditionalCheckFailedException") {
                        print("🔍 DEBUG: Profile already exists, trying to fetch it...")
                        
                        // Try to fetch the existing profile
                        do {
                            let listResult = try await Amplify.API.query(request: .list(User.self))
                            switch listResult {
                            case .success(let allUsers):
                                if let existingUser = allUsers.first(where: { $0.id == guestUserId }) {
                                    print("🔍 DEBUG: Found existing guest user profile after creation failure: \(existingUser.username)")
                                    await MainActor.run {
                                        self.currentUser = existingUser
                                        self.isLoading = false
                                        NotificationCenter.default.post(name: NSNotification.Name("UserProfileLoaded"), object: existingUser)
                                    }
                                    return existingUser
                                }
                            case .failure(let fetchError):
                                print("🔍 DEBUG: Failed to fetch existing profile: \(fetchError)")
                            }
                        } catch {
                            print("🔍 DEBUG: Exception while fetching existing profile: \(error)")
                        }
                    }
                    
                    // Check if this is an authentication error
                    if error.localizedDescription.contains("401") || error.localizedDescription.contains("Unauthorized") {
                        print("🔍 DEBUG: This appears to be an authentication error - API key may have expired")
                        print("🔍 DEBUG: Need to regenerate API key in Amplify backend")
                    }
                    
                    // Create local fallback if database creation fails
                    let localUser = User(
                        id: guestUserId,
                        username: guestUsername, // Use the same username with ID suffix
                        email: guestEmail,
                        createdAt: Temporal.DateTime.now(),
                        updatedAt: Temporal.DateTime.now()
                    )
                    
                    print("🔍 DEBUG: Created local guest user profile as fallback")
                    await MainActor.run {
                        self.currentUser = localUser
                        self.isLoading = false
                        self.error = "Failed to create guest profile in database, but using local profile: \(error.localizedDescription)"
                        NotificationCenter.default.post(name: NSNotification.Name("UserProfileCreated"), object: localUser)
                    }
                    return localUser
                }
            } else {
                // Handle regular authenticated user
                let authUser = try await Amplify.Auth.getCurrentUser()
                print("🔍 DEBUG: Got auth user with ID: \(authUser.userId)")
                
                // Get user attributes to extract email (only for non-guest users)
                let attributes = try await Amplify.Auth.fetchUserAttributes()
                let email = attributes.first(where: { $0.key.rawValue == "email" })?.value ?? ""
            
            // First, try to find existing user by AuthUser.userId (preferred method)
            let listResult = try await Amplify.API.query(request: .list(User.self))
            switch listResult {
            case .success(let allUsers):
                // First, try to find user with matching AuthUser.userId
                if let existingUser = allUsers.first(where: { $0.id == authUser.userId }) {
                    print("🔍 DEBUG: Found existing user profile by AuthUser.userId: \(existingUser.username)")
                    await MainActor.run {
                        self.currentUser = existingUser
                        self.isLoading = false
                        // Notify other parts of the app that user profile was loaded
                        NotificationCenter.default.post(name: NSNotification.Name("UserProfileLoaded"), object: existingUser)
                    }
                    return existingUser
                }
                
                // Fallback: Look for user with matching email
                if let existingUser = allUsers.first(where: { $0.email == email && !email.isEmpty }) {
                    print("🔍 DEBUG: Found existing user profile by email: \(existingUser.username)")
                    await MainActor.run {
                        self.currentUser = existingUser
                        self.isLoading = false
                    }
                    return existingUser
                }
                
                // If no user found by email, check if there are any duplicate users for this email
                let duplicateUsers = allUsers.filter { $0.email == email && !email.isEmpty }
                if duplicateUsers.count > 1 {
                    print("🔍 DEBUG: Found \(duplicateUsers.count) duplicate users for email: \(email)")
                    // Keep the first one (oldest), delete the rest
                    let usersToDelete = Array(duplicateUsers.dropFirst())
                    for userToDelete in usersToDelete {
                        do {
                            let deleteResult = try await Amplify.API.mutate(request: .delete(userToDelete))
                            switch deleteResult {
                            case .success(let deletedUser):
                                print("🔍 DEBUG: Deleted duplicate user: \(deletedUser.username)")
                            case .failure(let error):
                                print("🔍 DEBUG: Failed to delete duplicate user: \(error)")
                            }
                        } catch {
                            print("🔍 DEBUG: Error deleting duplicate user: \(error)")
                        }
                    }
                    
                    // Return the first (oldest) user
                    let oldestUser = duplicateUsers.first!
                    await MainActor.run {
                        self.currentUser = oldestUser
                        self.isLoading = false
                    }
                    return oldestUser
                }
            case .failure(let error):
                print("🔍 DEBUG: Error fetching users: \(error)")
            }
            
            // If not found by AuthUser.userId, try to automatically migrate existing user
            await autoMigrateUserIfNeeded(authUser: authUser, email: email)
            
            // Try to find user again after migration
            let listResult2 = try await Amplify.API.query(request: .list(User.self))
            switch listResult2 {
            case .success(let allUsers2):
                if let existingUser = allUsers2.first(where: { $0.id == authUser.userId }) {
                    print("🔍 DEBUG: Found existing user profile after migration: \(existingUser.username)")
                    await MainActor.run {
                        self.currentUser = existingUser
                        self.isLoading = false
                    }
                    return existingUser
                }
            case .failure(let error):
                print("🔍 DEBUG: Error fetching users after migration: \(error)")
            }
            
            // If still not found, create new profile
            let newUser = await createDefaultUserProfile(authUser: authUser, email: email)
            await MainActor.run {
                self.isLoading = false
            }
            return newUser
            }
        } catch {
            print("🔍 DEBUG: Error in ensureUserProfile: \(error)")
            await MainActor.run {
                self.error = "Error ensuring user profile: \(error.localizedDescription)"
                self.isLoading = false
            }
            return nil
        }
    }
    
    /// Creates a default user profile with Cognito email and auto username
    private func createDefaultUserProfile(authUser: AuthUser, email: String) async -> User? {
        do {
            print("🔍 DEBUG: Creating default user profile...")
            
            // Auto-generate username as Player + first 5 chars of userId
            let defaultUsername = "Player" + String(authUser.userId.prefix(5))
            let cleanUsername = defaultUsername.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("🔍 DEBUG: Creating user with username: \(cleanUsername)")
            print("🔍 DEBUG: Email: \(cleanEmail)")
            
            guard !cleanUsername.isEmpty else {
                print("🔍 ERROR: Username is empty!")
                return nil
            }
            
            // Create user with AuthUser.userId as the ID to ensure consistency
            let newUser = User(
                id: authUser.userId, // Use AuthUser.userId as the User.id
                username: cleanUsername,
                email: cleanEmail.isEmpty ? "user@example.com" : cleanEmail,
                createdAt: Temporal.DateTime.now(),
                updatedAt: Temporal.DateTime.now()
            )
            
            print("🔍 DEBUG: About to call Amplify.API.mutate")
            let result = try await Amplify.API.mutate(request: .create(newUser))
            
            switch result {
            case .success(let createdUser):
                print("🔍 DEBUG: User created successfully: \(createdUser)")
                await MainActor.run {
                    self.currentUser = createdUser
                    // Notify other parts of the app that user profile was created
                    NotificationCenter.default.post(name: NSNotification.Name("UserProfileCreated"), object: createdUser)
                }
                return createdUser
            case .failure(let error):
                print("🔍 DEBUG: Failed to create user: \(error)")
                
                // Check if this is a duplicate user error
                if error.localizedDescription.contains("already exists") || 
                   error.localizedDescription.contains("duplicate") ||
                   error.localizedDescription.contains("unique constraint") {
                    print("🔍 DEBUG: Detected duplicate user creation, trying to find existing user...")
                    
                    // Try to find the existing user by email
                    let existingUser = await getUserByEmail(cleanEmail)
                    if let user = existingUser {
                        print("🔍 DEBUG: Found existing user after duplicate creation attempt: \(user.username)")
                        await MainActor.run {
                            self.currentUser = user
                        }
                        return user
                    }
                }
                
                await MainActor.run {
                    self.error = "Failed to create user profile: \(error.localizedDescription)"
                }
                return nil
            }
        } catch {
            print("🔍 DEBUG: Exception during user creation: \(error)")
            await MainActor.run {
                self.error = "Error creating user profile: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    /// Updates the user profile with new information
    func updateUserProfile(username: String, email: String) async -> Bool {
        guard let currentUser = currentUser else {
            await MainActor.run {
                self.error = "No current user to update"
            }
            return false
        }
        
        do {
            var updatedUser = currentUser
            updatedUser.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedUser.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedUser.updatedAt = Temporal.DateTime.now()
            
            let result = try await Amplify.API.mutate(request: .update(updatedUser))
            
            switch result {
            case .success(let updatedUser):
                await MainActor.run {
                    self.currentUser = updatedUser
                }
                return true
                
            case .failure(let error):
                await MainActor.run {
                    self.error = "Failed to update profile: \(error.localizedDescription)"
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.error = "Error updating profile: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    /// Loads the current user profile
    func loadCurrentUserProfile() async {
        isLoading = true
        
        do {
            // Get current user info using helper function that works for both guest and authenticated users
            guard let currentUserInfo = await getCurrentUser() else {
                print("🔍 DEBUG: Unable to get current user information")
                await MainActor.run {
                    self.currentUser = nil
                    self.error = "Unable to get current user information"
                    self.isLoading = false
                }
                return
            }
            
            let userId = currentUserInfo.userId
            let isGuest = currentUserInfo.isGuest
            
            print("🔍 DEBUG: Loading user profile for user: \(userId), isGuest: \(isGuest)")
            
            // For guest users, we don't need to fetch attributes
            let email = isGuest ? "guest@scoreboard.app" : ""
            
            // Find user by userId
            let result = try await Amplify.API.query(request: .list(User.self))
            
            await MainActor.run {
                switch result {
                case .success(let allUsers):
                    // First try to find by userId
                    if let user = allUsers.first(where: { $0.id == userId }) {
                        self.currentUser = user
                    } else if !isGuest, let user = allUsers.first(where: { $0.email == email && !email.isEmpty }) {
                        // Fallback to email lookup (only for non-guest users)
                        self.currentUser = user
                    } else {
                        self.currentUser = nil
                    }
                case .failure:
                    self.currentUser = nil
                }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.currentUser = nil
                self.error = "Error loading user profile: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Checks if the current user has a complete profile
    func hasCompleteProfile() -> Bool {
        guard let user = currentUser else { return false }
        
        // Check if user has meaningful username and email
        let hasValidUsername = !user.username.isEmpty && !user.username.hasPrefix("Player")
        let hasValidEmail = !user.email.isEmpty && user.email != "user@example.com"
        
        return hasValidUsername && hasValidEmail
    }
    
    // MARK: - Helper Methods
    
    /// Clears error state
    func clearError() {
        error = nil
    }
    
    /// Gets a user by their email (since ID is auto-generated)
    func getUserByEmail(_ email: String) async -> User? {
        do {
            print("🔍 DEBUG: getUserByEmail called with email: \(email)")
            let result = try await Amplify.API.query(request: .list(User.self))
            switch result {
            case .success(let allUsers):
                print("🔍 DEBUG: getUserByEmail found \(allUsers.count) total users")
                let foundUser = allUsers.first(where: { $0.email == email })
                if let user = foundUser {
                    print("🔍 DEBUG: Found user by email: \(user.username)")
                } else {
                    print("🔍 DEBUG: No user found with email: \(email)")
                }
                return foundUser
            case .failure(let error):
                print("🔍 DEBUG: Error getting user by email: \(error)")
                return nil
            }
        } catch {
            print("🔍 DEBUG: Exception getting user by email: \(error)")
            return nil
        }
    }
    
    /// Gets a user by their AuthUser.userId
    func getUserByAuthUserId(_ authUserId: String) async -> User? {
        do {
            print("🔍 DEBUG: getUserByAuthUserId called with authUserId: \(authUserId)")
            let result = try await Amplify.API.query(request: .list(User.self))
            switch result {
            case .success(let allUsers):
                print("🔍 DEBUG: getUserByAuthUserId found \(allUsers.count) total users")
                let foundUser = allUsers.first(where: { $0.id == authUserId })
                if let user = foundUser {
                    print("🔍 DEBUG: Found user by authUserId: \(user.username)")
                } else {
                    print("🔍 DEBUG: No user found with authUserId: \(authUserId)")
                }
                return foundUser
            case .failure(let error):
                print("🔍 DEBUG: Error getting user by authUserId: \(error)")
                return nil
            }
        } catch {
            print("🔍 DEBUG: Exception getting user by authUserId: \(error)")
            return nil
        }
    }
    
    /// Cleans up duplicate users (keeps the first one and deletes the rest)
    func cleanupDuplicateUsers() async {
        do {
            let result = try await Amplify.API.query(request: .list(User.self))
            switch result {
            case .success(let users):
                // Group users by their email
                let groupedUsers = Dictionary(grouping: users) { $0.email }
                
                for (email, duplicateUsers) in groupedUsers {
                    if duplicateUsers.count > 1 {
                        print("🔍 DEBUG: Found \(duplicateUsers.count) duplicate users for email: \(email)")
                        
                        // Sort by creation date to keep the oldest one
                        let sortedUsers = duplicateUsers.sorted { user1, user2 in
                            let date1 = user1.createdAt ?? Temporal.DateTime.now()
                            let date2 = user2.createdAt ?? Temporal.DateTime.now()
                            return date1 < date2
                        }
                        
                        // Keep the first (oldest) user, delete the rest
                        let usersToDelete = Array(sortedUsers.dropFirst())
                        
                        print("🔍 DEBUG: Keeping user: \(sortedUsers.first?.username ?? "unknown") (oldest)")
                        print("🔍 DEBUG: Deleting \(usersToDelete.count) duplicate users")
                        
                        for userToDelete in usersToDelete {
                            do {
                                let deleteResult = try await Amplify.API.mutate(request: .delete(userToDelete))
                                switch deleteResult {
                                case .success(let deletedUser):
                                    print("🔍 DEBUG: Successfully deleted duplicate user: \(deletedUser.username)")
                                case .failure(let error):
                                    print("🔍 DEBUG: Failed to delete duplicate user: \(error)")
                                }
                            } catch {
                                print("🔍 DEBUG: Error deleting duplicate user: \(error)")
                            }
                        }
                    }
                }
            case .failure(let error):
                print("🔍 DEBUG: Error listing users for cleanup: \(error)")
            }
        } catch {
            print("🔍 DEBUG: Error in cleanupDuplicateUsers: \(error)")
        }
    }
    
    /// Automatically migrates user if needed without UI interaction
    private func autoMigrateUserIfNeeded(authUser: AuthUser, email: String) async {
        do {
            print("🔍 DEBUG: ===== AUTO MIGRATION START =====")
            print("🔍 DEBUG: AuthUser ID: \(authUser.userId)")
            print("🔍 DEBUG: AuthUser email: \(email)")
            
            let result = try await Amplify.API.query(request: .list(User.self))
            switch result {
            case .success(let allUsers):
                print("🔍 DEBUG: Found \(allUsers.count) total users in database")
                
                // Check if there's already a user with the correct AuthUser ID
                if let existingUserWithCorrectID = allUsers.first(where: { $0.id == authUser.userId }) {
                    print("🔍 DEBUG: Found existing user with correct AuthUser ID: \(existingUserWithCorrectID.username)")
                    return
                }
                
                // Find user by email first (this is the key fix)
                var userToMigrate: User? = nil
                
                if !email.isEmpty {
                    userToMigrate = allUsers.first(where: { $0.email == email })
                    if let user = userToMigrate {
                        print("🔍 DEBUG: Found user by email to migrate: \(user.username)")
                    }
                }
                
                // If no user found by email, try any user with different ID
                if userToMigrate == nil {
                    userToMigrate = allUsers.first(where: { $0.id != authUser.userId })
                    if let user = userToMigrate {
                        print("🔍 DEBUG: Found user by different ID to migrate: \(user.username)")
                    }
                }
                
                if let existingUser = userToMigrate {
                    print("🔍 DEBUG: Found user to migrate...")
                    print("🔍 DEBUG: Existing user - ID: \(existingUser.id), Username: \(existingUser.username), Email: \(existingUser.email)")
                    print("🔍 DEBUG: Target AuthUser ID: \(authUser.userId)")
                    
                    // Create new user with correct ID
                    let migratedUser = User(
                        id: authUser.userId,
                        username: existingUser.username,
                        email: existingUser.email,
                        createdAt: existingUser.createdAt ?? Temporal.DateTime.now(),
                        updatedAt: Temporal.DateTime.now()
                    )
                    
                    do {
                        // Create the new user with correct ID
                        let createResult = try await Amplify.API.mutate(request: .create(migratedUser))
                        switch createResult {
                        case .success(let newUser):
                            print("🔍 DEBUG: Successfully created migrated user: \(newUser.username)")
                            
                            // Delete the old user
                            let deleteResult = try await Amplify.API.mutate(request: .delete(existingUser))
                            switch deleteResult {
                            case .success(let deletedUser):
                                print("🔍 DEBUG: Successfully deleted old user: \(deletedUser.username)")
                            case .failure(let error):
                                print("🔍 DEBUG: Failed to delete old user: \(error)")
                            }
                        case .failure(let error):
                            print("🔍 DEBUG: Failed to create migrated user: \(error)")
                        }
                    } catch {
                        print("🔍 DEBUG: Error during auto-migration: \(error)")
                    }
                } else {
                    print("🔍 DEBUG: No users found to migrate")
                }
            case .failure(let error):
                print("🔍 DEBUG: Error listing users for auto-migration: \(error)")
            }
            print("🔍 DEBUG: ===== AUTO MIGRATION END =====")
        } catch {
            print("🔍 DEBUG: Error in autoMigrateUserIfNeeded: \(error)")
        }
    }
    
    /// Migrates existing users to use AuthUser.userId as their ID
    func migrateUsersToAuthUserId() async {
        do {
            let authUser = try await Amplify.Auth.getCurrentUser()
            let attributes = try await Amplify.Auth.fetchUserAttributes()
            let email = attributes.first(where: { $0.key.rawValue == "email" })?.value ?? ""
            
            print("🔍 DEBUG: ===== MIGRATION START =====")
            print("🔍 DEBUG: AuthUser ID: \(authUser.userId)")
            print("🔍 DEBUG: AuthUser email: \(email)")
            
            let result = try await Amplify.API.query(request: .list(User.self))
            switch result {
            case .success(let allUsers):
                print("🔍 DEBUG: Found \(allUsers.count) total users in database")
                
                // Print all users for debugging
                for user in allUsers {
                    print("🔍 DEBUG: User - ID: \(user.id), Username: \(user.username), Email: \(user.email)")
                }
                
                // First, check if there's already a user with the correct AuthUser ID
                if let existingUserWithCorrectID = allUsers.first(where: { $0.id == authUser.userId }) {
                    print("🔍 DEBUG: Found existing user with correct AuthUser ID: \(existingUserWithCorrectID.username)")
                    return
                }
                
                // Try to find user by email first, then any user with different ID
                var userToMigrate: User? = nil
                
                // First try to find by email
                if !email.isEmpty {
                    userToMigrate = allUsers.first(where: { $0.email == email })
                    if let user = userToMigrate {
                        print("🔍 DEBUG: Found user by email to migrate: \(user.username)")
                    }
                }
                
                // If no user found by email, try any user with different ID
                if userToMigrate == nil {
                    userToMigrate = allUsers.first(where: { $0.id != authUser.userId })
                    if let user = userToMigrate {
                        print("🔍 DEBUG: Found user by different ID to migrate: \(user.username)")
                    }
                }
                
                if let existingUser = userToMigrate {
                    print("🔍 DEBUG: Found user to migrate...")
                    print("🔍 DEBUG: Existing user - ID: \(existingUser.id), Username: \(existingUser.username), Email: \(existingUser.email)")
                    print("🔍 DEBUG: Target AuthUser ID: \(authUser.userId)")
                    
                    // Create new user with correct ID
                    let migratedUser = User(
                        id: authUser.userId,
                        username: existingUser.username,
                        email: existingUser.email,
                        createdAt: existingUser.createdAt ?? Temporal.DateTime.now(),
                        updatedAt: Temporal.DateTime.now()
                    )
                    
                    do {
                        // Create the new user with correct ID
                        let createResult = try await Amplify.API.mutate(request: .create(migratedUser))
                        switch createResult {
                        case .success(let newUser):
                            print("🔍 DEBUG: Successfully created migrated user: \(newUser.username)")
                            
                            // Delete the old user
                            let deleteResult = try await Amplify.API.mutate(request: .delete(existingUser))
                            switch deleteResult {
                            case .success(let deletedUser):
                                print("🔍 DEBUG: Successfully deleted old user: \(deletedUser.username)")
                            case .failure(let error):
                                print("🔍 DEBUG: Failed to delete old user: \(error)")
                            }
                        case .failure(let error):
                            print("🔍 DEBUG: Failed to create migrated user: \(error)")
                        }
                    } catch {
                        print("🔍 DEBUG: Error during migration: \(error)")
                    }
                } else {
                    print("🔍 DEBUG: No users found to migrate")
                }
            case .failure(let error):
                print("🔍 DEBUG: Error listing users for migration: \(error)")
            }
            print("🔍 DEBUG: ===== MIGRATION END =====")
        } catch {
            print("🔍 DEBUG: Error in migrateUsersToAuthUserId: \(error)")
        }
    }
    
    /// Manually creates a user with the correct AuthUser ID
    func createUserWithCorrectID() async {
        do {
            let authUser = try await Amplify.Auth.getCurrentUser()
            let attributes = try await Amplify.Auth.fetchUserAttributes()
            let email = attributes.first(where: { $0.key.rawValue == "email" })?.value ?? ""
            
            print("🔍 DEBUG: ===== CREATE USER WITH CORRECT ID =====")
            print("🔍 DEBUG: AuthUser ID: \(authUser.userId)")
            print("🔍 DEBUG: AuthUser email: \(email)")
            
            // Auto-generate username as Player + first 5 chars of userId
            let defaultUsername = "Player" + String(authUser.userId.prefix(5))
            let cleanUsername = defaultUsername.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("🔍 DEBUG: Creating user with username: \(cleanUsername)")
            print("🔍 DEBUG: Email: \(cleanEmail)")
            
            // Create user with AuthUser.userId as the ID
            let newUser = User(
                id: authUser.userId,
                username: cleanUsername,
                email: cleanEmail.isEmpty ? "user@example.com" : cleanEmail,
                createdAt: Temporal.DateTime.now(),
                updatedAt: Temporal.DateTime.now()
            )
            
            let result = try await Amplify.API.mutate(request: .create(newUser))
            
            switch result {
            case .success(let createdUser):
                print("🔍 DEBUG: Successfully created user with correct ID: \(createdUser.username)")
                await MainActor.run {
                    self.currentUser = createdUser
                }
            case .failure(let error):
                print("🔍 DEBUG: Failed to create user with correct ID: \(error)")
                
                // If creation fails, try to find existing user and update it
                if error.localizedDescription.contains("already exists") {
                    print("🔍 DEBUG: User already exists, trying to find and update...")
                    let existingUser = await getUserByAuthUserId(authUser.userId)
                    if let user = existingUser {
                        print("🔍 DEBUG: Found existing user with correct ID: \(user.username)")
                        await MainActor.run {
                            self.currentUser = user
                        }
                    }
                }
            }
            
            print("🔍 DEBUG: ===== CREATE USER WITH CORRECT ID END =====")
        } catch {
            print("🔍 DEBUG: Error in createUserWithCorrectID: \(error)")
        }
    }
    
    /// Force creates a user with correct ID by deleting existing users first
    func forceCreateUserWithCorrectID() async {
        do {
            let authUser = try await Amplify.Auth.getCurrentUser()
            let attributes = try await Amplify.Auth.fetchUserAttributes()
            let email = attributes.first(where: { $0.key.rawValue == "email" })?.value ?? ""
            
            print("🔍 DEBUG: ===== FORCE CREATE USER WITH CORRECT ID =====")
            print("🔍 DEBUG: AuthUser ID: \(authUser.userId)")
            print("🔍 DEBUG: AuthUser email: \(email)")
            
            // First, delete any existing users with the same email or different IDs
            let result = try await Amplify.API.query(request: .list(User.self))
            switch result {
            case .success(let allUsers):
                print("🔍 DEBUG: Found \(allUsers.count) total users in database")
                
                // Delete users with same email or different IDs
                for user in allUsers {
                    if user.email == email || user.id != authUser.userId {
                        print("🔍 DEBUG: Deleting user: \(user.username) (ID: \(user.id))")
                        do {
                            let deleteResult = try await Amplify.API.mutate(request: .delete(user))
                            switch deleteResult {
                            case .success(let deletedUser):
                                print("🔍 DEBUG: Successfully deleted user: \(deletedUser.username)")
                            case .failure(let error):
                                print("🔍 DEBUG: Failed to delete user: \(error)")
                            }
                        } catch {
                            print("🔍 DEBUG: Error deleting user: \(error)")
                        }
                    }
                }
            case .failure(let error):
                print("🔍 DEBUG: Error listing users: \(error)")
            }
            
            // Now create the new user with correct ID
            let defaultUsername = "Player" + String(authUser.userId.prefix(5))
            let cleanUsername = defaultUsername.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("🔍 DEBUG: Creating new user with username: \(cleanUsername)")
            
            let newUser = User(
                id: authUser.userId,
                username: cleanUsername,
                email: cleanEmail.isEmpty ? "user@example.com" : cleanEmail,
                createdAt: Temporal.DateTime.now(),
                updatedAt: Temporal.DateTime.now()
            )
            
            let createResult = try await Amplify.API.mutate(request: .create(newUser))
            
            switch createResult {
            case .success(let createdUser):
                print("🔍 DEBUG: Successfully created user with correct ID: \(createdUser.username)")
                await MainActor.run {
                    self.currentUser = createdUser
                }
            case .failure(let error):
                print("🔍 DEBUG: Failed to create user: \(error)")
            }
            
            print("🔍 DEBUG: ===== FORCE CREATE USER WITH CORRECT ID END =====")
        } catch {
            print("🔍 DEBUG: Error in forceCreateUserWithCorrectID: \(error)")
        }
    }
    
    /// Deletes the current user's account
    func deleteAccount() async -> Bool {
        guard let currentUser = currentUser else {
            await MainActor.run {
                self.error = "No current user to delete"
            }
            return false
        }
        
        do {
            // Delete the user from the database
            let result = try await Amplify.API.mutate(request: .delete(currentUser))
            
            switch result {
            case .success:
                // Clear the current user
                await MainActor.run {
                    self.currentUser = nil
                }
                
                // Sign out the user
                try await Amplify.Auth.signOut()
                
                return true
                
            case .failure(let error):
                await MainActor.run {
                    self.error = "Failed to delete account: \(error.localizedDescription)"
                }
                return false
            }
        } catch {
            await MainActor.run {
                self.error = "Error deleting account: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // Guest profile creation is now handled in ensureUserProfile
    // This method is no longer needed
} 