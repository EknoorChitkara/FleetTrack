//
//  FirebaseAuthAdapter.swift
//  FleetTrack
//
//  Created by Firebase Integration
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Adapter layer between Firebase Authentication and FleetTrack's authentication system
/// This preserves the existing MVVM architecture while leveraging Firebase's backend
class FirebaseAuthAdapter {
    
    static let shared = FirebaseAuthAdapter()
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    // Store verification ID for phone auth
    private var currentVerificationID: String?
    
    private init() {
        // Configure auth settings
        auth.languageCode = "en"
    }
    
    // MARK: - Admin Authentication
    
    /// Create admin account (system/super-admin only)
    /// Returns user and a flag indicating if password setup is needed
    func createAdminAccount(email: String) async throws -> (user: User, setupToken: String) {
        // Validate email
        guard ValidationHelpers.isValidEmail(email) else {
            throw FirebaseAuthError.invalidEmail
        }
        
        // Check if user already exists
        let existingUsers = try await db.collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments()
        
        if !existingUsers.documents.isEmpty {
            throw FirebaseAuthError.emailAlreadyExists
        }
        
        // Create Firebase user with temporary password
        let tempPassword = generateTemporaryPassword()
        
        let authResult = try await auth.createUser(withEmail: email, password: tempPassword)
        let firebaseUser = authResult.user
        
        // Send password reset email (acts as setup email)
        try await auth.sendPasswordReset(withEmail: email)
        
        // Create FleetTrack user profile
        let user = User(
            id: UUID(uuidString: firebaseUser.uid) ?? UUID(),
            role: .admin,
            email: email,
            isActive: true,
            isVerified: false,
            createdAt: Date(),
            twoFactorEnabled: false
        )
        
        // Store user metadata in Firestore
        try await saveUserMetadata(user, firebaseUID: firebaseUser.uid)
        
        print("✅ Admin account created: \(email)")
        print("📧 Password setup email sent to: \(email)")
        
        // Return a mock setup token (Firebase handles this via email)
        let setupToken = "firebase_email_sent"
        return (user, setupToken)
    }
    
    /// Admin login with email/password
    func adminLogin(email: String, password: String) async throws -> User {
        // Sign in with Firebase
        let authResult = try await auth.signIn(withEmail: email, password: password)
        let firebaseUser = authResult.user
        
        // Fetch user metadata from Firestore
        let user = try await fetchUserMetadata(firebaseUID: firebaseUser.uid)
        
        // Verify role
        guard user.role == .admin else {
            throw FirebaseAuthError.invalidRole
        }
        
        // Check if account is active
        guard user.isActive else {
            throw FirebaseAuthError.accountDeactivated
        }
        
        print("✅ Admin logged in: \(email)")
        return user
    }
    
    // MARK: - Driver Authentication
    
    /// Create driver account with phone number
    func createDriverAccount(phoneNumber: String, employeeID: String) async throws -> User {
        // Validate inputs
        guard ValidationHelpers.isValidPhoneNumber(phoneNumber) else {
            throw FirebaseAuthError.invalidPhoneNumber
        }
        
        guard ValidationHelpers.isValidEmployeeID(employeeID) else {
            throw FirebaseAuthError.invalidEmployeeID
        }
        
        // Check if driver already exists
        let existingDrivers = try await db.collection("users")
            .whereField("phoneNumber", isEqualTo: phoneNumber)
            .getDocuments()
        
        if !existingDrivers.documents.isEmpty {
            throw FirebaseAuthError.phoneAlreadyExists
        }
        
        // Create user profile (will be linked after phone verification)
        let user = User(
            id: UUID(),
            role: .driver,
            phoneNumber: phoneNumber,
            employeeID: employeeID,
            isActive: true,
            isVerified: false,
            createdAt: Date(),
            twoFactorEnabled: true // Phone auth is inherently 2FA
        )
        
        // Store in Firestore
        try await saveUserMetadata(user, firebaseUID: user.id.uuidString)
        
        print("✅ Driver account created: \(phoneNumber)")
        return user
    }
    
    /// Send SMS verification code to driver's phone
    func sendDriverSMSCode(phoneNumber: String) async throws -> String {
        // Format phone number (ensure it has country code)
        let formattedPhone = phoneNumber.hasPrefix("+") ? phoneNumber : "+1\(phoneNumber)"
        
        // Send SMS verification code via Firebase
        let verificationID = try await PhoneAuthProvider.provider()
            .verifyPhoneNumber(formattedPhone, uiDelegate: nil)
        
        // Store verification ID for later use
        currentVerificationID = verificationID
        
        print("✅ SMS sent to: \(phoneNumber)")
        return verificationID
    }
    
