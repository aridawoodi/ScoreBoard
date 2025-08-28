import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var textOffset: CGFloat = 20
    
    var body: some View {
        ZStack {
            // Background gradient matching app theme
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("GradientBackground"), // Dark green from asset
                    Color.black // Very dark gray / almost black
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo Container using shared component
                AnimatedLogoView.splashScreen(size: 100)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                // App name with modern typography
                Text("ScoreBoard")
                    .font(.system(size: 42, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .tracking(1.5) // Letter spacing
                    .opacity(textOpacity)
                    .offset(y: textOffset)
                
                // Subtitle
                Text("Track • Score • Win")
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(0.5)
                    .opacity(textOpacity)
                    .offset(y: textOffset)
                    .padding(.top, 8)
                
                Spacer()
            }
        }
        .onAppear {
            // Animate logo appearance with exciting effects
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // Animate text appearance with delay
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                textOpacity = 1.0
                textOffset = 0
            }
        }
    }
}

#Preview {
    SplashScreenView()
} 
