//
//  AnimatedLogoView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/5/24.
//

import SwiftUI

// MARK: - Shared Animated Logo Component
struct AnimatedLogoView: View {
    let size: CGFloat
    let isInteractive: Bool
    let autoAnimate: Bool
    
    @State private var logoRotation: Double = 0.0
    @State private var borderPulse: CGFloat = 1.0
    @State private var logoGlow: CGFloat = 0.0
    @State private var isAnimating = false
    
    // MARK: - Initializers
    init(size: CGFloat = 100, isInteractive: Bool = false, autoAnimate: Bool = true) {
        self.size = size
        self.isInteractive = isInteractive
        self.autoAnimate = autoAnimate
    }
    
    var body: some View {
        ZStack {
            // Glow effect behind logo
            Circle()
                .fill(Color("LightGreen").opacity(0.3))
                .frame(width: size + 20, height: size + 20)
                .blur(radius: 15)
                .scaleEffect(logoGlow)
            
            // Background circle with border
            Circle()
                .fill(Color.clear)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(Color("LightGreen"), lineWidth: 3)
                        .scaleEffect(borderPulse)
                )
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            // Logo image
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size - 3, height: size - 3)
                .clipShape(Circle())
        }
        .rotationEffect(.degrees(logoRotation))
        .onTapGesture {
            if isInteractive {
                triggerAnimation()
            }
        }
        .onAppear {
            if autoAnimate {
                startAutoAnimation()
            } else {
                // Just show glow for non-auto-animating logos
                withAnimation(.easeOut(duration: 0.8)) {
                    logoGlow = 1.0
                }
            }
        }
    }
    
    // MARK: - Animation Methods
    private func startAutoAnimation() {
        // Initial glow effect
        withAnimation(.easeOut(duration: 0.8)) {
            logoGlow = 1.0
        }
        
        // Auto rotation for excitement
        withAnimation(.easeInOut(duration: 1.2).delay(0.2)) {
            logoRotation = 360
        }
        
        // Continuous pulsing border effect
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
            borderPulse = 1.1
        }
    }
    
    private func triggerAnimation() {
        guard !isAnimating else { return }
        isAnimating = true
        
        print("🔍 DEBUG: Logo tapped - triggering animation")
        
        // Reset rotation
        logoRotation = 0
        
        // Trigger spin animation
        withAnimation(.easeInOut(duration: 1.2)) {
            logoRotation = 360
        }
        
        // Trigger pulse animation
        withAnimation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true)) {
            borderPulse = 1.2
        }
        
        // Reset after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isAnimating = false
            withAnimation(.easeInOut(duration: 0.3)) {
                borderPulse = 1.0
            }
        }
    }
}

// MARK: - Convenience Initializers
extension AnimatedLogoView {
    /// Splash screen logo with auto-animation
    static func splashScreen(size: CGFloat = 100) -> AnimatedLogoView {
        AnimatedLogoView(size: size, isInteractive: false, autoAnimate: true)
    }
    
    /// Interactive main board logo
    static func interactive(size: CGFloat = 80) -> AnimatedLogoView {
        AnimatedLogoView(size: size, isInteractive: true, autoAnimate: false)
    }
    
    /// Static logo with just glow effect
    static func static(size: CGFloat = 24) -> AnimatedLogoView {
        AnimatedLogoView(size: size, isInteractive: false, autoAnimate: false)
    }
}

#Preview {
    VStack(spacing: 30) {
        AnimatedLogoView.splashScreen()
        AnimatedLogoView.interactive()
        AnimatedLogoView.static()
    }
    .padding()
    .background(Color.black)
}
