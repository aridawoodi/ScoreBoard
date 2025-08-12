//
//  Helpers.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation
import Amplify

struct Helpers {
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Temporal.DateTime Extensions
extension Temporal.DateTime {
    var foundationDate: Date? {
        ISO8601DateFormatter().date(from: self.iso8601String)
    }
}

// MARK: - User Management Helpers

/// Get current user that works for both guest and authenticated users
func getCurrentUser() async -> (userId: String, isGuest: Bool)? {
    do {
        // Check if we're in guest mode
        let isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
        
        if isGuestUser {
            // Handle guest user
            let guestUserId = UserDefaults.standard.string(forKey: "current_guest_user_id") ?? ""
            print("🔍 DEBUG: Getting guest user with ID: \(guestUserId)")
            return (userId: guestUserId, isGuest: true)
        } else {
            // Handle regular authenticated user
            let user = try await Amplify.Auth.getCurrentUser()
            print("🔍 DEBUG: Getting authenticated user with ID: \(user.userId)")
            return (userId: user.userId, isGuest: false)
        }
    } catch {
        print("🔍 DEBUG: Error getting current user: \(error)")
        return nil
    }
}

// Guest user creation is now handled directly in UserService.ensureUserProfile()
// This function is no longer needed

/// Ensure API calls work for guest users by using API key authentication
func ensureGuestAPIAccess() async {
    let isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
    if isGuestUser {
        print("🔍 DEBUG: Ensuring API access for guest user")
        
        // Test API access by trying to list games
        do {
            print("🔍 DEBUG: Testing API access for guest user...")
            let result = try await Amplify.API.query(request: .list(Game.self))
            switch result {
            case .success(let games):
                print("🔍 DEBUG: API access successful! Found \(games.count) games")
            case .failure(let error):
                print("🔍 DEBUG: API access failed: \(error)")
                print("🔍 DEBUG: This indicates the API key may have expired or there's a configuration issue")
            }
        } catch {
            print("🔍 DEBUG: API test failed with exception: \(error)")
        }
    }
}

