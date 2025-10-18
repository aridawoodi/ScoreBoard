//
//  GuestMigrationService.swift
//  ScoreBoard
//
//  Service to handle migration from guest user to authenticated account
//

import Foundation
import Amplify

enum MigrationError: Error {
    case noGuestUser
    case emailAlreadyExists
    case signUpFailed(String)
    case confirmationFailed(String)
    case gameUpdateFailed(String)
    case userProfileUpdateFailed(String)
    case rollbackFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .noGuestUser:
            return "No guest user found to migrate"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .signUpFailed(let message):
            return "Sign up failed: \(message)"
        case .confirmationFailed(let message):
            return "Email confirmation failed: \(message)"
        case .gameUpdateFailed(let message):
            return "Failed to update games: \(message)"
        case .userProfileUpdateFailed(let message):
            return "Failed to update user profile: \(message)"
        case .rollbackFailed(let message):
            return "Migration failed and rollback encountered errors: \(message)"
        }
    }
}

struct MigrationProgress {
    var currentStep: String
    var completedSteps: Int
    var totalSteps: Int
    var percentage: Double {
        return Double(completedSteps) / Double(totalSteps)
    }
}

class GuestMigrationService: ObservableObject {
    static let shared = GuestMigrationService()
    
    @Published var migrationProgress: MigrationProgress?
    @Published var isMigrating: Bool = false
    
    private init() {}
    
    // MARK: - Main Migration Function
    
    /// Converts a guest user to an authenticated account and migrates all data
    /// - Parameters:
    ///   - email: Email for the new authenticated account
    ///   - password: Password for the new authenticated account
    ///   - confirmationCode: Email verification code (optional, if already confirmed)
    /// - Returns: The new authenticated user ID
    func migrateGuestToAuthenticatedAccount(
        email: String,
        password: String,
        onProgress: @escaping (MigrationProgress) -> Void
    ) async throws -> String {
        
        await MainActor.run {
            isMigrating = true
        }
        
        let totalSteps = 8
        var currentStep = 0
        
        // Helper to update progress
        func updateProgress(step: String) async {
            currentStep += 1
            let progress = MigrationProgress(
                currentStep: step,
                completedSteps: currentStep,
                totalSteps: totalSteps
            )
            await MainActor.run {
                migrationProgress = progress
                onProgress(progress)
            }
        }
        
        do {
            // STEP 1: Verify guest user exists
            await updateProgress(step: "Verifying guest account...")
            
            guard let guestUserId = UserDefaults.standard.string(forKey: "current_guest_user_id"),
                  UserDefaults.standard.bool(forKey: "is_guest_user") else {
                throw MigrationError.noGuestUser
            }
            
            print("🔍 DEBUG: GuestMigration - Starting migration for guest user: \(guestUserId)")
            
            // Fetch guest user profile
            let guestUserResult = try await Amplify.API.query(request: .get(User.self, byId: guestUserId))
            guard case .success(let guestUser) = guestUserResult, let guestUser = guestUser else {
                throw MigrationError.noGuestUser
            }
            
            print("🔍 DEBUG: GuestMigration - Guest user profile: \(guestUser.username)")
            
            // STEP 2: Create Cognito authenticated account
            await updateProgress(step: "Creating authenticated account...")
            
            // Check if current user is signed in (as guest)
            let currentAuthState = try await Amplify.Auth.fetchAuthSession()
            if currentAuthState.isSignedIn {
                print("🔍 DEBUG: GuestMigration - Signing out guest user before creating authenticated account")
                _ = try await Amplify.Auth.signOut()
            }
            
            // Sign up with Cognito
            let signUpResult = try await Amplify.Auth.signUp(
                username: email,
                password: password,
                options: .init(userAttributes: [AuthUserAttribute(.email, value: email)])
            )
            
            // Check if we need email confirmation
            switch signUpResult.nextStep {
            case .confirmUser:
                print("🔍 DEBUG: GuestMigration - Sign up requires email confirmation")
                // Continue to confirmation step
            case .done:
                print("🔍 DEBUG: GuestMigration - Sign up completed without confirmation")
                // No confirmation needed
            case .completeAutoSignIn:
                print("🔍 DEBUG: GuestMigration - Auto sign-in required")
                // Auto sign-in case
            }
            
            print("🔍 DEBUG: GuestMigration - Sign up initiated successfully")
            
            // Note: Email confirmation will be handled by completeMigration()
            // Return guest ID so the calling view can proceed to confirmation
            
            return guestUserId // Return guest ID for confirmation step
            
        } catch let error as MigrationError {
            await MainActor.run {
                isMigrating = false
                migrationProgress = nil
            }
            throw error
        } catch {
            await MainActor.run {
                isMigrating = false
                migrationProgress = nil
            }
            throw MigrationError.signUpFailed(error.localizedDescription)
        }
    }
    
