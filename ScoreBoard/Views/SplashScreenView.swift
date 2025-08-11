import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var textOpacity: Double = 0.0
    @State private var textOffset: CGFloat = 20
    
    var body: some View {
        ZStack {
            // Clean white background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo Container
                ZStack {
                    // Background circle with subtle gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.6, blue: 1.0),
                                    Color(red: 0.4, green: 0.2, blue: 0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    // ScoreBoard Logo
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // App name with modern typography
                Text("ScoreBoard")
                    .font(.system(size: 42, weight: .bold, design: .default))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .tracking(1.5) // Letter spacing
                    .opacity(textOpacity)
                    .offset(y: textOffset)
                
                // Subtitle
                Text("Track • Score • Win")
                    .font(.system(size: 16, weight: .medium, design: .default))
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                    .tracking(0.5)
                    .opacity(textOpacity)
                    .offset(y: textOffset)
                    .padding(.top, 8)
                
                Spacer()
            }
        }
        .onAppear {
            // Animate logo appearance
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
