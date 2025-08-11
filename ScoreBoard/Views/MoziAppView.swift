import SwiftUI

struct MoziAppView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Background color matching the light beige
            Color(red: 0.98, green: 0.96, blue: 0.94)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top section with status bar, greeting, and notification
                VStack(alignment: .leading, spacing: 8) {
                    // Status bar (simulated)
                    HStack {
                        Text("9:41")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "cellularbars")
                                .font(.system(size: 12))
                            Image(systemName: "wifi")
                                .font(.system(size: 12))
                            Image(systemName: "battery.100")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.black)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // Greeting and location
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Good afternoon")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.black)
                                
                                HStack(spacing: 4) {
                                    Text("from")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.black)
                                    
                                    Text("San Francisco")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Color(red: 1.0, green: 0.6, blue: 0.0)) // Orange accent
                                }
                            }
                            
                            Spacer()
                            
                            // Notification bell
                            Image(systemName: "bell")
                                .font(.system(size: 20))
                                .foregroundColor(.black)
                        }
                        
                        // Date tag
                        Text("Wed, Jan 8")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                Spacer()
                
                // Middle section with invite card
                VStack(alignment: .leading, spacing: 16) {
                                            Text("Invite your friends")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                    
                    // Invite card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                                                            Text("Know someone who lives here or has plans to visit? ")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            
                            HStack(spacing: 0) {
                                Text("Invite them")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.0, green: 0.5, blue: 1.0)) // Blue accent
                                
                                Text(" to Mozi.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        Spacer()
                        
                        // Share icon
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Bottom navigation bar
                VStack(spacing: 0) {
                    // Navigation bar
                    HStack(spacing: 0) {
                        ForEach(0..<5) { index in
                            VStack(spacing: 4) {
                                if index == 2 {
                                    // Center add button
                                    Circle()
                                        .fill(Color.primary)
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Image(systemName: "plus")
                                                .font(.system(size: 20, weight: .bold))
                                                .foregroundColor(Color(.systemBackground))
                                        )
                                        .offset(y: -10)
                                } else {
                                    // Navigation icons
                                    Image(systemName: iconName(for: index))
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedTab == index ? .primary : .secondary)
                                }
                                
                                Text(tabTitle(for: index))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(selectedTab == index ? .primary : .secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                selectedTab = index
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    
                    // Footer
                    HStack {
                        HStack(spacing: 4) {
                            Text("M")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                            Text("Mozi")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Text("curated by")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                            
                            Text("MM")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Mobbin")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.2, green: 0.2, blue: 0.2))
                }
            }
        }
    }
    
    private func iconName(for index: Int) -> String {
        switch index {
        case 0: return "house"
        case 1: return "paperplane"
        case 2: return "plus"
        case 3: return "person.2"
        case 4: return "person.circle"
        default: return "house"
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Home"
        case 1: return "My Plans"
        case 2: return ""
        case 3: return "My People"
        case 4: return "Profile"
        default: return ""
        }
    }
}

#Preview {
    MoziAppView()
} 