//
//  OnboardingTooltip.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI

// MARK: - Onboarding Tooltip Component
struct OnboardingTooltip: View {
    let title: String
    let message: String
    let actionText: String
    let dismissText: String
    let onAction: () -> Void
    let onDismiss: () -> Void
    
    @State private var showTooltip = false
    
    var body: some View {
        ZStack {
            // Semi-transparent background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissTooltip()
                }
            
            // Tooltip content
            VStack(spacing: 20) {
                // Icon
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                    .padding(.top, 20)
                
                // Title
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // Message
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Action buttons
                HStack(spacing: 16) {
                    // Dismiss button
                    Button(dismissText) {
                        dismissTooltip()
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                    
                    // Action button
                    Button(actionText) {
                        onAction()
                        dismissTooltip()
                    }
                    .font(.body.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .padding(.bottom, 20)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 40)
            .scaleEffect(showTooltip ? 1.0 : 0.8)
            .opacity(showTooltip ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showTooltip)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: OnboardingConstants.Animation.animationDuration)) {
                showTooltip = true
            }
        }
    }
    
    private func dismissTooltip() {
        withAnimation(.easeInOut(duration: OnboardingConstants.Animation.animationDuration)) {
            showTooltip = false
        }
        
        // Delay the actual dismissal to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + OnboardingConstants.Animation.animationDuration) {
            onDismiss()
        }
    }
}



// MARK: - Preview
#Preview {
    OnboardingTooltip(
        title: OnboardingConstants.Messages.welcomeTitle,
        message: OnboardingConstants.Messages.welcomeMessage,
        actionText: OnboardingConstants.Buttons.createGame,
        dismissText: OnboardingConstants.Buttons.maybeLater
    ) {
        print("Create game action tapped")
    } onDismiss: {
        print("Tooltip dismissed")
    }
}
