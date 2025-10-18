//
//  ConvertToAccountView.swift
//  ScoreBoard
//
//  View for converting guest user to authenticated account
//

import SwiftUI
import Amplify

struct ConvertToAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var migrationService = GuestMigrationService.shared
    @StateObject private var userService = UserService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var confirmationCode = ""
    
    @State private var showConfirmation = false
    @State private var guestUserId: String?
    
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    @State private var migrationProgress: MigrationProgress?
    
    let onSuccess: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if !showConfirmation {
                        // STEP 1: Email and Password Entry
                        emailPasswordForm
                    } else {
                        // STEP 2: Email Confirmation
                        confirmationForm
                    }
                    
                    // Migration Progress
                    if let progress = migrationProgress {
                        progressView(progress)
                    }
                }
                .padding()
            }
            .navigationTitle(showConfirmation ? "Verify Email" : "Convert to Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .disabled(isProcessing)
                }
            }
            .gradientBackground()
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("OK") {
                    onSuccess()
                    dismiss()
                }
            } message: {
                Text("Your guest account has been successfully converted to an authenticated account! All your games and data have been preserved.")
            }
        }
    }
    
    // MARK: - Email & Password Form
    
    private var emailPasswordForm: some View {
        VStack(spacing: 24) {
            // Info Card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    Text("Why Convert?")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Text("Converting to an authenticated account allows you to:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                
                VStack(alignment: .leading, spacing: 8) {
                    benefitRow(icon: "checkmark.circle.fill", text: "Sign in from any device")
                    benefitRow(icon: "checkmark.circle.fill", text: "Recover your account if you delete the app")
                    benefitRow(icon: "checkmark.circle.fill", text: "Keep all your games and progress")
                    benefitRow(icon: "checkmark.circle.fill", text: "Secure your data with a password")
                }
                .padding(.leading, 8)
            }
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
            
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("", text: $email)
                    .modifier(AppTextFieldStyle(placeholder: "Enter your email", text: $email))
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.headline)
                    .foregroundColor(.white)
                
                SecureField("", text: $password)
                    .modifier(AppTextFieldStyle(placeholder: "Create a password", text: $password))
            }
            
            // Confirm Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Confirm Password")
                    .font(.headline)
                    .foregroundColor(.white)
                
                SecureField("", text: $confirmPassword)
                    .modifier(AppTextFieldStyle(placeholder: "Re-enter password", text: $confirmPassword))
                
                // Password match indicator
                if !confirmPassword.isEmpty {
                    HStack {
                        Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(password == confirmPassword ? .green : .red)
                        Text(password == confirmPassword ? "Passwords match" : "Passwords don't match")
                            .font(.caption)
                            .foregroundColor(password == confirmPassword ? .green : .red)
                    }
                }
            }
            
            // Password Requirements
            VStack(alignment: .leading, spacing: 8) {
                Text("Password Requirements:")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                VStack(alignment: .leading, spacing: 4) {
                    requirementRow(text: "At least 8 characters", met: password.count >= 8)
                    requirementRow(text: "Contains a number", met: password.contains(where: { $0.isNumber }))
                    requirementRow(text: "Contains a letter", met: password.contains(where: { $0.isLetter }))
                }
                .padding(.leading, 8)
            }
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            
            // Convert Button
            Button(action: {
                startConversion()
            }) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Convert to Account")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canProceed ? Color("LightGreen") : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(!canProceed || isProcessing)
        }
    }
    
    // MARK: - Confirmation Form
    
    private var confirmationForm: some View {
        VStack(spacing: 24) {
            // Info
            VStack(spacing: 12) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Check Your Email")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("We sent a verification code to:")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(email)
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            .padding()
            
            // Confirmation Code Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Verification Code")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("", text: $confirmationCode)
                    .modifier(AppTextFieldStyle(placeholder: "Enter 6-digit code", text: $confirmationCode))
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.characters)
            }
            
            // Verify Button
            Button(action: {
                completeConversion()
            }) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Verify & Complete Migration")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(confirmationCode.count == 6 ? Color("LightGreen") : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(confirmationCode.count != 6 || isProcessing)
            
            // Resend Code
            Button(action: {
                // TODO: Implement resend code
            }) {
                Text("Resend Code")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .disabled(isProcessing)
        }
    }
    
    // MARK: - Progress View
    
    private func progressView(_ progress: MigrationProgress) -> some View {
        VStack(spacing: 16) {
            Text(progress.currentStep)
                .font(.headline)
                .foregroundColor(.white)
            
            ProgressView(value: progress.percentage)
                .progressViewStyle(LinearProgressViewStyle(tint: Color("LightGreen")))
                .frame(height: 8)
            
            Text("\(progress.completedSteps) of \(progress.totalSteps) steps")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Views
    
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.caption)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
        }
    }
    
    private func requirementRow(text: String, met: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .green : .white.opacity(0.3))
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundColor(met ? .green : .white.opacity(0.7))
        }
    }
    
    // MARK: - Validation
    
    private var canProceed: Bool {
        return !email.isEmpty &&
               email.contains("@") &&
               password.count >= 8 &&
               password == confirmPassword &&
               password.contains(where: { $0.isNumber }) &&
               password.contains(where: { $0.isLetter })
    }
    
    // MARK: - Actions
    
    private func startConversion() {
        isProcessing = true
        
        Task {
            do {
                // Start migration and get guest user ID
                let guestId = try await migrationService.migrateGuestToAuthenticatedAccount(
                    email: email,
                    password: password,
                    onProgress: { progress in
                        migrationProgress = progress
                    }
                )
                
                await MainActor.run {
                    guestUserId = guestId
                    isProcessing = false
                    showConfirmation = true
                }
                
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func completeConversion() {
        guard let guestId = guestUserId else {
            errorMessage = "Guest user ID not found"
            showError = true
            return
        }
        
        isProcessing = true
        
        Task {
            do {
                // Complete migration with confirmation code
                let newAuthUserId = try await migrationService.completeMigration(
                    email: email,
                    password: password,
                    confirmationCode: confirmationCode,
                    guestUserId: guestId,
                    onProgress: { progress in
                        migrationProgress = progress
                    }
                )
                
                print("🔍 DEBUG: ConvertToAccountView - Migration completed! New ID: \(newAuthUserId)")
                
                // Reload user profile
                await userService.ensureUserProfile()
                
                await MainActor.run {
                    isProcessing = false
                    showSuccess = true
                }
                
            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Preview

struct ConvertToAccountView_Previews: PreviewProvider {
    static var previews: some View {
        ConvertToAccountView(onSuccess: {
            print("Migration successful!")
        })
    }
}