    /// Complete the migration after email confirmation
    func completeMigration(
        email: String,
        password: String,
        confirmationCode: String,
        guestUserId: String,
        onProgress: @escaping (MigrationProgress) -> Void
    ) async throws -> String {
        
        let totalSteps = 8
        var currentStep = 2 // Starting from step 3 (steps 1-2 were done in initial migration)
        
        // Helper to update progress
        func updateProgress(step: String) async {
            currentStep += 1
            let progress = MigrationProgress(
                currentStep: step,
                completedSteps: currentStep,
                totalSteps: totalSteps
            )
            await MainActor.run {
                migrationProgress = progress
                onProgress(progress)
            }
        }
        
        do {
            // STEP 3: Confirm email
            await updateProgress(step: "Confirming email...")
            
            let confirmResult = try await Amplify.Auth.confirmSignUp(
                for: email,
                confirmationCode: confirmationCode
            )
            
            guard confirmResult.isSignUpComplete else {
                throw MigrationError.confirmationFailed("Email confirmation incomplete")
            }
            
            print("🔍 DEBUG: GuestMigration - Email confirmed successfully")
            
            // STEP 4: Sign in with new account
            await updateProgress(step: "Signing in to new account...")
            
            let signInResult = try await Amplify.Auth.signIn(username: email, password: password)
            guard signInResult.isSignedIn else {
                throw MigrationError.signUpFailed("Sign in failed after confirmation")
            }
            
            let authUser = try await Amplify.Auth.getCurrentUser()
            let newAuthUserId = authUser.userId
            
            print("🔍 DEBUG: GuestMigration - Signed in as authenticated user: \(newAuthUserId)")
            
            // Fetch guest user profile
            let guestUserResult = try await Amplify.API.query(request: .get(User.self, byId: guestUserId))
            guard case .success(let guestUser) = guestUserResult, let guestUser = guestUser else {
                throw MigrationError.noGuestUser
            }
            
            // STEP 5: Fetch all games where user is involved
            await updateProgress(step: "Fetching your games...")
            
            let allGamesResult = try await Amplify.API.query(request: .list(Game.self))
            guard case .success(let allGames) = allGamesResult else {
                throw MigrationError.gameUpdateFailed("Failed to fetch games")
            }
            
            // Filter to games where guest user is host or player
            let guestGames = allGames.filter { game in
                // Check if guest is the host
                if game.hostUserID == guestUserId {
                    return true
                }
                
                // Check if guest is in playerIDs
                if game.playerIDs.contains(guestUserId) {
                    return true
                }
                
                // Check if guest is in playerHierarchy
                if game.hasPlayerHierarchy {
                    let hierarchy = game.getPlayerHierarchy()
                    for (_, children) in hierarchy {
                        if children.contains(where: { $0.hasPrefix(guestUserId) }) {
                            return true
                        }
                    }
                }
                
                return false
            }
            
            print("🔍 DEBUG: GuestMigration - Found \(guestGames.count) games to migrate")
            
            // STEP 6: Update all games
            await updateProgress(step: "Migrating \(guestGames.count) games...")
            
            var updatedGamesCount = 0
            var failedGames: [String] = []
            
            for game in guestGames {
                do {
                    var updatedGame = game
                    var needsUpdate = false
                    
                    // Update hostUserID if guest is the host
                    if game.hostUserID == guestUserId {
                        updatedGame.hostUserID = newAuthUserId
                        needsUpdate = true
                        print("🔍 DEBUG: GuestMigration - Updating hostUserID for game \(game.id)")
                    }
                    
                    // Update playerIDs if guest is in the list
                    if game.playerIDs.contains(guestUserId) {
                        updatedGame.playerIDs = game.playerIDs.map { playerID in
                            playerID == guestUserId ? newAuthUserId : playerID
                        }
                        needsUpdate = true
                        print("🔍 DEBUG: GuestMigration - Updated playerIDs for game \(game.id)")
                    }
                    
                    // Update playerHierarchy if guest is a child player
                    if game.hasPlayerHierarchy {
                        var hierarchy = game.getPlayerHierarchy()
                        var hierarchyUpdated = false
                        
                        for (team, children) in hierarchy {
                            hierarchy[team] = children.map { child in
                                if child.hasPrefix(guestUserId) {
                                    let username = child.components(separatedBy: ":").last ?? guestUser.username
                                    hierarchyUpdated = true
                                    print("🔍 DEBUG: GuestMigration - Updating child player in team \(team): \(guestUserId) → \(newAuthUserId)")
                                    return "\(newAuthUserId):\(username)"
                                }
                                return child
                            }
                        }
                        
                        if hierarchyUpdated {
                            // Encode updated hierarchy
                            if let data = try? JSONEncoder().encode(hierarchy),
                               let hierarchyJSON = String(data: data, encoding: .utf8) {
                                updatedGame.playerHierarchy = hierarchyJSON
                                needsUpdate = true
                            }
                        }
                    }
                    
                    // Update the game if any changes were made
                    if needsUpdate {
                        updatedGame.updatedAt = Temporal.DateTime.now()
                        let updateResult = try await Amplify.API.mutate(request: .update(updatedGame))
                        
                        switch updateResult {
                        case .success:
                            updatedGamesCount += 1
                            print("🔍 DEBUG: GuestMigration - Successfully updated game \(game.id)")
                            
                            // Notify DataManager of the update
                            await MainActor.run {
                                DataManager.shared.onGameUpdated(updatedGame)
                            }
                        case .failure(let error):
                            print("🔍 DEBUG: GuestMigration - Failed to update game \(game.id): \(error)")
                            failedGames.append(game.id)
                        }
                    }
                } catch {
                    print("🔍 DEBUG: GuestMigration - Error updating game \(game.id): \(error)")
                    failedGames.append(game.id)
                }
            }
            
            print("🔍 DEBUG: GuestMigration - Updated \(updatedGamesCount) games, \(failedGames.count) failed")
            
            if !failedGames.isEmpty {
                print("🔍 DEBUG: GuestMigration - Failed games: \(failedGames)")
            }
            
            // STEP 7: Create new authenticated user profile
            await updateProgress(step: "Creating user profile...")
            
            let newUser = User(
                id: newAuthUserId,
                username: guestUser.username,  // Keep the same username
                email: email,  // Use authenticated email
                createdAt: guestUser.createdAt,  // Preserve original creation date
                updatedAt: Temporal.DateTime.now()
            )
            
            let createUserResult = try await Amplify.API.mutate(request: .create(newUser))
            guard case .success(let createdUser) = createUserResult else {
                throw MigrationError.userProfileUpdateFailed("Failed to create authenticated user profile")
            }
            
            print("🔍 DEBUG: GuestMigration - Created authenticated user profile: \(createdUser.username)")
            
            // STEP 8: Update local storage and cleanup
            await updateProgress(step: "Finalizing migration...")
            
            await MainActor.run {
                // Update UserDefaults
                UserDefaults.standard.set(false, forKey: "is_guest_user")
                UserDefaults.standard.set(newAuthUserId, forKey: "authenticated_user_id")
                UserDefaults.standard.removeObject(forKey: "current_guest_user_id")
                
                // Migrate user-specific storage
                UserSpecificStorageManager.shared.migrateGuestToAuthenticated(
                    from: guestUserId,
                    to: newAuthUserId
                )
                
                print("🔍 DEBUG: GuestMigration - Updated local storage")
            }
            
            // Update DataManager with new user ID
            await DataManager.shared.setCurrentUser(id: newAuthUserId)
            
            // STEP 9: Delete old guest user profile
            await updateProgress(step: "Cleaning up old guest profile...")
            
            do {
                let deleteResult = try await Amplify.API.mutate(request: .delete(guestUser))
                switch deleteResult {
                case .success:
                    print("🔍 DEBUG: GuestMigration - ✅ Deleted old guest user profile")
                case .failure(let error):
                    print("🔍 DEBUG: GuestMigration - ⚠️ Failed to delete old guest user: \(error)")
                    // Don't throw - migration is still successful even if cleanup fails
                }
            } catch {
                print("🔍 DEBUG: GuestMigration - ⚠️ Error deleting old guest user: \(error)")
                // Continue - this is non-critical
            }
            
            await updateProgress(step: "Migration complete!")
            
            await MainActor.run {
                isMigrating = false
                migrationProgress = nil
            }
            
            print("🔍 DEBUG: GuestMigration - ✅ Migration completed successfully!")
            print("🔍 DEBUG: GuestMigration - Old guest ID: \(guestUserId)")
            print("🔍 DEBUG: GuestMigration - New authenticated ID: \(newAuthUserId)")
            print("🔍 DEBUG: GuestMigration - Migrated \(updatedGamesCount) games")
            
            return newAuthUserId
            
        } catch let error as MigrationError {
            await MainActor.run {
                isMigrating = false
                migrationProgress = nil
            }
            throw error
        } catch {
            await MainActor.run {
                isMigrating = false
                migrationProgress = nil
            }
            throw MigrationError.signUpFailed(error.localizedDescription)
        }
    }
}

