import SwiftUI

// Custom tab icon for "Your Board" that represents the app logo
struct AppLogoIcon: View {
    let isSelected: Bool
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Outer circle background with thin border
            Circle()
                .stroke(isSelected ? Color.accentColor : Color.secondary, lineWidth: 1.5)
                .frame(width: size, height: size)
            
            // Logo image that fills the circle
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size - 3, height: size - 3) // Slightly smaller to fit within border
                .clipShape(Circle())
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