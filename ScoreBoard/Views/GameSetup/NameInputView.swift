//
//  NameInputView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/5/24.
//

import Foundation
import SwiftUI

struct NameInputView: View {
    @Binding var playerName: String
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text("Enter Your Name")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("How should other players see you in this game?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Name Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Enter your name", text: $playerName)
                        .textFieldStyle(.roundedBorder)
                        .font(.title2)
                        .autocapitalization(.words)
                        .onSubmit {
                            confirmName()
                        }
                }
                .padding(.horizontal)
                
                // Confirm Button
                Button(action: {
                    confirmName()
                }) {
                    Text("Join Game")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Enter Name")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
    
    func confirmName() {
        let trimmedName = playerName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        playerName = trimmedName
        onConfirm()
        dismiss()
    }
} 