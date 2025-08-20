//
//  FloatingActionButton.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI

struct FloatingActionButton: View {
    @Binding var isExpanded: Bool
    let onBackToBoards: () -> Void
    let onViewAllGames: (() -> Void)?
    
    // Animation states
    @State private var animationOffset: CGFloat = 0
    @State private var buttonScale: CGFloat = 1.0
    
    // Button positions for expansion
    private let buttonRadius: CGFloat = 120
    private let buttonSize: CGFloat = 50
    private let mainButtonSize: CGFloat = 60
    
    var body: some View {
        ZStack {
            // Background overlay when expanded
            if isExpanded {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isExpanded = false
                        }
                    }
            }
            
            // Floating action buttons
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    ZStack {
                        // Expanded buttons
                        if isExpanded {
                            // Back to Boards button
                            FloatingButton(
                                icon: "list.bullet",
                                title: "Back to Boards",
                                color: Color("LightGreen"),
                                size: buttonSize
                            ) {
                                onBackToBoards()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isExpanded = false
                                }
                            }
                            .offset(x: -buttonRadius * cos(.pi/4), y: -buttonRadius * sin(.pi/4))
                            .scaleEffect(isExpanded ? 1 : 0)
                            .opacity(isExpanded ? 1 : 0)
                            
                            // View All Games button (placeholder)
                            FloatingButton(
                                icon: "gamecontroller",
                                title: "View All Games",
                                color: Color.blue,
                                size: buttonSize
                            ) {
                                onViewAllGames?()
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isExpanded = false
                                }
                            }
                            .offset(x: -buttonRadius * cos(.pi/2), y: -buttonRadius * sin(.pi/2))
                            .scaleEffect(isExpanded ? 1 : 0)
                            .opacity(isExpanded ? 1 : 0)
                            
                            // Game Settings button (placeholder)
                            FloatingButton(
                                icon: "gearshape",
                                title: "Game Settings",
                                color: Color.orange,
                                size: buttonSize
                            ) {
                                // Placeholder action
                                print("Game Settings tapped")
                            }
                            .offset(x: -buttonRadius * cos(3 * .pi/4), y: -buttonRadius * sin(3 * .pi/4))
                            .scaleEffect(isExpanded ? 1 : 0)
                            .opacity(isExpanded ? 1 : 0)
                            
                            // Share Game button (placeholder)
                            FloatingButton(
                                icon: "square.and.arrow.up",
                                title: "Share Game",
                                color: Color.purple,
                                size: buttonSize
                            ) {
                                // Placeholder action
                                print("Share Game tapped")
                            }
                            .offset(x: -buttonRadius * cos(.pi), y: -buttonRadius * sin(.pi))
                            .scaleEffect(isExpanded ? 1 : 0)
                            .opacity(isExpanded ? 1 : 0)
                        }
                        
                        // Main floating button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "xmark" : "ellipsis.circle.fill")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: mainButtonSize, height: mainButtonSize)
                                .background(Color("LightGreen"))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .scaleEffect(buttonScale)
                        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                            withAnimation(.easeInOut(duration: 0.1)) {
                                buttonScale = pressing ? 0.95 : 1.0
                            }
                        }, perform: {})
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100) // Position above tab bar
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
    }
}

// Individual floating button component
struct FloatingButton: View {
    let icon: String
    let title: String
    let color: Color
    let size: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: size, height: size)
                    .background(color)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 80)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        GradientBackgroundView()
        
        VStack {
            Text("Scoreboard View")
                .font(.title)
                .foregroundColor(.white)
            
            Spacer()
        }
        
        FloatingActionButton(
            isExpanded: .constant(false),
            onBackToBoards: {
                print("Back to Boards tapped")
            },
            onViewAllGames: {
                print("View All Games tapped")
            }
        )
    }
}
