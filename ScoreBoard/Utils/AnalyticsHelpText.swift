//
//  AnalyticsHelpText.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation

// MARK: - Shared Analytics Help Text
struct AnalyticsHelpText {
    
    // MARK: - Player Information
    static let playerInfo = "Player level is calculated based on total games played and win rate. Progress bar shows advancement toward the next level. Streak shows consecutive days with at least one game played."
    
    // MARK: - Quick Stats Information
    static let quickStatsInfo = "Stats are calculated from your completed games. Games count includes all games you've participated in. Win rate is based on games where you had the highest score. Best score shows your highest single-game score."
    
    // MARK: - Win/Loss Information
    static let winLossInfo = "Win/Loss is calculated based on your final score in each game. A 'Win' means you had the highest score in that game. A 'Loss' means another player had a higher score. Win rate shows the percentage of games where you achieved the highest score."
    
    // MARK: - Performance Information
    static let performanceInfo = "Performance metrics are calculated from your game scores. Average Score is the mean of all your final scores. Best Score shows your highest single-game score. Games count shows how many games you've played in the selected timeframe."
    
    // MARK: - Recent Games Information
    static let recentGamesInfo = "Recent Games shows your last 5 completed games. Win/Loss is determined by comparing your final score to other players' scores. The date shows when the game was completed. Games are sorted by completion date."
    
    // MARK: - Achievements Information
    static let achievementsInfo = "Achievements are unlocked based on your gaming milestones. First Win: Win your first game. Streak Master: Win 5 consecutive games. High Scorer: Achieve a score of 1000+ points in any game. Regular Player: Participate in 50 total games."
    
    // MARK: - Individual Stat Information
    static let gamesPlayedInfo = "Total games you've participated in"
    static let winRateInfo = "Percentage of games where you had the highest score"
    static let bestScoreInfo = "Your highest single-game score achieved"
    static let avgScoreInfo = "Average of all your final scores across games"
} 