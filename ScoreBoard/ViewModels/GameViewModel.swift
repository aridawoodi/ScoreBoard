//
//  GameViewModel.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation

class GameViewModel: ObservableObject {
    @Published var currentGame: Game?
    
    func createGame(hostUserID: String, playerIDs: [String], rounds: Int) {
        // Logic to create a new game and save it to the backend
    }
}
