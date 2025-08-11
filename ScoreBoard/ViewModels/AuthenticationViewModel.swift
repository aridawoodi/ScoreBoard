//
//  AuthenticationViewModel.swift
//  ScoreBoard
//
//  Created by Ari Dawoodi on 11/6/24.
//

import Foundation
import Amplify

class AuthenticationViewModel: ObservableObject {
    @Published var isLoggedIn = false

    func signInWithApple() {
        // Logic for Apple sign-in using Amplify
    }

    func signInWithGoogle() {
        // Logic for Google sign-in using Amplify
    }
}
