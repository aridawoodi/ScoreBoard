//
//  AnalyticsTabView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI

// MARK: - Analytics Tab View
struct AnalyticsTabView: View {
    @ObservedObject var navigationState: NavigationState
    @Binding var selectedTab: Int
    @StateObject private var analyticsService = AnalyticsService.shared
    @StateObject private var dataManager = DataManager.shared
    @State private var playerStats: PlayerStats?
    @State private var isLoading = false
    @State private var showSampleData = false
    
    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading analytics...")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                }
            } else if let stats = playerStats {
                // Show real analytics data
                PlayerAnalyticsView()
                    .onAppear {
                        // The PlayerAnalyticsView will handle its own data loading
                    }
            } else {
                // Show sample data with clear indication it's sample data
                SampleAnalyticsView()
            }
        }
        .gradientBackground()
        .onAppear {
            loadAnalyticsData()
        }
    }
    
    private func loadAnalyticsData() {
        isLoading = true
        
        Task {
            // Check if user has any games
            let hasGames = !navigationState.userGames.isEmpty
            
            if hasGames {
                // Load real analytics data
                playerStats = await analyticsService.loadUserAnalytics()
            } else {
                // Show sample data - no need to set playerStats
                showSampleData = true
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
} 