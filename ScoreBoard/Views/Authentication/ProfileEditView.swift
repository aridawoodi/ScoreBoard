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
                    
                    Text("Update your profile information to personalize your experience")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Profile Form
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.headline)
                        TextField("Enter your username", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .disabled(!isGuestUser) // Only editable for guest users
                            .foregroundColor(isGuestUser ? .primary : .gray)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Profile Info Section
                if let user = userService.currentUser {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Profile Information")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                Text("User ID")
                                Spacer()
                                Text(user.id.prefix(8))
                                    .fontWeight(.semibold)
                                    .font(.caption)
                            }
                            
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.green)
                                Text("Member Since")
                                Spacer()
                                Text(formatDate(user.createdAt) ?? "Unknown")
                                    .fontWeight(.semibold)
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemGray6))
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
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                if isProfileUpdated {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Profile Updated Successfully!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Your profile information has been updated")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
            .alert("Profile Update", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadCurrentProfile()
                // Check if current user is a guest
                isGuestUser = UserDefaults.standard.bool(forKey: "is_guest_user")
                
                // Only fetch Cognito email for authenticated users, not guest users
                Task {
                    if isGuestUser {
                        // For guest users, use a placeholder email
                        await MainActor.run {
                            self.email = "guest@scoreboard.app"
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
        }
    }
    
    func loadCurrentProfile() {
        if let user = userService.currentUser {
            username = user.username
            // Do not set email here, let onAppear fetch from Cognito
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