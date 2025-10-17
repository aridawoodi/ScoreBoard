//
//  UsernameValidationServiceTests.swift
//  ScoreBoard
//
//  Test and demonstration file for UsernameValidationService
//

import Foundation

class UsernameValidationServiceTests {
    static let shared = UsernameValidationServiceTests()
    private let service = UsernameValidationService.shared
    
    private init() {}
    
    /// Run all validation tests
    func runAllTests() async {
        print("\n🧪 ===== USERNAME VALIDATION SERVICE TESTS START =====\n")
        
        await testFormatValidation()
        await testLengthConstraints()
        await testSpecialCharacters()
        await testAvailabilityCheck()
        await testSuggestionGeneration()
        testSanitization()
        
        print("\n🧪 ===== USERNAME VALIDATION SERVICE TESTS END =====\n")
    }
    
    // MARK: - Test Cases
    
    func testFormatValidation() async {
        print("🧪 TEST 1: Format Validation")
        
        let testCases: [(username: String, shouldPass: Bool, description: String)] = [
            ("john", true, "Simple username"),
            ("john_doe", true, "Username with underscore"),
            ("john123", true, "Username with numbers"),
            ("j", false, "Too short (< 3 chars)"),
            ("abcdefghijklmnopqrstuvwxyz", false, "Too long (> 20 chars)"),
            ("123john", false, "Starts with number"),
            ("_john", false, "Starts with underscore"),
            ("john__doe", false, "Consecutive underscores"),
            ("john-doe", false, "Contains hyphen"),
            ("john doe", false, "Contains space"),
            ("john@doe", false, "Contains special char"),
            ("", false, "Empty string"),
        ]
        
        for testCase in testCases {
            let result = service.validateFormatOnly(testCase.username)
            let passed = result.isValid == testCase.shouldPass
            let emoji = passed ? "✅" : "❌"
            
            print("   \(emoji) '\(testCase.username)' - \(testCase.description)")
            print("      Result: \(result.message)")
            
            if !passed {
                print("      ⚠️  FAILED: Expected \(testCase.shouldPass), got \(result.isValid)")
            }
        }
        
        print("   ✅ TEST 1 COMPLETED\n")
    }
    
    func testLengthConstraints() async {
        print("🧪 TEST 2: Length Constraints")
        
        let constraints = service.getLengthConstraints()
        print("   Min length: \(constraints.min)")
        print("   Max length: \(constraints.max)")
        
        // Test edge cases
        let minUsername = String(repeating: "a", count: constraints.min)
        let maxUsername = String(repeating: "a", count: constraints.max)
        let tooShort = String(repeating: "a", count: constraints.min - 1)
        let tooLong = String(repeating: "a", count: constraints.max + 1)
        
        let minResult = service.validateFormatOnly(minUsername)
        let maxResult = service.validateFormatOnly(maxUsername)
        let shortResult = service.validateFormatOnly(tooShort)
        let longResult = service.validateFormatOnly(tooLong)
        
        print("   Minimum length (\(minUsername)): \(minResult.isValid ? "✅" : "❌")")
        print("   Maximum length (\(maxUsername)): \(maxResult.isValid ? "✅" : "❌")")
        print("   Too short (\(tooShort)): \(!shortResult.isValid ? "✅" : "❌")")
        print("   Too long (\(tooLong.prefix(10))...): \(!longResult.isValid ? "✅" : "❌")")
        
        print("   ✅ TEST 2 COMPLETED\n")
    }
    
    func testSpecialCharacters() async {
        print("🧪 TEST 3: Special Characters")
        
        print("   Allowed characters: \(service.getAllowedCharactersDescription())")
        
        let testCases = [
            "valid_user123",  // Should pass
            "user@domain",    // Should fail
            "user#tag",       // Should fail
            "user.name",      // Should fail
            "user-name",      // Should fail
            "user name",      // Should fail
        ]
        
        for username in testCases {
            let result = service.validateFormatOnly(username)
            let emoji = result.isValid ? "✅" : "❌"
            print("   \(emoji) '\(username)': \(result.message)")
        }
        
        print("   ✅ TEST 3 COMPLETED\n")
    }
    
