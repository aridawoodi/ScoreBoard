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
    @ObservedObject private var dataManager = DataManager.shared
    
    var body: some View {
        Group {
            if dataManager.isLoadingGames || dataManager.isLoadingScores || dataManager.isLoadingUsers {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Loading analytics...")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.7))
                }
            } else if let analyticsData = dataManager.reactiveAnalyticsData as? [String: Any] {
                // Show real analytics data from reactive DataManager
                AnalyticsDataView(analyticsData: analyticsData)
            } else {
                // Show sample data when no real data is available
                SampleAnalyticsView()
            }
        }
        .gradientBackground()
        .onAppear {
            print("🔍 DEBUG: AnalyticsTabView onAppear - using reactive analytics data from DataManager")
            print("🔍 DEBUG: AnalyticsTabView - Current analytics data available: \(dataManager.reactiveAnalyticsData != nil)")
        }
    }
}

// MARK: - Analytics Data View
struct AnalyticsDataView: View {
    let analyticsData: [String: Any]
    
    var body: some View {
        Group {
            if let games = analyticsData["games"] as? [Game],
               let scores = analyticsData["scores"] as? [Score],
               let userId = analyticsData["userId"] as? String,
               let stats = PlayerStats.from(games: games, scores: scores, userId: userId) {
                PlayerAnalyticsView(playerStats: stats)
            } else {
                SampleAnalyticsView()
            }
        }
    }
} 