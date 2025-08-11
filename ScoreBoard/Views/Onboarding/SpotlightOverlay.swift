//
//  SpotlightOverlay.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import SwiftUI

// MARK: - Spotlight Mask Shape
private struct SpotlightMaskShape: Shape {
    let holeRect: CGRect
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Full-screen rect
        path.addRect(rect)
        // Hole rect (rounded)
        let holePath = Path(roundedRect: holeRect, cornerRadius: cornerRadius)
        path.addPath(holePath)
        return path
    }
}

// MARK: - Spotlight Overlay
struct SpotlightOverlay: View {
    @Binding var isVisible: Bool
    let targetRectGlobal: CGRect
    let message: String
    var cornerRadius: CGFloat = 10
    var dimOpacity: Double = 0.0
    var onDismiss: (() -> Void)? = nil
    
    @State private var pulse: Bool = false
    
    private func localizedRect(in proxy: GeometryProxy) -> CGRect {
        // Convert from global to this GeometryProxy's local coordinate space
        let origin = proxy.frame(in: .global).origin
        return CGRect(
            x: targetRectGlobal.origin.x - origin.x,
            y: targetRectGlobal.origin.y - origin.y,
            width: targetRectGlobal.size.width,
            height: targetRectGlobal.size.height
        )
    }
    
    var body: some View {
        if isVisible {
            GeometryReader { proxy in
                let localRect = localizedRect(in: proxy)
                ZStack(alignment: .topLeading) {
                    // Optional dimmed background that does NOT block interactions
                    if dimOpacity > 0 {
                        Color.black.opacity(dimOpacity)
                            .ignoresSafeArea()
                            .allowsHitTesting(false)
                    }
                    
                    // Highlight ring around the target
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.accentColor, lineWidth: 3)
                        .shadow(color: .accentColor.opacity(0.6), radius: 8)
                        .frame(width: localRect.width, height: localRect.height)
                        .position(x: localRect.midX, y: localRect.midY)
                        .scaleEffect(pulse ? 1.06 : 0.98, anchor: .center)
                        .opacity(pulse ? 0.85 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                            value: pulse
                        )
                        .allowsHitTesting(false)
                    
                    // Hint bubble (auto-placed below the hole if possible, otherwise above)
                    let padding: CGFloat = 12
                    let bubbleWidth = min(proxy.size.width - 32, 320)
                    let belowY = localRect.maxY + 12
                    let aboveY = max(localRect.minY - 12, 12)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tip")
                            .font(.subheadline.bold())
                        Text(message)
                            .font(.body)
                        
                        HStack(spacing: 10) {
                            Button("Got it") {
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(14)
                    .frame(width: bubbleWidth, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .shadow(radius: 8)
                    .position(
                        x: min(max(localRect.midX, bubbleWidth / 2 + padding), proxy.size.width - bubbleWidth / 2 - padding),
                        y: (belowY + 100 < proxy.size.height) ? (belowY + 60) : (aboveY - 60)
                    )
                    .accessibilityAddTraits(.isModal)
                }
                .onAppear {
                    pulse = true
                }
            }
            .transition(.opacity)
            .animation(.easeInOut(duration: OnboardingConstants.Animation.animationDuration), value: isVisible)
        }
    }
    
    private func dismiss() {
        withAnimation(.easeInOut(duration: OnboardingConstants.Animation.animationDuration)) {
            isVisible = false
        }
        onDismiss?()
    }
}

// MARK: - Preview
#Preview {
    StatefulPreviewWrapper(true) { isVisible in
        ZStack {
            Color.white
            SpotlightOverlay(
                isVisible: isVisible,
                targetRectGlobal: CGRect(x: 180, y: 120, width: 100, height: 44),
                message: "Tap Create in the top-right to save your game.",
                dimOpacity: 0.0
            )
        }
    }
}

// Helper to preview @Binding
struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content
    
    init(_ value: Value, @ViewBuilder content: @escaping (Binding<Value>) -> Content) {
        _value = State(initialValue: value)
        self.content = content
    }
    
    var body: some View { content($value) }
}
