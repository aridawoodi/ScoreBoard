//
//  CreateUserProfileView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/5/24.
//

import SwiftUI

struct CreateUserProfileView: View {
    @Binding var showUserProfile: Bool
    @Binding var userProfile: User?
    
    var body: some View {
        UserProfileView()
            .onDisappear {
                // Refresh user profile when sheet is dismissed
                Task {
                    if let profile = await AmplifyService.checkUserProfile() {
                        await MainActor.run {
                            self.userProfile = profile
                        }
                    }
                }
            }
    }
} 