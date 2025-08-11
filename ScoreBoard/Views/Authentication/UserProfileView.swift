//
//  UserProfileView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/5/24.
//

import SwiftUI
import Amplify

struct UserProfileView: View {
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isProfileCreated = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create Your Profile")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Set up your profile so other players can find and invite you to games")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
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
                        TextField("Enter your email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Button(action: {
                    createProfile()
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Profile")
                    }
                }
                .disabled(isLoading || username.isEmpty || email.isEmpty)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
                if isProfileCreated {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Profile Created Successfully!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Other players can now find and invite you to games")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Continue") {
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("User Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Skip") {
                    dismiss()
                }
            )
            .alert("Profile Creation", isPresented: $showAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                loadUserAttributes()
            }
        }
    }
    
    func loadUserAttributes() {
        Task {
            do {
                let attributes = try await Amplify.Auth.fetchUserAttributes()
                let email = attributes.first(where: { $0.key.rawValue == "email" })?.value ?? ""
                
                await MainActor.run {
                    self.email = email
                }
            } catch {
                print("Error loading user attributes: \(error)")
            }
        }
    }
    
    func createProfile() {
        guard !username.isEmpty && !email.isEmpty else {
            alertMessage = "Please fill in all fields."
            showAlert = true
            return
        }
        
        isLoading = true
        Task {
            do {
                print("🔍 DEBUG: Starting profile creation...")
                
                // Prepare user data
                let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
                let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                
                print("🔍 DEBUG: Username: '\(trimmedUsername)'")
                print("🔍 DEBUG: Email: '\(trimmedEmail)'")
                
                // Create user without ID (let backend auto-generate)
                let userToCreate = User(
                    id: UUID().uuidString, username: trimmedUsername,
                    email: trimmedEmail,
                    createdAt: Temporal.DateTime.now(),
                    updatedAt: Temporal.DateTime.now()
                )
                
                print("🔍 DEBUG: User to create: \(userToCreate)")
                
                let createResult = try await Amplify.API.mutate(request: .create(userToCreate))
                
                await MainActor.run {
                    isLoading = false
                    switch createResult {
                    case .success(let createdUser):
                        print("🔍 DEBUG: Profile created successfully with ID: \(createdUser.id)")
                        isProfileCreated = true
                    case .failure(let error):
                        print("🔍 DEBUG: Creation failed: \(error)")
                        print("🔍 DEBUG: Error type: \(type(of: error))")
                        
                        // Check if this is a duplicate user error
                        if error.localizedDescription.contains("already exists") || 
                           error.localizedDescription.contains("duplicate") ||
                           error.localizedDescription.contains("unique constraint") {
                            print("🔍 DEBUG: Detected duplicate user creation in UserProfileView")
                            
                            // Try to find existing user by email
                            let userService = UserService.shared
                            Task {
                                let existingUser = await userService.getUserByEmail(trimmedEmail)
                                await MainActor.run {
                                    if let user = existingUser {
                                        print("🔍 DEBUG: Found existing user: \(user.username)")
                                        alertMessage = "Profile already exists for this email. Using existing profile."
                                        showAlert = true
                                        // Still mark as created since we found the user
                                        isProfileCreated = true
                                    } else {
                                        alertMessage = "Failed to create profile: \(error.localizedDescription)"
                                        showAlert = true
                                    }
                                }
                            }
                        } else {
                            if let graphQLError = error as? GraphQLResponseError<User> {
                                print("🔍 DEBUG: GraphQL Error details: \(graphQLError)")
                                print("🔍 DEBUG: GraphQL Error description: \(graphQLError.localizedDescription)")
                            }
                            alertMessage = "Failed to create profile: \(error.localizedDescription)"
                            showAlert = true
                        }
                    }
                }
            } catch {
                print("🔍 DEBUG: General error: \(error)")
                await MainActor.run {
                    isLoading = false
                    alertMessage = "Error: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
} 
