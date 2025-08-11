//
//  GameReviewView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI

let sampleGameDetails = GameDetails(rounds: [
    Round(id: 1, number: 1, scores: [
        PlayerScore(id: "1", playerName: "Alice", value: 10),
        PlayerScore(id: "2", playerName: "Bob", value: 8)
    ]),
    Round(id: 2, number: 2, scores: [
        PlayerScore(id: "1", playerName: "Alice", value: 7),
        PlayerScore(id: "2", playerName: "Bob", value: 9)
    ])
])

struct GameReviewView: View {
    @State var gameDetails: GameDetails

    var body: some View {
        VStack {
            Text("Game Review")
                .font(.headline)
            
            ForEach(gameDetails.rounds) { round in
                VStack(alignment: .leading) {
                    Text("Round \(round.number)")
                        .font(.subheadline)
                        .padding(.top, 5)
                    
                    ForEach(round.scores) { score in
                        HStack {
                            Text("\(score.playerName):")
                                .fontWeight(.bold)
                            Text("\(score.value)")
                        }
                    }
                }
            }
        }
        .padding()
    }
}

#Preview {
    GameReviewView(gameDetails: sampleGameDetails)
}
