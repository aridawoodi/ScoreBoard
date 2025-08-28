import SwiftUI

// Custom tab icon for "Your Board" that represents the app logo
struct AppLogoIcon: View {
    let isSelected: Bool
    let size: CGFloat
    @State private var logoRotation: Double = 0.0
    @State private var borderPulse: CGFloat = 1.0
    @State private var logoGlow: CGFloat = 0.0
    
    var body: some View {
        ZStack {
            // Glow effect behind logo
            Circle()
                .fill(Color("LightGreen").opacity(0.3))
                .frame(width: size + 20, height: size + 20)
                .blur(radius: 15)
                .scaleEffect(logoGlow)
            
            // Outer circle background with thin border
            Circle()
                .stroke(isSelected ? Color("LightGreen") : Color.white.opacity(0.3), lineWidth: 1.5)
                .frame(width: size, height: size)
                .scaleEffect(borderPulse)
            
            // Logo image that fills the circle
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size - 3, height: size - 3) // Slightly smaller to fit within border
                .clipShape(Circle())
        }
        .rotationEffect(.degrees(logoRotation))
        .onAppear {
            // Add exciting animations when the logo appears
            withAnimation(.easeInOut(duration: 1.2).delay(0.2)) {
                logoRotation = 360
            }
            
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
                borderPulse = 1.1
            }
            
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                logoGlow = 1.0
            }
        }
    }
}

// Custom tab icon for "Your Board" that's larger than other tabs
struct YourBoardTabIcon: View {
    let isSelected: Bool
    let iconSize: CGFloat
    
    var body: some View {
        AppLogoIcon(isSelected: isSelected, size: iconSize * 1.3) // 30% larger than other icons
    }
}

// Preview
struct CustomTabIcons_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            YourBoardTabIcon(isSelected: true, iconSize: 24)
            YourBoardTabIcon(isSelected: false, iconSize: 24)
        }
        .padding()
    }
} 