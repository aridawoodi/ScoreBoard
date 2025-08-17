//
//  JoinOptionsView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/5/24.
//

import Foundation
import SwiftUI

struct JoinOptionsView: View {
    let playerName: String
    @Binding var joinMode: JoinMode
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.2.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Join Game")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("How would you like to join this game?")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Join Options
                VStack(spacing: 16) {
                    // Player Option
                    Button(action: {
                        joinMode = .player
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.green)
                                    Text("Join as Player")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                Text("Play and score in the game")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                            if joinMode == .player {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                            }
                        }
                        .padding()
                        .background(joinMode == .player ? Color.green.opacity(0.1) : Color.black.opacity(0.3))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(joinMode == .player ? Color.green : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Spectator Option
                    Button(action: {
                        joinMode = .spectator
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Image(systemName: "eye.fill")
                                        .foregroundColor(.blue)
                                    Text("Join as Spectator")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                Text("Watch the game without playing")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                            if joinMode == .spectator {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                        }
                        .padding()
                        .background(joinMode == .spectator ? Color.blue.opacity(0.1) : Color.black.opacity(0.3))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(joinMode == .spectator ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                
                // Player Name Display (if joining as player)
                if joinMode == .player && !playerName.isEmpty {
                    VStack(spacing: 8) {
                        Text("You'll join as:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(playerName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(8)
                }
                
                // Warning if user might already be in game
                if joinMode == .player {
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text("Note: You can only join once per game")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        Text("If you're already in this game, you can update your display name")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                }
                
                // Join Button
                Button(action: {
                    onConfirm()
                }) {
                    HStack {
                        Image(systemName: joinMode == .player ? "person.fill" : "eye.fill")
                        Text(joinMode == .player ? "Join as Player" : "Join as Spectator")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                }
                .foregroundColor(.white)
                .padding()
                .background(joinMode == .player ? Color.green : Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Join Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white)
            )
            .gradientBackground()
        }
    }
} 