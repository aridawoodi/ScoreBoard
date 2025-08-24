//
//  BalloonView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/5/24.
//

import SwiftUI

// MARK: - Balloon View
struct BalloonView: View {
    let color: Color
    @State private var isFloating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Balloon body
            Circle()
                .fill(color)
                .frame(width: 40, height: 50)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            
            // Balloon string
            Rectangle()
                .fill(Color.gray)
                .frame(width: 2, height: 30)
        }
        .offset(y: isFloating ? -10 : 0)
        .animation(
            .easeInOut(duration: 2)
            .repeatForever(autoreverses: true),
            value: isFloating
        )
        .onAppear {
            isFloating = true
        }
    }
}

#Preview {
    BalloonView(color: .red)
}

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    var body: some View {
        ZStack {
            ForEach(confettiPieces, id: \.id) { piece in
                ConfettiPieceView(piece: piece)
            }
        }
        .onAppear {
            generateConfetti()
        }
    }
    
    private func generateConfetti() {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        confettiPieces = (0..<50).map { _ in
            ConfettiPiece(
                id: UUID(),
                color: colors.randomElement() ?? .blue,
                position: CGPoint(
                    x: CGFloat.random(in: 0...screenWidth),
                    y: CGFloat.random(in: 0...screenHeight)
                ),
                rotation: Double.random(in: 0...360),
                scale: Double.random(in: 0.5...1.5)
            )
        }
    }
}

struct ConfettiPiece {
    let id: UUID
    let color: Color
    let position: CGPoint
    let rotation: Double
    let scale: Double
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: 8, height: 8)
            .position(piece.position)
            .rotationEffect(.degrees(piece.rotation))
            .scaleEffect(piece.scale)
            .opacity(isAnimating ? 0 : 1)
            .animation(
                .easeOut(duration: 3)
                .delay(Double.random(in: 0...2)),
                value: isAnimating
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...1)) {
                    isAnimating = true
                }
            }
    }
}
