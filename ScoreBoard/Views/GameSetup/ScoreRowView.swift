//
//  ScoreRowView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

//import SwiftUI
//
//struct ScoreRowView: View {
//    let playerID: String
//    let playerName: String
//    let score: Int
//    let onScoreChanged: (Int) -> Void
//    let isIPad: Bool
//    
//    @State private var showingScoreInput = false
//    @State private var tempScore: String = ""
//    
//    // Responsive sizing
//    private var avatarSize: CGFloat {
//        isIPad ? 32 : 24
//    }
//    
//    private var playerNameFont: Font {
//        isIPad ? .body : .caption
//    }
//    
//    private var playerTypeFont: Font {
//        isIPad ? .caption : .caption2
//    }
//    
//    private var scoreFont: Font {
//        isIPad ? .body.bold() : .caption.bold()
//    }
//    
//    private var scoreWidth: CGFloat {
//        isIPad ? 120 : 80
//    }
//    
//    private var rowPadding: CGFloat {
//        isIPad ? 16 : 12
//    }
//    
//    var body: some View {
//        HStack(spacing: isIPad ? 16 : 12) {
//            // Player Info
//            VStack(alignment: .leading, spacing: isIPad ? 6 : 4) {
//                HStack(spacing: isIPad ? 8 : 4) {
//                    // Player Avatar
//                    ZStack {
//                        Circle()
//                            .fill(Color.accentColor.opacity(0.15))
//                            .frame(width: avatarSize, height: avatarSize)
//                        Text(playerName.prefix(1).uppercased())
//                            .font(isIPad ? .title3.bold() : .caption.bold())
//                            .foregroundColor(.accentColor)
//                    }
//                    
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text(playerName)
//                            .font(playerNameFont)
//                            .fontWeight(.medium)
//                            .lineLimit(1)
//                        
//                        // Player Type Indicator
//                        HStack(spacing: 2) {
//                            Image(systemName: playerID.contains(":") ? "person.circle" : "person.circle.fill")
//                                .font(playerTypeFont)
//                                .foregroundColor(playerID.contains(":") ? .orange : .green)
//                            Text(playerID.contains(":") ? "Anonymous" : "Registered")
//                                .font(playerTypeFont)
//                                .foregroundColor(playerID.contains(":") ? .orange : .green)
//                        }
//                    }
//                }
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//            
//            // Score Display
//            Button(action: {
//                tempScore = score == 0 ? "" : String(score)
//                showingScoreInput = true
//            }) {
//                Text("\(score)")
//                    .font(scoreFont)
//                    .frame(width: scoreWidth, height: isIPad ? 48 : 32)
//                    .background(score == 0 ? Color(.systemGray5) : Color.blue.opacity(0.1))
//                    .foregroundColor(score == 0 ? .secondary : .primary)
//                    .clipShape(RoundedRectangle(cornerRadius: isIPad ? 12 : 6))
//                    .overlay(
//                        RoundedRectangle(cornerRadius: isIPad ? 12 : 6)
//                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
//                    )
//            }
//            .buttonStyle(.plain)
//        }
//        .padding(.horizontal, rowPadding)
//        .padding(.vertical, isIPad ? 12 : 8)
//        .background(Color(.systemBackground))
//        .cornerRadius(isIPad ? 12 : 8)
//            .sheet(isPresented: $showingScoreInput) {
//                ScoreInputView(
//                    playerName: playerName,
//                    currentScore: score,
//                    onScoreChanged: { newScore in
//                        onScoreChanged(newScore)
//                    },
//                    isIPad: isIPad
//                )
//            }
//    }
//}
//
//// MARK: - ScoreInputView
//struct ScoreInputView: View {
//    let playerName: String
//    let currentScore: Int
//    let onScoreChanged: (Int) -> Void
//    let isIPad: Bool
//    
//    @State private var scoreText: String = ""
//    @Environment(\.dismiss) private var dismiss
//    
//    private var titleFont: Font {
//        isIPad ? .title2 : .headline
//    }
//    
//    private var bodyFont: Font {
//        isIPad ? .title3 : .body
//    }
//    
//    var body: some View {
//        NavigationView {
//            VStack(spacing: isIPad ? 32 : 24) {
//                VStack(spacing: isIPad ? 16 : 12) {
//                    Text("Enter Score")
//                        .font(titleFont)
//                        .fontWeight(.semibold)
//                    
//                    Text("\(playerName)")
//                        .font(bodyFont)
//                        .foregroundColor(.secondary)
//                }
//                
//                VStack(spacing: isIPad ? 16 : 12) {
//                    Text("Score")
//                        .font(isIPad ? .title3 : .subheadline)
//                        .foregroundColor(.secondary)
//                    
//                    TextField("Enter score", text: $scoreText)
//                        .textFieldStyle(RoundedBorderTextFieldStyle())
//                        .font(bodyFont)
//                        .keyboardType(.numberPad)
//                        .frame(maxWidth: isIPad ? 300 : 200)
//                    
//                    // Using iPhone's built-in keyboard; no custom keypad
//                }
//                
//                HStack(spacing: isIPad ? 20 : 16) {
//                    Button("Cancel") {
//                        dismiss()
//                    }
//                    .buttonStyle(.bordered)
//                    .frame(maxWidth: .infinity)
//                    
//                    Button("Save") {
//                        if let score = Int(scoreText) {
//                            onScoreChanged(score)
//                        }
//                        dismiss()
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .frame(maxWidth: .infinity)
//                    .disabled(scoreText.isEmpty)
//                }
//                .padding(.horizontal, isIPad ? 40 : 20)
//                
//                Spacer()
//            }
//            .padding(isIPad ? 40 : 24)
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Done") {
//                        dismiss()
//                    }
//                }
//            }
//        }
//        .onAppear {
//            scoreText = currentScore == 0 ? "" : String(currentScore)
//        }
//    }
//}
//
//// Custom keypad removed in favor of iPhone's built-in keyboard
//
//// MARK: - Helper Structs
//struct CellIdentifier: Identifiable {
//    let id = UUID()
//    let playerID: String
//    let round: Int
//}
