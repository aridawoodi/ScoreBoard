//
//  ProfileSetupManagerTests.swift
//  ScoreBoard
//
//  Manual testing helper for ProfileSetupManager
//

import Foundation

class ProfileSetupManagerTests {
    static let shared = ProfileSetupManagerTests()
    private let manager = ProfileSetupManager.shared
    
    private init() {}
    
    /// Run all tests
    func runAllTests() {
        print("\n🧪 ===== PROFILE SETUP MANAGER TESTS START =====\n")
        
        testSetupCompletion()
        testSetupSkipping()
        testSetupClearing()
        testMultipleUsers()
        
        print("\n🧪 ===== PROFILE SETUP MANAGER TESTS END =====\n")
    }
    
    // MARK: - Test Cases
    
    func testSetupCompletion() {
        print("🧪 TEST 1: Setup Completion Tracking")
        let testUserId = "test_user_123"
        
        // Clear any existing state
        manager.clearSetupFlags(userId: testUserId)
        
        // Test initial state
        let initialState = manager.hasCompletedSetup(userId: testUserId)
        print("   Initial completed state: \(initialState)")
        assert(!initialState, "Initial state should be false")
        
        // Mark as completed
        manager.markSetupCompleted(userId: testUserId)
        
        // Verify completed state
        let completedState = manager.hasCompletedSetup(userId: testUserId)
        print("   After marking complete: \(completedState)")
        assert(completedState, "Should be marked as completed")
        
        // Verify validated state
        let validatedState = manager.isUsernameValidated(userId: testUserId)
        print("   Username validated: \(validatedState)")
        assert(validatedState, "Username should be validated when setup is completed")
        
        // Cleanup
        manager.clearSetupFlags(userId: testUserId)
        
        print("   ✅ TEST 1 PASSED\n")
    }
    
    func testSetupSkipping() {
        print("🧪 TEST 2: Setup Skipping Tracking")
        let testUserId = "test_user_456"
        
        // Clear any existing state
        manager.clearSetupFlags(userId: testUserId)
        
        // Test initial state
        let initialState = manager.hasSkippedSetup(userId: testUserId)
        print("   Initial skipped state: \(initialState)")
        assert(!initialState, "Initial state should be false")
        
        // Mark as skipped
        manager.markSetupSkipped(userId: testUserId)
        
        // Verify skipped state
        let skippedState = manager.hasSkippedSetup(userId: testUserId)
        print("   After marking skipped: \(skippedState)")
        assert(skippedState, "Should be marked as skipped")
        
        // Verify completed state is still false
        let completedState = manager.hasCompletedSetup(userId: testUserId)
        print("   Completed state (should be false): \(completedState)")
        assert(!completedState, "Completed should still be false when skipped")
        
        // Cleanup
        manager.clearSetupFlags(userId: testUserId)
        
        print("   ✅ TEST 2 PASSED\n")
    }
    
    func testSetupClearing() {
        print("🧪 TEST 3: Setup Flag Clearing")
        let testUserId = "test_user_789"
        
        // Set all flags
        manager.markSetupCompleted(userId: testUserId)
        manager.markSetupSkipped(userId: testUserId)
        
        // Verify flags are set
        print("   Before clearing - Completed: \(manager.hasCompletedSetup(userId: testUserId))")
        print("   Before clearing - Skipped: \(manager.hasSkippedSetup(userId: testUserId))")
        
        // Clear all flags
        manager.clearSetupFlags(userId: testUserId)
        
        // Verify all flags are cleared
        let completedAfter = manager.hasCompletedSetup(userId: testUserId)
        let skippedAfter = manager.hasSkippedSetup(userId: testUserId)
        let validatedAfter = manager.isUsernameValidated(userId: testUserId)
        
        print("   After clearing - Completed: \(completedAfter)")
        print("   After clearing - Skipped: \(skippedAfter)")
        print("   After clearing - Validated: \(validatedAfter)")
        
        assert(!completedAfter && !skippedAfter && !validatedAfter, "All flags should be cleared")
        
        print("   ✅ TEST 3 PASSED\n")
    }
    
    func testMultipleUsers() {
        print("🧪 TEST 4: Multiple Users Isolation")
        let user1 = "user_aaa"
        let user2 = "user_bbb"
        
        // Clear existing states
        manager.clearSetupFlags(userId: user1)
        manager.clearSetupFlags(userId: user2)
        
        // Mark user1 as completed
        manager.markSetupCompleted(userId: user1)
        
        // Mark user2 as skipped
        manager.markSetupSkipped(userId: user2)
        
        // Verify user1 state
        print("   User1 completed: \(manager.hasCompletedSetup(userId: user1))")
        print("   User1 skipped: \(manager.hasSkippedSetup(userId: user1))")
        
        // Verify user2 state
        print("   User2 completed: \(manager.hasCompletedSetup(userId: user2))")
        print("   User2 skipped: \(manager.hasSkippedSetup(userId: user2))")
        
        // Assertions
        assert(manager.hasCompletedSetup(userId: user1), "User1 should be completed")
        assert(!manager.hasSkippedSetup(userId: user1), "User1 should not be skipped")
        assert(!manager.hasCompletedSetup(userId: user2), "User2 should not be completed")
        assert(manager.hasSkippedSetup(userId: user2), "User2 should be skipped")
        
        // Cleanup
        manager.clearSetupFlags(userId: user1)
        manager.clearSetupFlags(userId: user2)
        
        print("   ✅ TEST 4 PASSED\n")
    }
    
    // MARK: - Debug State Printer
    
    func printCurrentState(for userId: String) {
        manager.printSetupState(userId: userId)
    }
}

