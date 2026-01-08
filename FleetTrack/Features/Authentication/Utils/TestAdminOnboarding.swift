//
//  TestAdminOnboarding.swift
//  authFMS
//
//  Created by Eknoor on 06/01/26.
//
//  Test script for new admin onboarding workflow

import Foundation

/// Test the complete admin onboarding workflow
@MainActor
class TestAdminOnboarding {
    
    private let authService = MockAuthService.shared
    private let twoFactorService = MockTwoFactorService.shared
    private let emailService = MockEmailService.shared
    private let dataStore = MockDataStore.shared
    
    /// Run all tests
    func runAllTests() async {
        print("\n🧪 ========== TESTING ADMIN ONBOARDING WORKFLOW ==========\n")
        
        await testAdminAccountCreation()
        await testSetupTokenValidation()
        await testPasswordSetup()
        await testCompleteOnboardingFlow()
        await testErrorCases()
        
        print("\n✅ ========== ALL TESTS COMPLETED ==========\n")
    }
    
    // MARK: - Test Cases
    
    /// Test 1: Admin account creation
    func testAdminAccountCreation() async {
        print("📋 Test 1: Admin Account Creation")
        
        do {
            let (user, token) = try await authService.createAdminAccount(email: "newadmin@fleetms.com")
            
            assert(user.email == "newadmin@fleetms.com", "Email should match")
            assert(user.role == .admin, "Role should be admin")
            assert(user.needsPasswordSetup, "Should need password setup")
            assert(!user.isVerified, "Should not be verified yet")
            assert(!token.isEmpty, "Token should be generated")
            
            print("   ✅ Admin account created successfully")
            print("   ✅ Setup token generated: \(token.prefix(20))...")
        } catch {
            print("   ❌ Failed: \(error.localizedDescription)")
        }
        
        print("")
    }
    
    /// Test 2: Setup token validation
    func testSetupTokenValidation() async {
        print("📋 Test 2: Setup Token Validation")
        
        do {
            // Create account
            let (_, token) = try await authService.createAdminAccount(email: "tokentest@fleetms.com")
            
            // Validate token
            let user = try await authService.verifySetupToken(token)
            
            assert(user.email == "tokentest@fleetms.com", "Email should match")
            assert(user.needsPasswordSetup, "Should need password setup")
            
            print("   ✅ Valid token verified successfully")
            
            // Test invalid token
            do {
                _ = try await authService.verifySetupToken("invalid_token")
                print("   ❌ Should have thrown error for invalid token")
            } catch {
                print("   ✅ Invalid token rejected correctly")
            }
            
        } catch {
            print("   ❌ Failed: \(error.localizedDescription)")
        }
        
        print("")
    }
    
    /// Test 3: Password setup
    func testPasswordSetup() async {
        print("📋 Test 3: Password Setup")
        
        do {
            // Create account
            let (_, token) = try await authService.createAdminAccount(email: "passwordtest@fleetms.com")
            
            // Set password
            let user = try await authService.setInitialPassword(token: token, password: "Admin@123")
            
            assert(!user.needsPasswordSetup, "Should not need password setup anymore")
            assert(user.isVerified, "Should be verified")
            assert(user.passwordHash != nil, "Password hash should be set")
            assert(user.passwordSetAt != nil, "Password set date should be recorded")
            
            print("   ✅ Password set successfully")
            
            // Test weak password
            let (_, token2) = try await authService.createAdminAccount(email: "weakpass@fleetms.com")
            do {
                _ = try await authService.setInitialPassword(token: token2, password: "weak")
                print("   ❌ Should have rejected weak password")
            } catch {
                print("   ✅ Weak password rejected correctly")
            }
            
        } catch {
            print("   ❌ Failed: \(error.localizedDescription)")
        }
        
        print("")
    }
    
    /// Test 4: Complete onboarding flow
    func testCompleteOnboardingFlow() async {
        print("📋 Test 4: Complete Onboarding Flow")
        
        do {
            // Step 1: Create account
            print("   Step 1: Creating admin account...")
            let (user, token) = try await authService.createAdminAccount(email: "complete@fleetms.com")
            try await emailService.sendSetupEmail(to: user.email!, token: token)
            
            // Step 2: Set password
            print("   Step 2: Setting password...")
            let updatedUser = try await authService.setInitialPassword(token: token, password: "Admin@123")
            
            // Step 3: Setup 2FA
            print("   Step 3: Setting up 2FA...")
            let totpConfig = try await twoFactorService.setupTOTP(for: updatedUser.id)
            
            // Simulate TOTP code (in real app, user scans QR and enters code)
            let totpCode = CryptoHelpers.generateTOTPCode(secret: totpConfig.secret)
            try await twoFactorService.verifyAndEnableTOTP(for: updatedUser.id, code: totpCode)
            
            // Step 4: Login
            print("   Step 4: Testing login...")
            let loggedInUser = try await authService.adminLogin(email: "complete@fleetms.com", password: "Admin@123")
            
            // Verify 2FA
            let newCode = CryptoHelpers.generateTOTPCode(secret: totpConfig.secret)
            let verified = try await twoFactorService.verifyTOTPCode(for: loggedInUser.id, code: newCode)
            
            assert(verified, "2FA verification should succeed")
            
            // Create session
            let session = try await authService.createSession(for: loggedInUser)
            
            assert(session.isValid, "Session should be valid")
            
            print("   ✅ Complete onboarding flow successful!")
            print("   ✅ User can now login with email, password, and 2FA")
            
        } catch {
            print("   ❌ Failed: \(error.localizedDescription)")
        }
        
        print("")
    }
    
    /// Test 5: Error cases
    func testErrorCases() async {
        print("📋 Test 5: Error Cases")
        
        // Test duplicate email
        do {
            _ = try await authService.createAdminAccount(email: "duplicate@fleetms.com")
            _ = try await authService.createAdminAccount(email: "duplicate@fleetms.com")
            print("   ❌ Should have rejected duplicate email")
        } catch AuthError.emailAlreadyExists {
            print("   ✅ Duplicate email rejected correctly")
        } catch {
            print("   ❌ Wrong error: \(error.localizedDescription)")
        }
        
        // Test login before password setup
        do {
            let (user, _) = try await authService.createAdminAccount(email: "nopassword@fleetms.com")
            _ = try await authService.adminLogin(email: user.email!, password: "anything")
            print("   ❌ Should have rejected login before password setup")
        } catch AuthError.passwordNotSet {
            print("   ✅ Login before password setup rejected correctly")
        } catch {
            print("   ❌ Wrong error: \(error.localizedDescription)")
        }
        
        // Test token reuse
        do {
            let (_, token) = try await authService.createAdminAccount(email: "tokenreuse@fleetms.com")
            _ = try await authService.setInitialPassword(token: token, password: "Admin@123")
            _ = try await authService.setInitialPassword(token: token, password: "Admin@456")
            print("   ❌ Should have rejected token reuse")
        } catch AuthError.passwordAlreadySet {
            print("   ✅ Token reuse rejected correctly")
        } catch {
            print("   ❌ Wrong error: \(error.localizedDescription)")
        }
        
        print("")
    }
}

// MARK: - Usage Example

/*
 To run tests:
 
 Task {
     await TestAdminOnboarding().runAllTests()
 }
 */
