////
////  test.swift
////  ScoreBoard
////
////  Created by Ari Dawoodi on 9/3/25.
////
//
//import SwiftUI
//
//// MARK: - Color Extension for Hex Support
//extension Color {
//    init(hex: String) {
//        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
//        var int: UInt64 = 0
//        Scanner(string: hex).scanHexInt64(&int)
//        let a, r, g, b: UInt64
//        switch hex.count {
//        case 3: // RGB (12-bit)
//            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
//        case 6: // RGB (24-bit)
//            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
//        case 8: // ARGB (32-bit)
//            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
//        default:
//            (a, r, g, b) = (1, 1, 1, 0)
//        }
//
//        self.init(
//            .sRGB,
//            red: Double(r) / 255,
//            green: Double(g) / 255,
//            blue:  Double(b) / 255,
//            opacity: Double(a) / 255
//        )
//    }
//}
//
//struct ExcelStyleTable: View {
//    @State private var animate = false
//    @State private var cellData: [[String]] = [
//        ["Round", "Player 1", "Player 2"],
//        ["1", "25", "18"],
//        ["2", "42", "35"],
//        ["3", "38", "41"],
//        ["4", "29", "33"],
//        ["5", "45", "39"]
//    ]
//
//    var body: some View {
//        ZStack {
//            // Table content (background)
//            VStack(spacing: 0) {
//                ForEach(0..<6, id: \.self) { row in
//                    HStack(spacing: 0) {
//                        ForEach(0..<3, id: \.self) { col in
//                            Text(cellData[row][col])
//                                .foregroundColor(.white)
//                                .font(.system(size: 14, weight: row == 0 ? .bold : .regular))
//                                .frame(maxWidth: .infinity, minHeight: 40)
//                                .background(
//                                    Rectangle()
//                                        .fill(row == 0 ? Color.gray.opacity(0.3) : Color.black.opacity(0.2))
//                                )
//                                .overlay(
//                                    Rectangle()
//                                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
//                                )
//                        }
//                    }
//                }
//            }
//            .background(Color.black)
//            .clipShape(RoundedRectangle(cornerRadius: 8))
//            
//            // Animated gradient border (on top)
//            RoundedRectangle(cornerRadius: 8)
//                .strokeBorder(
//                    LinearGradient(
//                        gradient: Gradient(colors: [
//                            Color(hex: "0D2B17"), .orange, Color(hex: "0D2B17"), .red, Color(hex: "0D2B17"), .blue, Color(hex: "0D2B17"), .green, Color(hex: "0D2B17")
//                        ]),
//                        startPoint: animate ? .topLeading : .bottomTrailing,
//                        endPoint: animate ? .bottomTrailing : .topLeading
//                    ),
//                    lineWidth: 3
//                )
//                .animation(
//                    Animation.linear(duration: 3)
//                        .repeatForever(autoreverses: false),
//                    value: animate
//                )
//                .allowsHitTesting(false) // Allow touches to pass through to the table
//        }
//        .padding()
//        .onAppear {
//            animate = true
//        }
//    }
//}
//
//struct testview: View {
//    var body: some View {
//        ZStack {
//            Color.black.ignoresSafeArea()
//            ExcelStyleTable()
//                .frame(width: 300, height: 250)
//                .padding()
//        }
//    }
//}
//
//#Preview {
//    testview()
//}