// MARK: - UserSpecificStorageManager Extension for Migration

extension UserSpecificStorageManager {
    /// Migrates all user-specific data from guest to authenticated user
    func migrateGuestToAuthenticated(from guestUserId: String, to authenticatedUserId: String) {
        print("🔍 DEBUG: UserSpecificStorageManager - Migrating data from \(guestUserId) to \(authenticatedUserId)")
        
        let keysToMigrate = [
            "default_game_settings",
            "last_game_settings",
            "game_templates",
            "current_user_username"
        ]
        
        for baseKey in keysToMigrate {
            let guestKey = "\(baseKey)_\(guestUserId)"
            let authKey = "\(baseKey)_\(authenticatedUserId)"
            
            if let data = UserDefaults.standard.data(forKey: guestKey) {
                UserDefaults.standard.set(data, forKey: authKey)
                print("🔍 DEBUG: UserSpecificStorageManager - Migrated \(baseKey)")
            } else if let string = UserDefaults.standard.string(forKey: guestKey) {
                UserDefaults.standard.set(string, forKey: authKey)
                print("🔍 DEBUG: UserSpecificStorageManager - Migrated \(baseKey)")
            }
        }
        
        // Migrate profile setup flags
        let setupKeys = [
            "profile_setup_completed",
            "profile_setup_skipped",
            "username_validated"
        ]
        
        for baseKey in setupKeys {
            let guestKey = "\(baseKey)_\(guestUserId)"
            let authKey = "\(baseKey)_\(authenticatedUserId)"
            
            if UserDefaults.standard.object(forKey: guestKey) != nil {
                let value = UserDefaults.standard.bool(forKey: guestKey)
                UserDefaults.standard.set(value, forKey: authKey)
                print("🔍 DEBUG: UserSpecificStorageManager - Migrated \(baseKey): \(value)")
            }
        }
        
        print("🔍 DEBUG: UserSpecificStorageManager - Migration completed")
    }
}

