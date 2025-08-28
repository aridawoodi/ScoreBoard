//
//  FloatingTabBar.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI

// MARK: - FloatingTabBar
struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    var namespace: Namespace.ID
    @ObservedObject var navigationState: NavigationState

    @State private var isPulsing = false

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let tabs: [(icon: String, label: String)] = [
        ("person.2.fill", "Join Scoreboard"),
        ("chart.bar.fill", "Analytics"),
        ("list.bullet", "Your Board"),
        ("plus.square", "Create Scoreboard"),
        ("person.circle", "Profile")
    ]

    private var isIPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    private var iconSize: CGFloat { isIPad ? 28 : 24 }
    private var verticalPadding: CGFloat { isIPad ? 16 : 12 }
    private var horizontalPadding: CGFloat { isIPad ? 24 : 16 }
    private var bottomPadding: CGFloat { isIPad ? 12 : 8 }
    private var edgePadding: CGFloat { isIPad ? 16 : 8 }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { idx in
                    let tab = tabs[idx]
                    Button(action: {
                        print("🔍 DEBUG: Tab \(idx) tapped - \(tabs[idx].label)")
                        
                        // Special handling for "Your Board" tab (index 2)
                        if idx == 2 {
                            handleYourBoardTabTap()
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedTab = idx
                            }
                        }
                    }) {
                        if idx == 2 {
                            // Custom logo for "Your Board" tab - bigger and extends outside
                            AppLogoIcon(isSelected: selectedTab == idx, size: iconSize * 2.5)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, verticalPadding)
                                .offset(y: -12) // Move up more to extend outside the tab bar
                        } else {
                            // Standard system icons for other tabs
                            Image(systemName: tab.icon)
                                .font(.system(size: iconSize, weight: .semibold))
                                .foregroundColor(selectedTab == idx ? .white : .white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, verticalPadding)
                        }
                    }
                    .background(
                        ZStack {
                            if selectedTab == idx {
                                Capsule()
                                    .fill(Color.white.opacity(0.2))
                                    .matchedGeometryEffect(id: "tabbg", in: namespace)
                            }
                        }
                    )
                    .overlay(
                        Group {
                            // Temporarily disabled glow effect to test if it's causing issues
                            // if idx == 3 {
                            //     Circle()
                            //         .fill(
                            //             RadialGradient(
                            //                 gradient: Gradient(colors: [
                            //                     Color.accentColor.opacity(0.3),
                            //                     Color.accentColor.opacity(0.1),
                            //                     Color.clear
                            //                 ]),
                            //                 center: .center,
                            //                 startRadius: 15,
                            //                 endRadius: 35
                            //             )
                            //         )
                            //         .scaleEffect(isPulsing ? 1.4 : 1.2)
                            //         .blur(radius: 8)
                            //         .opacity(isPulsing ? 0.6 : 0.8)
                            //         .animation(
                            //             Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                            //             value: isPulsing
                            //         )
                            // }
                        }
                    )
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.3))
                    .shadow(color: Color.black.opacity(0.3), radius: 16, x: 0, y: 8)
            )
            .padding(.horizontal, edgePadding)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .frame(height: isIPad ? 80 : 60)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPulsing = true
            }
        }
    }
    
    // MARK: - Your Board Tab Navigation Logic
    private func handleYourBoardTabTap() {
        print("🔍 DEBUG: ===== YOUR BOARD TAB TAP HANDLER =====")
        print("🔍 DEBUG: Current selectedTab: \(selectedTab)")
        print("🔍 DEBUG: Current selectedGame: \(navigationState.selectedGame?.id ?? "nil")")
        print("🔍 DEBUG: Has games: \(navigationState.hasGames)")
        print("🔍 DEBUG: Latest game: \(navigationState.latestGame?.id ?? "nil")")
        print("🔍 DEBUG: shouldShowMainBoard: \(navigationState.shouldShowMainBoard)")
        
        // Always clear the selected game to go back to main board view
        // This provides the same functionality as "Back to Boards" button
        if navigationState.selectedGame != nil {
            print("🔍 DEBUG: Clearing selected game to return to main board")
            navigationState.selectedGame = nil
        }
        
        // Set a flag to prevent auto-selection of latest game
        navigationState.shouldShowMainBoard = true
        print("🔍 DEBUG: Set shouldShowMainBoard to true")
        
        // Switch to Your Board tab if not already there
        if selectedTab != 2 {
            print("🔍 DEBUG: Switching to Your Board tab from tab \(selectedTab)")
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedTab = 2
            }
        } else {
            print("🔍 DEBUG: Already on Your Board tab - just cleared selected game")
            // Force a refresh of the YourBoardTabView by triggering objectWillChange
            navigationState.objectWillChange.send()
        }
        
        print("🔍 DEBUG: ===== YOUR BOARD TAB TAP HANDLER END =====")
    }
} 