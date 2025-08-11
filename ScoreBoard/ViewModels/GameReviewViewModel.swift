//
//  GameReviewViewModel.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation

class GameReviewViewModel: ObservableObject {
    @Published var gameDetails: GameDetails?

    func fetchGameDetails(gameID: String) {
        // Logic to fetch game details from the backend
    }
}