    /// Verify SMS code and complete driver login
    func verifyDriverSMSCode(verificationID: String, code: String, employeeID: String) async throws -> User {
        // Create phone credential
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        
        // Sign in with phone credential
        let authResult = try await auth.signIn(with: credential)
        let firebaseUser = authResult.user
        
        // Get phone number from Firebase user
        guard let phoneNumber = firebaseUser.phoneNumber else {
            throw FirebaseAuthError.invalidPhoneNumber
        }
        
        // Fetch user metadata by phone number
        let user = try await fetchUserMetadataByPhone(phoneNumber: phoneNumber)
        
        // Verify employee ID matches
        guard user.employeeID?.uppercased() == employeeID.uppercased() else {
            // Sign out if employee ID doesn't match
            try auth.signOut()
            throw FirebaseAuthError.invalidCredentials
        }
        
        // Update user verification status
        var updatedUser = user
        updatedUser.isVerified = true
        try await updateUserMetadata(updatedUser, firebaseUID: firebaseUser.uid)
        
        // Link the Firestore document to Firebase UID
        try await linkUserToFirebaseUID(user.id, firebaseUID: firebaseUser.uid)
        
        print("✅ Driver logged in: \(phoneNumber)")
        return updatedUser
    }
    
    // MARK: - Maintenance Manager Authentication
    
    /// Create maintenance manager account
    func createMaintenanceAccount(employeeID: String, email: String, password: String) async throws -> User {
        // Validate inputs
        guard ValidationHelpers.isValidEmail(email) else {
            throw FirebaseAuthError.invalidEmail
        }
        
        guard ValidationHelpers.isValidEmployeeID(employeeID) else {
            throw FirebaseAuthError.invalidEmployeeID
        }
        
        guard ValidationHelpers.isValidPassword(password) else {
            throw FirebaseAuthError.weakPassword
        }
        
        // Create Firebase user
        let authResult = try await auth.createUser(withEmail: email, password: password)
        let firebaseUser = authResult.user
        
        // Create user profile
        let user = User(
            id: UUID(uuidString: firebaseUser.uid) ?? UUID(),
            role: .maintenanceManager,
            email: email,
            employeeID: employeeID,
            isActive: true,
            isVerified: true,
            createdAt: Date(),
            twoFactorEnabled: false
        )
        
        // Store metadata
        try await saveUserMetadata(user, firebaseUID: firebaseUser.uid)
        
        print("✅ Maintenance account created: \(employeeID)")
        return user
    }
    
    /// Maintenance manager login
    func maintenanceLogin(employeeID: String, password: String) async throws -> User {
        // Fetch user by employee ID to get email
        let user = try await fetchUserMetadataByEmployeeID(employeeID)
        
        guard let email = user.email else {
            throw FirebaseAuthError.invalidCredentials
        }
        
        // Sign in with email/password
        let authResult = try await auth.signIn(withEmail: email, password: password)
        let firebaseUser = authResult.user
        
        // Verify role
        guard user.role == .maintenanceManager else {
            throw FirebaseAuthError.invalidRole
        }
        
        print("✅ Maintenance logged in: \(employeeID)")
        return user
    }
    
    // MARK: - Session Management
    
    /// Get current authenticated user
    func getCurrentUser() async throws -> User? {
        guard let firebaseUser = auth.currentUser else {
            return nil
        }
        
        do {
            return try await fetchUserMetadata(firebaseUID: firebaseUser.uid)
        } catch {
            // If user metadata not found, try to fetch by phone
            if let phoneNumber = firebaseUser.phoneNumber {
                return try? await fetchUserMetadataByPhone(phoneNumber: phoneNumber)
            }
            throw error
        }
    }
    
    /// Logout current user
    func logout() throws {
        try auth.signOut()
        currentVerificationID = nil
        print("✅ User logged out")
    }
    
    /// Check if user is authenticated
    var isAuthenticated: Bool {
        return auth.currentUser != nil
    }
    
    // MARK: - Password Management
    
    /// Send password reset email
    func sendPasswordResetEmail(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
        print("✅ Password reset email sent to: \(email)")
    }
    
    /// Update password (user must be authenticated)
    func updatePassword(newPassword: String) async throws {
        guard let user = auth.currentUser else {
            throw FirebaseAuthError.notAuthenticated
        }
        
        guard ValidationHelpers.isValidPassword(newPassword) else {
            throw FirebaseAuthError.weakPassword
        }
        
        try await user.updatePassword(to: newPassword)
        print("✅ Password updated")
    }
    
    // MARK: - Email Verification
    
    /// Send email verification
    func sendEmailVerification() async throws {
        guard let user = auth.currentUser else {
            throw FirebaseAuthError.notAuthenticated
        }
        
        try await user.sendEmailVerification()
        print("✅ Verification email sent")
    }
    
    // MARK: - Firestore User Metadata Management
    
