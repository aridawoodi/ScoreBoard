//
//  ProfileEditView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI
import Amplify

struct ProfileEditView: View {
    @StateObject private var userService = UserService.shared
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isProfileUpdated = false
    @State private var isGuestUser = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Edit Your Profile")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Update your profile information to personalize your experience")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Profile Form
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.headline)
                            .foregroundColor(.white)
                        TextField("Enter your username", text: $username)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                            .foregroundColor(.white)
                        TextField("Email", text: $email)
                            .foregroundColor(isGuestUser ? .white : .white.opacity(0.5))
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .disabled(!isGuestUser) // Only editable for guest users
                    }
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                
                // Profile Info Section
                if let user = userService.currentUser {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Profile Information")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                Text("User ID")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(user.id.prefix(8))
                                    .fontWeight(.semibold)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.green)
                                Text("Member Since")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(formatDate(user.createdAt) ?? "Unknown")
                                    .fontWeight(.semibold)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                                    }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                }
                
                // Update Button
                Button(action: {
                    updateProfile()
                }) {
                    if isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Updating...")
                        }
                        .frame(maxWidth: .infinity)
                    } else {
                        Text("Update Profile")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(isLoading || username.isEmpty || email.isEmpty)
                .foregroundColor(.white)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
                .controlSize(.large)
                

                
                Spacer()
            }
            .padding()

            .alert("Profile Update", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .overlay(
                ZStack {
                    // Cancel button at the top
                    VStack {
                        HStack {
                            Button("Cancel") {
                                dismiss()
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(8)
                            
                            Spacer()
                        }
                        .padding()
                        Spacer()
                    }
                    
                    // Success message overlay that doesn't affect Cancel button
                    if isProfileUpdated {
                        VStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.green)
                                Text("Profile Updated Successfully!")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Your profile information has been updated")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(12)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 100)
                        }
                    }
                }
            )
            .onAppear {
                loadCurrentProfile()
                // Check if current user is a guest
                isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
                
                // Handle email loading
                Task {
                    if isGuestUser {
                        // For guest users, use the email from the user profile or default
                        if let user = userService.currentUser {
                            await MainActor.run {
                                self.email = user.email
                            }
                        } else {
                            await MainActor.run {
                                self.email = "guest@scoreboard.app"
                            }
                        }
                    } else {
                        // For authenticated users, fetch Cognito email
                        do {
                            let attributes = try await Amplify.Auth.fetchUserAttributes()
                            if let cognitoEmail = attributes.first(where: { $0.key.rawValue == "email" })?.value {
                                await MainActor.run {
                                    self.email = cognitoEmail
                                }
                            }
                        } catch {
                            print("Failed to fetch Cognito email: \(error)")
                        }
                    }
                }
            }
            .gradientBackground()
        }
    }
    
    func loadCurrentProfile() {
        Task {
            // Load the current user profile first
            await userService.loadCurrentUserProfile()
            
            await MainActor.run {
                if let user = userService.currentUser {
                    username = user.username
                    // Email will be set in onAppear based on user type
                } else {
                    // If no user profile exists, try to create one for guest users
                    let isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
                    if isGuestUser {
                        // For guest users, ensure the profile exists by calling ensureUserProfile
                        Task {
                            if let guestProfile = await userService.ensureUserProfile() {
                                await MainActor.run {
                                    username = guestProfile.username
                                    email = guestProfile.email
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func updateProfile() {
        guard !username.isEmpty && !email.isEmpty else {
            alertMessage = "Please fill in all fields."
            showAlert = true
            return
        }
        isLoading = true
        Task {
            let success = await userService.updateUserProfile(username: username, email: email)
            await MainActor.run {
                isLoading = false
                if success {
                    isProfileUpdated = true
                    // Post notification to refresh profile in other views
                    print("🔍 DEBUG: Profile updated successfully - posting ProfileUpdated notification")
                    NotificationCenter.default.post(name: NSNotification.Name("ProfileUpdated"), object: nil)
                } else {
                    alertMessage = userService.error ?? "Failed to update profile"
                    showAlert = true
                }
            }
        }
    }
    
    // Helper function to format Temporal.DateTime
    func formatDate(_ date: Temporal.DateTime?) -> String? {
        guard let date = date else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        return formatter.string(from: date.foundationDate ?? Date())
    }
} 