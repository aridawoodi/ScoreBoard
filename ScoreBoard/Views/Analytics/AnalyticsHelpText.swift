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
    static let quickStatsInfo = "Stats are calculated from your completed games. Games count includes all games you've participated in. Win rate is based on games where you won according to the game's win condition (highest score or lowest score). Best score shows your highest single-game score."
    
    // MARK: - Win/Loss Information
    static let winLossInfo = "Win/Loss is calculated based on your final score in each game according to the game's win condition. A 'Win' means you achieved the winning condition (highest score for 'highest wins' games, or lowest score for 'lowest wins' games). A 'Loss' means another player met the winning condition. Win rate shows the percentage of games where you won."
    
    // MARK: - Performance Information
    static let performanceInfo = "Performance metrics are calculated from your game scores. Average Score is the mean of all your final scores. Best Score shows your highest single-game score. Games count shows how many games you've played in the selected timeframe."
    
    // MARK: - Recent Games Information
    static let recentGamesInfo = "Recent Games shows your last 5 completed games. Win/Loss is determined by the game's win condition (highest score or lowest score wins). The date shows when the game was completed. Games are sorted by completion date."
    
    // MARK: - Achievements Information
    static let achievementsInfo = "Achievements are unlocked based on your gaming milestones. First Win: Win your first game. Streak Master: Win 5 consecutive games. High Scorer: Achieve a score of 1000+ points in any game. Regular Player: Participate in 50 total games. Highest Score Master: Win 10 games with highest-score win condition. Lowest Score Master: Win 10 games with lowest-score win condition. Versatile Player: Win both highest and lowest score games."
    
    // MARK: - Individual Stat Information
    static let gamesPlayedInfo = "Total games you've participated in"
    static let winRateInfo = "Percentage of games where you won according to the game's win condition"
    static let bestScoreInfo = "Your highest single-game score achieved"
    static let avgScoreInfo = "Average of all your final scores across games"
} 