    /// Save user metadata to Firestore
    private func saveUserMetadata(_ user: User, firebaseUID: String) async throws {
        let userRef = db.collection("users").document(firebaseUID)
        
        let userData: [String: Any] = [
            "id": user.id.uuidString,
            "role": user.role.rawValue,
            "email": user.email ?? NSNull(),
            "phoneNumber": user.phoneNumber ?? NSNull(),
            "employeeID": user.employeeID ?? NSNull(),
            "isActive": user.isActive,
            "isVerified": user.isVerified,
            "createdAt": Timestamp(date: user.createdAt),
            "lastLogin": user.lastLogin != nil ? Timestamp(date: user.lastLogin!) : NSNull(),
            "twoFactorEnabled": user.twoFactorEnabled,
            "failedLoginAttempts": user.failedLoginAttempts,
            "accountLockedUntil": user.accountLockedUntil != nil ? Timestamp(date: user.accountLockedUntil!) : NSNull()
        ]
        
        try await userRef.setData(userData, merge: true)
    }
    
    /// Update existing user metadata
    private func updateUserMetadata(_ user: User, firebaseUID: String) async throws {
        try await saveUserMetadata(user, firebaseUID: firebaseUID)
    }
    
    /// Fetch user metadata from Firestore by Firebase UID
    private func fetchUserMetadata(firebaseUID: String) async throws -> User {
        let userRef = db.collection("users").document(firebaseUID)
        let snapshot = try await userRef.getDocument()
        
        guard snapshot.exists, let data = snapshot.data() else {
            throw FirebaseAuthError.userNotFound
        }
        
        return try parseUserFromFirestore(data)
    }
    
    /// Fetch user by phone number
    func fetchUserMetadataByPhone(phoneNumber: String) async throws -> User {
        let query = db.collection("users")
            .whereField("phoneNumber", isEqualTo: phoneNumber)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw FirebaseAuthError.userNotFound
        }
        
        return try parseUserFromFirestore(document.data())
    }
    
    /// Fetch user by employee ID
    func fetchUserMetadataByEmployeeID(_ employeeID: String) async throws -> User {
        let query = db.collection("users")
            .whereField("employeeID", isEqualTo: employeeID.uppercased())
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw FirebaseAuthError.userNotFound
        }
        
        return try parseUserFromFirestore(document.data())
    }
    
    /// Link user's UUID to Firebase UID
    private func linkUserToFirebaseUID(_ userID: UUID, firebaseUID: String) async throws {
        let userRef = db.collection("users").document(firebaseUID)
        try await userRef.updateData(["id": userID.uuidString])
    }
    
    /// Parse User from Firestore data
    private func parseUserFromFirestore(_ data: [String: Any]) throws -> User {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let roleString = data["role"] as? String,
              let role = UserRole(rawValue: roleString) else {
            throw FirebaseAuthError.invalidData
        }
        
        let createdAtTimestamp = data["createdAt"] as? Timestamp
        let lastLoginTimestamp = data["lastLogin"] as? Timestamp
        let accountLockedUntilTimestamp = data["accountLockedUntil"] as? Timestamp
        
        return User(
            id: id,
            role: role,
            email: data["email"] as? String,
            phoneNumber: data["phoneNumber"] as? String,
            employeeID: data["employeeID"] as? String,
            isActive: data["isActive"] as? Bool ?? true,
            isVerified: data["isVerified"] as? Bool ?? false,
            createdAt: createdAtTimestamp?.dateValue() ?? Date(),
            lastLogin: lastLoginTimestamp?.dateValue(),
            failedLoginAttempts: data["failedLoginAttempts"] as? Int ?? 0,
            accountLockedUntil: accountLockedUntilTimestamp?.dateValue(),
            twoFactorEnabled: data["twoFactorEnabled"] as? Bool ?? false
        )
    }
    
    // MARK: - Helper Methods
    
    /// Generate temporary password for admin setup
    private func generateTemporaryPassword() -> String {
        let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
        return String((0..<16).map { _ in characters.randomElement()! })
    }
}

// MARK: - Firebase Auth Errors

enum FirebaseAuthError: LocalizedError {
    case invalidEmail
    case invalidPhoneNumber
    case invalidEmployeeID
    case weakPassword
    case emailAlreadyExists
    case phoneAlreadyExists
    case emailNotVerified
    case invalidRole
    case userNotFound
    case invalidCredentials
    case notAuthenticated
    case invalidData
    case accountDeactivated
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPhoneNumber:
            return "Please enter a valid phone number"
        case .invalidEmployeeID:
            return "Employee ID must be 3 letters followed by 3 digits (e.g., DRV001)"
        case .weakPassword:
            return "Password must be at least 8 characters with uppercase, lowercase, number, and special character"
        case .emailAlreadyExists:
            return "An account with this email already exists"
        case .phoneAlreadyExists:
            return "An account with this phone number already exists"
        case .emailNotVerified:
            return "Please verify your email before logging in"
        case .invalidRole:
            return "Invalid user role for this login method"
        case .userNotFound:
            return "User not found"
        case .invalidCredentials:
            return "Invalid credentials. Please try again."
        case .notAuthenticated:
            return "You must be logged in to perform this action"
        case .invalidData:
            return "Invalid user data"
        case .accountDeactivated:
            return "This account has been deactivated"
        }
    }
}
