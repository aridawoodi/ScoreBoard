//
//  GradientBackgroundView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 8/15/25.
//

import SwiftUI

struct GradientBackgroundView: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color("GradientBackground"), // Dark green from asset
                Color.black // Very dark gray / almost black
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// Extension to make it easy to apply the gradient background to any view
extension View {
    func gradientBackground() -> some View {
        ZStack {
            GradientBackgroundView()
            self
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Sample Content")
            .foregroundColor(.white)
            .font(.title)
        
        Text("This view has the gradient background")
            .foregroundColor(.white.opacity(0.8))
            .font(.body)
    }
    .gradientBackground()
}
