//
//  KeychainHelper.swift
//  authFMS
//
//  Created by Eknoor on 04/01/26.
//

import Foundation
import Security

/// Helper for secure storage in iOS Keychain
class KeychainHelper {

    static let shared = KeychainHelper()

    private init() {}

    // MARK: - Save

    /// Save data to keychain
    func save(_ data: Data, forKey key: String) -> Bool {
        // Delete any existing item
        delete(forKey: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Save string to keychain
    func save(_ string: String, forKey key: String) -> Bool {
        guard let data = string.data(using: .utf8) else { return false }
        return save(data, forKey: key)
    }

    /// Save codable object to keychain
    func save<T: Codable>(_ object: T, forKey key: String) -> Bool {
        guard let data = try? JSONEncoder().encode(object) else { return false }
        return save(data, forKey: key)
    }

    // MARK: - Retrieve

    /// Retrieve data from keychain
    func retrieve(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    /// Retrieve string from keychain
    func retrieveString(forKey key: String) -> String? {
        guard let data = retrieve(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Retrieve codable object from keychain
    func retrieve<T: Codable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = retrieve(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    // MARK: - Delete

    /// Delete item from keychain
    @discardableResult
    func delete(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Clear All

    /// Clear all keychain items for this app
    @discardableResult
    func clearAll() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - Keychain Keys

extension KeychainHelper {
    /// Common keychain keys
    enum Keys {
        static let sessionToken = "com.fleetms.sessionToken"
        static let currentUserID = "com.fleetms.currentUserID"
        static let rememberMe = "com.fleetms.rememberMe"
        static let biometricEnabled = "com.fleetms.biometricEnabled"
    }
}
