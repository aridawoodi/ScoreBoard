//
//  CustomSignInView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/5/24.
//

import SwiftUI
import Amplify

struct CustomSignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    
    let onSignInSuccess: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            Text("Welcome to ScoreBoard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 30)
            
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("", text: $email)
                    .modifier(AppTextFieldStyle(placeholder: "Enter your email", text: $email))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.headline)
                    .foregroundColor(.white)
                
                SecureField("", text: $password)
                    .modifier(AppTextFieldStyle(placeholder: "Enter your password", text: $password))
            }
            
            // Sign In button
            Button(action: signIn) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Sign In")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color("LightGreen"))
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isLoading || email.isEmpty || password.isEmpty)
            .opacity((isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
            
            // Forgot Password and Create Account buttons on same line
            HStack {
                Button(action: { showForgotPassword = true }) {
                    Text("Forgot Password?")
                        .font(.subheadline)
                        .foregroundColor(Color("LightGreen"))
                }
                
                Spacer()
                
                Button(action: { showSignUp = true }) {
                    Text("Create Account")
                        .font(.subheadline)
                        .foregroundColor(Color("LightGreen"))
                }
            }
            

            
            // Continue as Guest button
            VStack(spacing: 16) {
                Divider()
                    .background(Color.white.opacity(0.3))
                
                Text("Or")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                Button(action: {
                    Task {
                        await signInAsGuest()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 18, weight: .medium))
                        
                        Text("Continue as Guest")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color("LightGreen"))
                    .cornerRadius(10)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showSignUp) {
            CustomSignUpView(onSignUpSuccess: {
                showSignUp = false
                onSignInSuccess()
            })
        }
        .sheet(isPresented: $showForgotPassword) {
            CustomForgotPasswordView(onResetSuccess: {
                showForgotPassword = false
            })
        }
    }
    
    private func signIn() {
        isLoading = true
        
        Task {
            do {
                // Check if there's already a user signed in (guest or authenticated)
                let currentAuthState = try await Amplify.Auth.fetchAuthSession()
                
                if currentAuthState.isSignedIn {
                    print("🔍 DEBUG: User already signed in, signing out first...")
                    
                    // Save current user's data before switching
                    UserSpecificStorageManager.shared.saveCurrentUserData()
                    
                    // Sign out the current user
                    _ = try await Amplify.Auth.signOut()
                    print("🔍 DEBUG: Successfully signed out current user")
                    
                    // Clear guest user flags if they exist
                    UserDefaults.standard.removeObject(forKey: "current_guest_user_id")
                    UserDefaults.standard.removeObject(forKey: "is_guest_user")
                    UserDefaults.standard.removeObject(forKey: "authenticated_user_id")
                    print("🔍 DEBUG: Cleared user flags")
                }
                
                // Now sign in with email/password
                let signInResult = try await Amplify.Auth.signIn(
                    username: email,
                    password: password
                )
                
                if signInResult.isSignedIn {
                    // Set authenticated user flags
                    UserDefaults.standard.set(false, forKey: "is_guest_user")
                    print("🔍 DEBUG: Set is_guest_user to false for authenticated user")
                    
                    // Store the authenticated user ID
                    do {
                        let user = try await Amplify.Auth.getCurrentUser()
                        let userId = user.userId
                        UserDefaults.standard.set(userId, forKey: "authenticated_user_id")
                        print("🔍 DEBUG: Stored authenticated user ID: \(userId)")
                    } catch {
                        print("🔍 DEBUG: Failed to fetch user ID after sign-in: \(error)")
                    }
                    
                    // Load the new user's data
                    UserSpecificStorageManager.shared.loadNewUserData()
                    print("🔍 DEBUG: Loaded new user's data")
                }
                
                await MainActor.run {
                    isLoading = false
                    if signInResult.isSignedIn {
                        onSignInSuccess()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func signInAsGuest() async {
        print("🔍 DEBUG: Starting guest sign-in...")
        
        do {
            // Check if there's already a user signed in (guest or authenticated)
            let currentAuthState = try await Amplify.Auth.fetchAuthSession()
            
            if currentAuthState.isSignedIn {
                print("🔍 DEBUG: User already signed in, signing out first...")
                
                // Save current user's data before switching
                UserSpecificStorageManager.shared.saveCurrentUserData()
                
                // Sign out the current user
                _ = try await Amplify.Auth.signOut()
                print("🔍 DEBUG: Successfully signed out current user")
                
                // Clear authenticated user flags if they exist
                UserDefaults.standard.removeObject(forKey: "authenticated_user_id")
                UserDefaults.standard.removeObject(forKey: "is_guest_user")
            }
        } catch {
            print("🔍 DEBUG: Error checking/signing out current user: \(error)")
            // Continue with guest sign-in even if there's an error
        }
        
        // Check if we already have a guest ID stored for this device
        let guestIdKey = "persistent_guest_id"
        let existingGuestId = UserDefaults.standard.string(forKey: guestIdKey)
        
        let guestId: String
        if let existingId = existingGuestId {
            // Reuse existing guest ID
            guestId = existingId
            print("🔍 DEBUG: Reusing existing guest ID: \(guestId)")
        } else {
            // Create new guest ID and store it
            guestId = "guest_\(UUID().uuidString)"
            UserDefaults.standard.set(guestId, forKey: guestIdKey)
            print("🔍 DEBUG: Created new guest ID: \(guestId)")
        }
        
        // Store guest authentication info for API calls
        UserDefaults.standard.set(guestId, forKey: "current_guest_user_id")
        UserDefaults.standard.set(true, forKey: "is_guest_user")
        
        print("🔍 DEBUG: Guest authentication info stored in UserDefaults")
        
        // Load the guest user's data
        UserSpecificStorageManager.shared.loadNewUserData()
        print("🔍 DEBUG: Loaded guest user's data")
        
        await MainActor.run {
            print("🔍 DEBUG: Setting authStatus to .signedIn")
            onSignInSuccess()
        }
    }
}

// MARK: - Custom Sign Up View
struct CustomSignUpView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showConfirmation = false
    @State private var confirmationCode = ""
    
    let onSignUpSuccess: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if !showConfirmation {
                    // Sign Up Form
                    VStack(spacing: 20) {
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("", text: $email)
                                .modifier(AppTextFieldStyle(placeholder: "Enter your email", text: $email))
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            SecureField("", text: $password)
                                .modifier(AppTextFieldStyle(placeholder: "Enter your password", text: $password))
                        }
                        
                        // Confirm Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            SecureField("", text: $confirmPassword)
                                .modifier(AppTextFieldStyle(placeholder: "Confirm your password", text: $confirmPassword))
                        }
                        
                        // Sign Up button
                        Button(action: signUp) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Create Account")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color("LightGreen"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || password != confirmPassword)
                        .opacity((isLoading || email.isEmpty || password.isEmpty || confirmPassword.isEmpty || password != confirmPassword) ? 0.6 : 1.0)
                        
                        Spacer()
                    }
                } else {
                    // Confirmation Code Form
                    VStack(spacing: 20) {
                        Text("Verify Your Email")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        Text("We sent a verification code to \(email)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                        
                        // Confirmation Code field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Verification Code")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("", text: $confirmationCode)
                                .modifier(AppTextFieldStyle(placeholder: "Enter verification code", text: $confirmationCode))
                                .keyboardType(.numberPad)
                        }
                        
                        // Confirm button
                        Button(action: confirmSignUp) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Verify")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color("LightGreen"))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading || confirmationCode.isEmpty)
                        .opacity((isLoading || confirmationCode.isEmpty) ? 0.6 : 1.0)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 32)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("GradientBackground"),
                        Color.black
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func signUp() {
        isLoading = true
        
        Task {
            do {
                let signUpResult = try await Amplify.Auth.signUp(
                    username: email,
                    password: password
                )
                
                await MainActor.run {
                    isLoading = false
                    if signUpResult.isSignUpComplete {
                        onSignUpSuccess()
                    } else {
                        showConfirmation = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func confirmSignUp() {
        isLoading = true
        
        Task {
            do {
                let confirmResult = try await Amplify.Auth.confirmSignUp(
                    for: email,
                    confirmationCode: confirmationCode
                )
                
                await MainActor.run {
                    isLoading = false
                    if confirmResult.isSignUpComplete {
                        onSignUpSuccess()
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Custom Forgot Password View
struct CustomForgotPasswordView: View {
    @State private var email = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    let onResetSuccess: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Reset Password")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextField("", text: $email)
                        .modifier(AppTextFieldStyle(placeholder: "Enter your email", text: $email))
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                // Reset Password button
                Button(action: resetPassword) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Send Reset Link")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color("LightGreen"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(isLoading || email.isEmpty)
                .opacity((isLoading || email.isEmpty) ? 0.6 : 1.0)
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("GradientBackground"),
                        Color.black
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Reset Link Sent", isPresented: $showSuccess) {
            Button("OK") {
                dismiss()
                onResetSuccess()
            }
        } message: {
            Text("We've sent a password reset link to your email address.")
        }
    }
    
    private func resetPassword() {
        isLoading = true
        
        Task {
            do {
                try await Amplify.Auth.resetPassword(for: email)
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [
                Color("GradientBackground"),
                Color.black
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        
        CustomSignInView(onSignInSuccess: {})
    }
}
