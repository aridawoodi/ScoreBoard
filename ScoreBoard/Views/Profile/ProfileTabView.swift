//
//  ProfileTabView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI

// MARK: - Profile Tab View (Now Side Navigation)
struct ProfileTabView: View {
    @Binding var showUserProfile: Bool
    @Binding var showProfileEdit: Bool
    let onSignOut: () async -> Void
    @StateObject private var userService = UserService.shared
    @State private var showDeleteAccountAlert = false
    @State private var showOnboardingResetToast = false
    // @State private var showSideMenu = false // Commented out for future use
    // @Binding var isSideNavigationOpen: Bool // Commented out for future use
    
    var body: some View {
        NavigationStack {
            // ZStack {
            //     // Main content with blur when side menu is open
            VStack(spacing: 0) {
                // Profile Header Section
                VStack(spacing: 16) {
                    // Profile Picture
                    if let profile = userService.currentUser {
                        // User has profile - show profile picture
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(String(profile.username.prefix(1)).uppercased())
                                    .font(.title.bold())
                                    .foregroundColor(.white)
                            )
                    } else {
                        // No profile - show placeholder
                        Circle()
                            .fill(Color(.systemGray4))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title)
                                    .foregroundColor(.white)
                            )
                    }
                    
                    // User Info
                    if let profile = userService.currentUser {
                        VStack(spacing: 4) {
                            Text(profile.username)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            if AmplifyService.isGuestUser(profile) {
                                Text("Guest Mode")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(8)
                            } else {
                                Text(profile.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        VStack(spacing: 4) {
                            Text("Profile Not Set Up")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("Create your profile to get started")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                // Settings Options List
                VStack(spacing: 0) {
                    // Edit Profile Option
                    if let currentUser = userService.currentUser {
                        // Show edit profile for both guest and authenticated users
                        SettingsRow(
                            icon: "pencil.circle.fill",
                            title: "Edit Profile",
                            iconColor: .blue
                        ) {
                            showProfileEdit = true
                        }
                        
                        Divider()
                            .padding(.leading, 60)
                        
                        // Show guest mode info for guest users
                        if AmplifyService.isGuestUser(currentUser) {
                            SettingsRow(
                                icon: "info.circle.fill",
                                title: "Guest Mode Active",
                                iconColor: .orange
                            ) {
                                // Show guest info
                            }
                            
                            Divider()
                                .padding(.leading, 60)
                        }
                    } else {
                        SettingsRow(
                            icon: "person.badge.plus",
                            title: "Create Profile",
                            iconColor: .blue
                        ) {
                            showUserProfile = true
                        }
                        
                        Divider()
                            .padding(.leading, 60)
                    }
                    
                    // Update Password Option (placeholder for future)
                    SettingsRow(
                        icon: "lock.circle.fill",
                        title: "Update Password",
                        iconColor: .orange
                    ) {
                        // Future functionality
                    }
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    // Delete Account Option
                    if let currentUser = userService.currentUser {
                        if !AmplifyService.isGuestUser(currentUser) {
                            // Only show delete account for regular users
                            SettingsRow(
                                icon: "trash.circle.fill",
                                title: "Delete My Account",
                                iconColor: .red
                            ) {
                                showDeleteAccountAlert = true
                            }
                            
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                    
                    // Reset Onboarding Option (for testing)
                    SettingsRow(
                        icon: "arrow.clockwise.circle.fill",
                        title: "Reset Onboarding",
                        iconColor: .orange
                    ) {
                        OnboardingManager().resetOnboarding()
                        showOnboardingResetToast = true
                    }
                    
                    Divider()
                        .padding(.leading, 60)
                    
                    // Sign Out Option
                    SettingsRow(
                        icon: "rectangle.portrait.and.arrow.right",
                        title: "Sign Out",
                        iconColor: .red
                    ) {
                        Task {
                            await onSignOut()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            // .opacity(showSideMenu ? 0 : 1) // Hide main content when side menu is open
            // .animation(.easeInOut(duration: 0.3), value: showSideMenu)
            
            // Side Navigation Menu - Commented out for future use
            // if showSideMenu {
            //     SideNavigationMenu(
            //         showSideMenu: $showSideMenu,
            //         showUserProfile: $showUserProfile,
            //         showProfileEdit: $showProfileEdit,
            //         showDeleteAccountAlert: $showDeleteAccountAlert,
            //         onSignOut: onSignOut,
            //         userService: userService,
            //         isSideNavigationOpen: $isSideNavigationOpen
            //     )
            //     .transition(.move(edge: .leading))
            //     .zIndex(1)
            // }
            // }
            .navigationTitle("Account Settings")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            // .toolbar {
            //     ToolbarItem(placement: .navigationBarTrailing) {
            //         Button(action: {
            //             withAnimation(.easeInOut(duration: 0.3)) {
            //                 showSideMenu.toggle()
            //                 isSideNavigationOpen = showSideMenu // Update parent state
            //             }
            //         }) {
            //             Image(systemName: "line.3.horizontal")
            //                 .font(.title2)
            //                 .foregroundColor(.primary)
            //         }
            //     }
            // }
            .onAppear {
                // Ensure user profile is loaded
                Task {
                    await userService.ensureUserProfile()
                }
            }
            // .onChange(of: showSideMenu) { newValue in
            //     // Update parent state when side menu state changes
            //     isSideNavigationOpen = newValue
            // }
            .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        let success = await userService.deleteAccount()
                        if success {
                            // Account deleted successfully, sign out
                            await onSignOut()
                        }
                    }
                }
            } message: {
                Text("This action will permanently delete your account and all associated data including:\n\n• Your profile information\n• All games you've created\n• All scores you've recorded\n\nThis action cannot be undone. Are you sure you want to continue?")
            }
            .overlay {
                if showOnboardingResetToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Onboarding reset successfully!")
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            showOnboardingResetToast = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Side Navigation Menu
struct SideNavigationMenu: View {
    @Binding var showSideMenu: Bool
    @Binding var showUserProfile: Bool
    @Binding var showProfileEdit: Bool
    @Binding var showDeleteAccountAlert: Bool
    let onSignOut: () async -> Void
    let userService: UserService
    @Binding var isSideNavigationOpen: Bool
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Side Menu Content
                VStack(spacing: 0) {
                    // Profile Section at Top
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            // Profile Picture
                            if let profile = userService.currentUser {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(profile.username.prefix(1)).uppercased())
                                            .font(.title2.bold())
                                            .foregroundColor(.white)
                                    )
                            } else {
                                Circle()
                                    .fill(Color(.systemGray4))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                if let profile = userService.currentUser {
                                    Text(profile.username)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text(profile.email)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                } else {
                                    Text("Guest User")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("Create profile to get started")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                // Profile edit action
                                showProfileEdit = true
                                showSideMenu = false
                                isSideNavigationOpen = false
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    }
                    
                    // Menu Items
                    VStack(spacing: 0) {
                        // Status Section
                        SideMenuSection(title: "Status") {
                            SideMenuItem(
                                icon: "checkmark.circle.fill",
                                title: "Available",
                                iconColor: .green,
                                showBadge: false
                            ) {
                                // Status action
                            }
                            
                            SideMenuItem(
                                icon: "message.circle.fill",
                                title: "Set status message",
                                iconColor: .blue,
                                showBadge: false
                            ) {
                                // Set status action
                            }
                        }
                        
                        // Main Settings Section
                        SideMenuSection(title: "Settings") {
                            SideMenuItem(
                                icon: "bell.fill",
                                title: "Notifications",
                                subtitle: "On",
                                iconColor: .blue,
                                showBadge: false
                            ) {
                                // Notifications action
                            }
                            
                            SideMenuItem(
                                icon: "gearshape.fill",
                                title: "Settings",
                                iconColor: .gray,
                                showBadge: false
                            ) {
                                // Settings action
                            }
                            
                            SideMenuItem(
                                icon: "diamond.fill",
                                title: "Your current benefits",
                                iconColor: .yellow,
                                showBadge: false
                            ) {
                                // Benefits action
                            }
                            
                            SideMenuItem(
                                icon: "person.3.fill",
                                title: "Invite to ScoreBoard",
                                iconColor: .purple,
                                showBadge: false
                            ) {
                                // Invite action
                            }
                        }
                        
                        // Secondary Section
                        SideMenuSection(title: "Content") {
                            SideMenuItem(
                                icon: "bookmark.fill",
                                title: "Saved",
                                iconColor: .blue,
                                showBadge: false
                            ) {
                                // Saved action
                            }
                            
                            SideMenuItem(
                                icon: "doc.fill",
                                title: "Files",
                                iconColor: .gray,
                                showBadge: false
                            ) {
                                // Files action
                            }
                        }
                        
                        // Account Section
                        SideMenuSection(title: "Account") {
                            if userService.currentUser == nil {
                                SideMenuItem(
                                    icon: "person.badge.plus",
                                    title: "Create Profile",
                                    iconColor: .blue,
                                    showBadge: false
                                ) {
                                    showUserProfile = true
                                    showSideMenu = false
                                    isSideNavigationOpen = false
                                }
                            } else {
                                SideMenuItem(
                                    icon: "pencil.circle.fill",
                                    title: "Edit Profile",
                                    iconColor: .blue,
                                    showBadge: false
                                ) {
                                    showProfileEdit = true
                                    showSideMenu = false
                                    isSideNavigationOpen = false
                                }
                                
                                SideMenuItem(
                                    icon: "plus.circle.fill",
                                    title: "Add account",
                                    iconColor: .gray,
                                    showBadge: false
                                ) {
                                    // Add account action
                                }
                            }
                        }
                        
                        // Sign Out Section
                        SideMenuSection(title: "Actions") {
                            SideMenuItem(
                                icon: "rectangle.portrait.and.arrow.right",
                                title: "Sign Out",
                                iconColor: .red,
                                showBadge: false
                            ) {
                                Task {
                                    await onSignOut()
                                }
                            }
                            
                            if userService.currentUser != nil {
                                SideMenuItem(
                                    icon: "trash.circle.fill",
                                    title: "Delete Account",
                                    iconColor: .red,
                                    showBadge: false
                                ) {
                                    showDeleteAccountAlert = true
                                    showSideMenu = false
                                    isSideNavigationOpen = false
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Footer Branding
                    VStack(spacing: 8) {
                        Divider()
                            .background(Color.white.opacity(0.2))
                        
                        HStack {
                            // ScoreBoard Logo
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text("S")
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                    )
                                
                                Text("ScoreBoard")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            // Curated by section
                            HStack(spacing: 4) {
                                Text("curated by")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.black)
                                    .frame(width: 16, height: 16)
                                    .overlay(
                                        Text("M")
                                            .font(.caption2.bold())
                                            .foregroundColor(.white)
                                    )
                                
                                Text("Mobbin")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .frame(width: geometry.size.width * 0.75)
                .background(
                    LinearGradient(
                        colors: [Color(.systemGray6), Color(.systemGray5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Blurred background overlay
                Color.black.opacity(0.3)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSideMenu = false
                            isSideNavigationOpen = false
                        }
                    }
            }
        }
    }
}

// MARK: - Side Menu Section
struct SideMenuSection: View {
    let title: String
    let content: () -> AnyView
    
    init(title: String, @ViewBuilder content: @escaping () -> some View) {
        self.title = title
        self.content = { AnyView(content()) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !title.isEmpty {
                HStack {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 8)
            }
            
            content()
        }
    }
}

// MARK: - Side Menu Item
struct SideMenuItem: View {
    let icon: String
    let title: String
    var subtitle: String?
    let iconColor: Color
    let showBadge: Bool
    let action: () -> Void
    
    init(icon: String, title: String, subtitle: String? = nil, iconColor: Color, showBadge: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.showBadge = showBadge
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 20, height: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                if showBadge {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Row Component
struct SettingsRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
} 