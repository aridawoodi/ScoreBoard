//
//  UsernameValidationService.swift
//  ScoreBoard
//
//  Username validation service with format checking, uniqueness validation,
//  and suggestion generation for duplicate usernames.
//

import Foundation
import Amplify

/// Result of username validation
struct UsernameValidationResult {
    let isValid: Bool
    let isAvailable: Bool
    let message: String
    let messageType: ValidationMessageType
    let suggestions: [String]
    
    enum ValidationMessageType {
        case success
        case error
        case info
    }
    
    /// Creates a successful validation result
    static func success(message: String = "Username is available!") -> UsernameValidationResult {
        return UsernameValidationResult(
            isValid: true,
            isAvailable: true,
            message: message,
            messageType: .success,
            suggestions: []
        )
    }
    
    /// Creates an error validation result with suggestions
    static func error(message: String, suggestions: [String] = []) -> UsernameValidationResult {
        return UsernameValidationResult(
            isValid: false,
            isAvailable: false,
            message: message,
            messageType: .error,
            suggestions: suggestions
        )
    }
    
    /// Creates an info validation result
    static func info(message: String) -> UsernameValidationResult {
        return UsernameValidationResult(
            isValid: false,
            isAvailable: false,
            message: message,
            messageType: .info,
            suggestions: []
        )
    }
}

/// Service for validating usernames
class UsernameValidationService {
    static let shared = UsernameValidationService()
    
    // MARK: - Configuration
    
    private let minLength = 3
    private let maxLength = 20
    private let allowedCharactersRegex = "^[a-zA-Z0-9_]+$"
    
    // Common offensive words to block (expandable)
    private let blockedWords = [
        "admin", "root", "system", "moderator", "support",
        "test", "null", "undefined", "anonymous", "guest"
    ]
    
    private init() {}
    
    // MARK: - Public Validation Methods
    
    /// Comprehensive username validation
    /// - Parameter username: The username to validate
    /// - Returns: ValidationResult with detailed feedback
    func validateUsername(_ username: String) async -> UsernameValidationResult {
        print("🔍 DEBUG: UsernameValidationService - Validating username: '\(username)'")
        
        // Step 1: Format validation
        let formatResult = validateFormat(username)
        if !formatResult.isValid {
            print("🔍 DEBUG: UsernameValidationService - Format validation failed: \(formatResult.message)")
            return formatResult
        }
        
        // Step 2: Check blocked words
        if isBlockedWord(username) {
            print("🔍 DEBUG: UsernameValidationService - Username is blocked word")
            return .error(message: "This username is reserved. Please choose another.")
        }
        
        // Step 3: Check uniqueness (case-insensitive)
        let isAvailable = await checkAvailability(username)
        
        if !isAvailable {
            print("🔍 DEBUG: UsernameValidationService - Username is taken, generating suggestions")
            let suggestions = await generateSuggestions(for: username)
            return .error(
                message: "This username is already taken",
                suggestions: suggestions
            )
        }
        
        print("🔍 DEBUG: UsernameValidationService - Username is valid and available ✓")
        return .success()
    }
    
    /// Quick format-only validation (for real-time typing feedback)
    /// - Parameter username: The username to validate
    /// - Returns: ValidationResult with format feedback only
    func validateFormatOnly(_ username: String) -> UsernameValidationResult {
        return validateFormat(username)
    }
    
    // MARK: - Format Validation
    
    /// Validates username format
    private func validateFormat(_ username: String) -> UsernameValidationResult {
        // Check if empty
        if username.isEmpty {
            return .info(message: "Enter a username")
        }
        
        // Check minimum length
        if username.count < minLength {
            return .error(message: "Username must be at least \(minLength) characters")
        }
        
        // Check maximum length
        if username.count > maxLength {
            return .error(message: "Username must be no more than \(maxLength) characters")
        }
        
        // Check allowed characters (alphanumeric + underscore only)
        let regex = try? NSRegularExpression(pattern: allowedCharactersRegex, options: [])
        let range = NSRange(location: 0, length: username.utf16.count)
        
        if regex?.firstMatch(in: username, options: [], range: range) == nil {
            return .error(message: "Username can only contain letters, numbers, and underscores")
        }
        
        // Check if starts with number or underscore
        if let firstChar = username.first, !firstChar.isLetter {
            return .error(message: "Username must start with a letter")
        }
        
        // Check for consecutive underscores
        if username.contains("__") {
            return .error(message: "Username cannot contain consecutive underscores")
        }
        
        // All format checks passed
        return UsernameValidationResult(
            isValid: true,
            isAvailable: true, // Format is valid, but availability not checked yet
            message: "Format is valid",
            messageType: .info,
            suggestions: []
        )
    }
    
    // MARK: - Availability Checking
    
