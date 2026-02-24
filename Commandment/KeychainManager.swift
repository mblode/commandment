import Foundation
import Security

enum KeychainManager {
    private static let service = "co.blode.commandment"
    private static let apiKeyAccount = "OpenAIAPIKey"

    private enum KeychainOperation {
        case add
        case copy
        case delete
    }

    private static func withDataProtectionKeychain(_ baseQuery: [String: Any]) -> [String: Any] {
        var query = baseQuery
        query[kSecUseDataProtectionKeychain as String] = true
        return query
    }

    private static func shouldFallbackToLegacy(for status: OSStatus, operation: KeychainOperation) -> Bool {
        if status == errSecMissingEntitlement {
            return true
        }

        switch operation {
        case .add:
            return status == errSecNotAvailable || status == errSecInteractionNotAllowed
        case .copy, .delete:
            return status == errSecItemNotFound || status == errSecNotAvailable || status == errSecInteractionNotAllowed
        }
    }

    private static func addWithFallback(_ baseQuery: [String: Any]) -> OSStatus {
        let dataProtectionQuery = withDataProtectionKeychain(baseQuery)
        let dataProtectionStatus = SecItemAdd(dataProtectionQuery as CFDictionary, nil)
        guard dataProtectionStatus != errSecSuccess else {
            return dataProtectionStatus
        }
        guard shouldFallbackToLegacy(for: dataProtectionStatus, operation: .add) else {
            return dataProtectionStatus
        }
        logInfo("KeychainManager: Falling back to legacy keychain for save (status: \(dataProtectionStatus))")
        return SecItemAdd(baseQuery as CFDictionary, nil)
    }

    private static func deleteWithFallback(_ baseQuery: [String: Any]) -> OSStatus {
        let dataProtectionQuery = withDataProtectionKeychain(baseQuery)
        let dataProtectionStatus = SecItemDelete(dataProtectionQuery as CFDictionary)
        guard dataProtectionStatus != errSecSuccess else {
            return dataProtectionStatus
        }
        guard shouldFallbackToLegacy(for: dataProtectionStatus, operation: .delete) else {
            return dataProtectionStatus
        }
        if dataProtectionStatus == errSecMissingEntitlement {
            logInfo("KeychainManager: Falling back to legacy keychain for delete (missing entitlement)")
        }
        return SecItemDelete(baseQuery as CFDictionary)
    }

    private static func copyMatchingWithFallback(_ baseQuery: [String: Any], result: inout AnyObject?) -> OSStatus {
        let dataProtectionQuery = withDataProtectionKeychain(baseQuery)
        let dataProtectionStatus = SecItemCopyMatching(dataProtectionQuery as CFDictionary, &result)
        guard dataProtectionStatus != errSecSuccess else {
            return dataProtectionStatus
        }
        guard shouldFallbackToLegacy(for: dataProtectionStatus, operation: .copy) else {
            return dataProtectionStatus
        }
        if dataProtectionStatus == errSecMissingEntitlement {
            logInfo("KeychainManager: Falling back to legacy keychain for load (missing entitlement)")
        } else if dataProtectionStatus == errSecItemNotFound {
            logDebug("KeychainManager: API key not found in data protection keychain, trying legacy keychain")
        } else {
            logDebug("KeychainManager: Retrying load against legacy keychain (status: \(dataProtectionStatus))")
        }
        result = nil
        return SecItemCopyMatching(baseQuery as CFDictionary, &result)
    }

    @discardableResult
    static func saveAPIKey(_ key: String) -> Bool {
        guard let data = key.data(using: .utf8) else { return false }

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount
        ]
        let deleteStatus = deleteWithFallback(deleteQuery)
        if deleteStatus != errSecSuccess && deleteStatus != errSecItemNotFound {
            logError("KeychainManager: Failed to clear existing API key before save (status: \(deleteStatus))")
        }

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = addWithFallback(addQuery)
        if status == errSecSuccess {
            logInfo("KeychainManager: API key saved to keychain")
            return true
        } else {
            logError("KeychainManager: Failed to save API key (status: \(status))")
            return false
        }
    }

    static func loadAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = copyMatchingWithFallback(query, result: &result)

        guard status == errSecSuccess, let data = result as? Data else {
            if status == errSecItemNotFound {
                logDebug("KeychainManager: No API key found in keychain")
            } else {
                logError("KeychainManager: Failed to load API key (status: \(status))")
            }
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func deleteAPIKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount
        ]
        let status = deleteWithFallback(query)
        if status == errSecSuccess {
            logInfo("KeychainManager: API key deleted from keychain")
            return true
        } else if status == errSecItemNotFound {
            return true
        } else {
            logError("KeychainManager: Failed to delete API key (status: \(status))")
            return false
        }
    }
}
