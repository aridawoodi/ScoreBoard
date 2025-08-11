//
//  Testview.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 8/8/25.
//

import SwiftUI

struct ScoreboardView: View {
    let players = ["player 1", "player 2", "player 3"]
    let totals = [55, 78, 110]
    let scores = [
        [11, 23, 55],
        [44, 55, 55]
    ]
    let currentPlayer = 2 // index for player 3 (0-based)
    
    var body: some View {
        VStack(spacing: 0) {
            // Title area
            VStack(spacing: 2) {
                Text("Falcon")
                    .font(.largeTitle)
                    .bold()
            }
            .padding(.top)
            
            Spacer().frame(height: 12) // Gap before table
            
            // Header row
            HStack(spacing: 0) {
//                cellView(text: "#", bold: true, bg: Color.blue.opacity(0.2), width: 40)
                
                ForEach(players.indices, id: \.self) { index in
                    VStack(spacing: 0) {
                        Text(players[index])
                            .font(.headline)
                            .padding(.top, 4)
                        
                        Text("\(totals[index])")
                            .font(.title3)
                            .bold()
                            .padding(6)
                            .frame(maxWidth: .infinity)
                            .background(columnColor(index).opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(index == currentPlayer ? Color.blue : Color.gray.opacity(0.4), lineWidth: index == currentPlayer ? 2 : 1)
                    )
                    .background(Color.blue.opacity(0.05))
                }
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            // Score rows
            ForEach(scores.indices, id: \.self) { row in
                HStack(spacing: 0) {
//                    cellView(text: "\(row + 1)", bg: Color.blue.opacity(0.2), width: 40)
                    
                    ForEach(scores[row].indices, id: \.self) { col in
                        cellView(
                            text: "\(scores[row][col])",
                            bg: columnColor(col).opacity(0.5)
                        )
                    }
                }
                Divider()
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helpers
    func cellView(text: String, bold: Bool = false, bg: Color, width: CGFloat? = nil) -> some View {
        Text(text)
            .font(bold ? .headline : .body)
            .bold(bold)
            .frame(minWidth: width, idealWidth: width, maxWidth: width ?? .infinity)
            .padding(.vertical, 8)
            .background(bg)
    }
    
    func columnColor(_ index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .purple
        default: return .green
        }
    }
}

struct ScoreboardView_Previews: PreviewProvider {
    static var previews: some View {
        ScoreboardView()
    }
}