    func testAvailabilityCheck() async {
        print("🧪 TEST 4: Availability Check")
        
        // Test with a likely taken username
        let commonUsername = "john"
        print("   Checking availability for '\(commonUsername)'...")
        
        let isAvailable = await service.checkAvailability(commonUsername)
        print("   Result: \(isAvailable ? "✅ Available" : "❌ Taken")")
        
        // Test with a unique username
        let uniqueUsername = "test_unique_\(UUID().uuidString.prefix(8))"
        print("   Checking availability for '\(uniqueUsername)'...")
        
        let isUniqueAvailable = await service.checkAvailability(uniqueUsername)
        print("   Result: \(isUniqueAvailable ? "✅ Available" : "❌ Taken")")
        
        print("   ✅ TEST 4 COMPLETED\n")
    }
    
    func testSuggestionGeneration() async {
        print("🧪 TEST 5: Suggestion Generation")
        
        let takenUsername = "john"
        print("   Generating suggestions for '\(takenUsername)'...")
        
        let suggestions = await service.generateSuggestions(for: takenUsername)
        
        print("   Generated \(suggestions.count) suggestions:")
        for (index, suggestion) in suggestions.enumerated() {
            print("      \(index + 1). \(suggestion)")
            
            // Verify each suggestion is valid
            let result = await service.validateUsername(suggestion)
            if result.isValid && result.isAvailable {
                print("         ✅ Valid and available")
            } else {
                print("         ❌ Invalid or taken")
            }
        }
        
        print("   ✅ TEST 5 COMPLETED\n")
    }
    
    func testSanitization() {
        print("🧪 TEST 6: Username Sanitization")
        
        let testCases: [(input: String, expected: String)] = [
            ("john@doe", "johndoe"),
            ("user name", "username"),
            ("123user", "user"),
            ("user#123", "user123"),
            ("___user", "user"),
            ("user!!!123", "user123"),
        ]
        
        for testCase in testCases {
            let sanitized = service.sanitizeUsername(testCase.input)
            let passed = sanitized == testCase.expected
            let emoji = passed ? "✅" : "⚠️"
            
            print("   \(emoji) '\(testCase.input)' → '\(sanitized)' (expected: '\(testCase.expected)')")
        }
        
        print("   ✅ TEST 6 COMPLETED\n")
    }
    
    // MARK: - Usage Examples
    
    func demonstrateUsage() async {
        print("\n📖 ===== USAGE EXAMPLES =====\n")
        
        // Example 1: Quick format check (no API call)
        print("Example 1: Quick Format Check")
        let formatResult = service.validateFormatOnly("john_doe")
        print("   Result: \(formatResult.message)")
        print("   Is valid format: \(formatResult.isValid)\n")
        
        // Example 2: Full validation (with availability check)
        print("Example 2: Full Validation")
        let fullResult = await service.validateUsername("john_doe_123")
        print("   Result: \(fullResult.message)")
        print("   Is valid: \(fullResult.isValid)")
        print("   Is available: \(fullResult.isAvailable)")
        if !fullResult.suggestions.isEmpty {
            print("   Suggestions: \(fullResult.suggestions.joined(separator: ", "))")
        }
        print()
        
        // Example 3: Check availability only
        print("Example 3: Check Availability Only")
        let isAvailable = await service.checkAvailability("uniqueuser123")
        print("   Is available: \(isAvailable)\n")
        
        // Example 4: Generate suggestions
        print("Example 4: Generate Suggestions")
        let suggestions = await service.generateSuggestions(for: "john")
        print("   Suggestions: \(suggestions.joined(separator: ", "))\n")
        
        print("===== USAGE EXAMPLES END =====\n")
    }
}

