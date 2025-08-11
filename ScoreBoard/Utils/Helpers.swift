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

/// Create a GuestUser for guest users
func createGuestUser(userId: String) -> GuestUser {
    return GuestUser(
        userId: userId,
        username: "Guest User",
        email: "guest@scoreboard.app"
    )
}