    /// Checks if username is available (case-insensitive)
    /// - Parameter username: The username to check
    /// - Returns: True if available, false if taken
    func checkAvailability(_ username: String) async -> Bool {
        print("🔍 DEBUG: UsernameValidationService - Checking availability for: '\(username)'")
        
        do {
            // Query all users from the database
            let result = try await Amplify.API.query(request: .list(User.self))
            
            switch result {
            case .success(let users):
                print("🔍 DEBUG: UsernameValidationService - Retrieved \(users.count) users from database")
                
                // Case-insensitive comparison
                let lowercaseUsername = username.lowercased()
                let isTaken = users.contains { user in
                    user.username.lowercased() == lowercaseUsername
                }
                
                if isTaken {
                    print("🔍 DEBUG: UsernameValidationService - Username '\(username)' is TAKEN")
                } else {
                    print("🔍 DEBUG: UsernameValidationService - Username '\(username)' is AVAILABLE ✓")
                }
                
                return !isTaken
                
            case .failure(let error):
                print("🔍 ERROR: UsernameValidationService - Failed to query users: \(error)")
                // On error, assume taken to be safe
                return false
            }
        } catch {
            print("🔍 ERROR: UsernameValidationService - Exception during availability check: \(error)")
            // On error, assume taken to be safe
            return false
        }
    }
    
    /// Checks if username is a blocked/reserved word
    private func isBlockedWord(_ username: String) -> Bool {
        let lowercaseUsername = username.lowercased()
        return blockedWords.contains(lowercaseUsername)
    }
    
    // MARK: - Suggestion Generation
    
    /// Generates username suggestions when the desired username is taken
    /// - Parameter username: The original username that was taken
    /// - Returns: Array of 3-5 available username suggestions
    func generateSuggestions(for username: String) async -> [String] {
        print("🔍 DEBUG: UsernameValidationService - Generating suggestions for: '\(username)'")
        
        var suggestions: [String] = []
        let maxSuggestions = 5
        
        // Strategy 1: Append random numbers (2-3 digits)
        for _ in 0..<3 {
            let randomNumber = Int.random(in: 10...999)
            let suggestion = "\(username)\(randomNumber)"
            
            // Only add if it passes format validation and is available
            if await isValidSuggestion(suggestion) {
                suggestions.append(suggestion)
                if suggestions.count >= maxSuggestions { break }
            }
        }
        
        // Strategy 2: Append common suffixes
        if suggestions.count < maxSuggestions {
            let suffixes = ["_sb", "_gamer", "_pro", "_player", "_x"]
            for suffix in suffixes {
                let suggestion = "\(username)\(suffix)"
                
                if await isValidSuggestion(suggestion) {
                    suggestions.append(suggestion)
                    if suggestions.count >= maxSuggestions { break }
                }
            }
        }
        
        // Strategy 3: Prepend "the_" or other prefixes
        if suggestions.count < maxSuggestions {
            let prefixes = ["the_", "i_am_", "mr_", "ms_"]
            for prefix in prefixes {
                let suggestion = "\(prefix)\(username)"
                
                if await isValidSuggestion(suggestion) {
                    suggestions.append(suggestion)
                    if suggestions.count >= maxSuggestions { break }
                }
            }
        }
        
        // Strategy 4: Modify with underscores
        if suggestions.count < maxSuggestions {
            let variations = [
                "\(username)_\(Int.random(in: 1...99))",
                "_\(username)_",
                "\(username)_official"
            ]
            
            for variation in variations {
                if await isValidSuggestion(variation) {
                    suggestions.append(variation)
                    if suggestions.count >= maxSuggestions { break }
                }
            }
        }
        
        print("🔍 DEBUG: UsernameValidationService - Generated \(suggestions.count) suggestions: \(suggestions)")
        
        return Array(suggestions.prefix(maxSuggestions))
    }
    
    /// Checks if a suggestion is valid (format + availability)
    private func isValidSuggestion(_ suggestion: String) async -> Bool {
        // Check format first (quick, no API call)
        let formatResult = validateFormat(suggestion)
        if !formatResult.isValid {
            return false
        }
        
        // Check length constraint
        if suggestion.count > maxLength {
            return false
        }
        
        // Check availability (requires API call)
        return await checkAvailability(suggestion)
    }
    
    // MARK: - Helper Methods
    
    /// Returns the allowed character set description
    func getAllowedCharactersDescription() -> String {
        return "Letters (a-z, A-Z), numbers (0-9), and underscores (_)"
    }
    
    /// Returns the length constraints
    func getLengthConstraints() -> (min: Int, max: Int) {
        return (minLength, maxLength)
    }
    
    /// Sanitizes a username by removing invalid characters
    func sanitizeUsername(_ username: String) -> String {
        // Remove all characters except alphanumeric and underscore
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        let sanitized = username.components(separatedBy: allowedCharacters.inverted).joined()
        
        // Ensure it starts with a letter
        if let firstChar = sanitized.first, !firstChar.isLetter {
            // Find the first letter
            if let firstLetterIndex = sanitized.firstIndex(where: { $0.isLetter }) {
                return String(sanitized[firstLetterIndex...])
            }
            return "" // No letters found
        }
        
        return sanitized
    }
}

// MARK: - Debounce Helper

/// Helper class for debouncing username validation
class ValidationDebouncer {
    private var workItem: DispatchWorkItem?
    private let delay: TimeInterval
    
    init(delay: TimeInterval = 0.5) {
        self.delay = delay
    }
    
    /// Debounces the validation call
    func debounce(action: @escaping () -> Void) {
        // Cancel previous work item
        workItem?.cancel()
        
        // Create new work item
        let newWorkItem = DispatchWorkItem(block: action)
        workItem = newWorkItem
        
        // Schedule execution after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: newWorkItem)
    }
    
    /// Cancels any pending validation
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}

