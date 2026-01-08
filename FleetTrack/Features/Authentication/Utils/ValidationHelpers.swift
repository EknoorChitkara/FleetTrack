//
//  ValidationHelpers.swift
//  authFMS
//
//  Created by Eknoor on 04/01/26.
//

import Foundation

/// Validation helpers for user input
struct ValidationHelpers {
    
    // MARK: - Email Validation
    
    /// Validate email format
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Get email validation error message
    static func emailValidationMessage(_ email: String) -> String? {
        if email.isEmpty {
            return "Email is required"
        }
        if !isValidEmail(email) {
            return "Please enter a valid email address"
        }
        return nil
    }
    
    // MARK: - Phone Number Validation
    
    /// Validate phone number format (supports US format)
    static func isValidPhoneNumber(_ phone: String) -> Bool {
        let cleanedPhone = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        return cleanedPhone.count >= 10 && cleanedPhone.count <= 15
    }
    
    /// Format phone number for display
    static func formatPhoneNumber(_ phone: String) -> String {
        let cleanedPhone = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        guard cleanedPhone.count >= 10 else { return phone }
        
        let areaCode = cleanedPhone.prefix(3)
        let middle = cleanedPhone.dropFirst(3).prefix(3)
        let last = cleanedPhone.dropFirst(6).prefix(4)
        
        return "+1 \(areaCode)-\(middle)-\(last)"
    }
    
    /// Get phone validation error message
    static func phoneValidationMessage(_ phone: String) -> String? {
        if phone.isEmpty {
            return "Phone number is required"
        }
        if !isValidPhoneNumber(phone) {
            return "Please enter a valid phone number"
        }
        return nil
    }
    
    // MARK: - Employee ID Validation
    
    /// Validate employee ID format (3 letters + 3 digits)
    static func isValidEmployeeID(_ employeeID: String) -> Bool {
        let employeeIDRegex = "^[A-Z]{3}[0-9]{3}$"
        let employeeIDPredicate = NSPredicate(format: "SELF MATCHES %@", employeeIDRegex)
        return employeeIDPredicate.evaluate(with: employeeID.uppercased())
    }
    
    /// Format employee ID (uppercase)
    static func formatEmployeeID(_ employeeID: String) -> String {
        return employeeID.uppercased()
    }
    
    /// Get employee ID validation error message
    static func employeeIDValidationMessage(_ employeeID: String) -> String? {
        if employeeID.isEmpty {
            return "Employee ID is required"
        }
        if !isValidEmployeeID(employeeID) {
            return "Employee ID must be 3 letters followed by 3 digits (e.g., DRV001)"
        }
        return nil
    }
    
    // MARK: - Password Validation
    
    /// Password strength levels
    enum PasswordStrength: Int {
        case veryWeak = 0
        case weak = 1
        case medium = 2
        case strong = 3
        case veryStrong = 4
        
        var displayName: String {
            switch self {
            case .veryWeak: return "Very Weak"
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            case .veryStrong: return "Very Strong"
            }
        }
        
        var color: String {
            switch self {
            case .veryWeak: return "red"
            case .weak: return "orange"
            case .medium: return "yellow"
            case .strong: return "green"
            case .veryStrong: return "blue"
            }
        }
    }
    
    /// Check password strength
    static func passwordStrength(_ password: String) -> PasswordStrength {
        var score = 0
        
        // Length check
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        
        // Character variety checks
        if password.range(of: "[A-Z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[a-z]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[0-9]", options: .regularExpression) != nil { score += 1 }
        if password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil { score += 1 }
        
        // Map score to strength
        switch score {
        case 0...1: return .veryWeak
        case 2: return .weak
        case 3...4: return .medium
        case 5: return .strong
        default: return .veryStrong
        }
    }
    
    /// Validate password meets minimum requirements
    static func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }
        
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChar = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        
        return hasUppercase && hasLowercase && hasNumber && hasSpecialChar
    }
    
    /// Get password validation error message
    static func passwordValidationMessage(_ password: String) -> String? {
        if password.isEmpty {
            return "Password is required"
        }
        if password.count < 8 {
            return "Password must be at least 8 characters"
        }
        if !isValidPassword(password) {
            return "Password must contain uppercase, lowercase, number, and special character"
        }
        return nil
    }
    
    /// Get detailed password requirements
    static func passwordRequirements(_ password: String) -> [String: Bool] {
        return [
            "At least 8 characters": password.count >= 8,
            "Uppercase letter": password.range(of: "[A-Z]", options: .regularExpression) != nil,
            "Lowercase letter": password.range(of: "[a-z]", options: .regularExpression) != nil,
            "Number": password.range(of: "[0-9]", options: .regularExpression) != nil,
            "Special character": password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        ]
    }
    
    // MARK: - 2FA Code Validation
    
    /// Validate 2FA code format (6 digits)
    static func isValid2FACode(_ code: String) -> Bool {
        let codeRegex = "^[0-9]{6}$"
        let codePredicate = NSPredicate(format: "SELF MATCHES %@", codeRegex)
        return codePredicate.evaluate(with: code)
    }
    
    /// Get 2FA code validation error message
    static func twoFactorCodeValidationMessage(_ code: String) -> String? {
        if code.isEmpty {
            return "Verification code is required"
        }
        if !isValid2FACode(code) {
            return "Code must be 6 digits"
        }
        return nil
    }
}
