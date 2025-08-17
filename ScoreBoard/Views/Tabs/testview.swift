//
//  testview.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 8/15/25.
//

import SwiftUI

struct WalletView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color("GradientBackground"), Color.black]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("@Alexsmithmobbin")
                            .foregroundColor(.white)
                            .font(.subheadline)
                        Text("Account 2")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.caption)
                    }
                    Spacer()
                    Image(systemName: "qrcode.viewfinder")
                        .foregroundColor(.white)
                        .font(.title3)
                }
                .padding(.horizontal)
                
                // Balance
                VStack(spacing: 4) {
                    Text("$21.23")
                        .foregroundColor(.white)
                        .font(.largeTitle)
                        .bold()
                    Text("+$0.36  •  +1.74%")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }
                .padding(.top, 10)
                
                // Action buttons
                HStack(spacing: 20) {
                    ActionButton(icon: "qrcode", label: "Receive")
                    ActionButton(icon: "paperplane", label: "Send")
                    ActionButton(icon: "arrow.left.arrow.right", label: "Swap")
                    ActionButton(icon: "dollarsign.circle", label: "Buy")
                }
                .padding(.top, 10)
                
                // Tokens list
                VStack(spacing: 12) {
                    TokenRow(icon: "circle.hexagongrid", name: "Ethereum", amount: "$18.98", change: "+$0.36", color: .green)
                    TokenRow(icon: "circle", name: "USDC", amount: "$2.25", change: "-$0.01", color: .red)
                    TokenRow(icon: "circle.fill", name: "Solana", amount: "$0.00", change: "+$0.00", color: .gray)
                    TokenRow(icon: "circle", name: "Ethereum", amount: "$0.00", change: "+$0.00", color: .gray)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
        }
    }
}

struct ActionButton: View {
    let icon: String
    let label: String
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.4))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(.purple)
                        .font(.title2)
                )
            Text(label)
                .foregroundColor(.white)
                .font(.caption)
        }
    }
}

struct TokenRow: View {
    let icon: String
    let name: String
    let amount: String
    let change: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.title2)
            Text(name)
                .foregroundColor(.white)
                .font(.body)
            Spacer()
            VStack(alignment: .trailing) {
                Text(amount)
                    .foregroundColor(.white)
                Text(change)
                    .foregroundColor(color)
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

#Preview {
    WalletView()
}
