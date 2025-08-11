//
//  LoginView.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation
import SwiftUI
import Amplify

struct LoginView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Scoreboard App")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Button(action: {
//                signInWithApple()
            }) {
                Text("Sign in with Apple")
                    .frame(width: 280, height: 45)
                    .background(Color.primary)
                    .foregroundColor(Color(.systemBackground))
                    .cornerRadius(8)
            }

            Button(action: {
//                signInWithGoogle()
            }) {
                Text("Sign in with Google")
                    .frame(width: 280, height: 45)
                    .background(Color.accentColor)
                    .foregroundColor(Color(.systemBackground))
                    .cornerRadius(8)
            }
        }
    }

}

