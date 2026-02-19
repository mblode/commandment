import Foundation
import Security

enum KeychainManager {
    private static let service = "co.blode.commandment"
    private static let apiKeyAccount = "OpenAIAPIKey"

    private static func withOptionalDataProtectionKeychain(_ baseQuery: [String: Any]) -> [[String: Any]] {
        var dataProtectionQuery = baseQuery
        dataProtectionQuery[kSecUseDataProtectionKeychain as String] = true
        return [dataProtectionQuery, baseQuery]
    }

    private static func addWithFallback(_ baseQuery: [String: Any]) -> OSStatus {
        let queries = withOptionalDataProtectionKeychain(baseQuery)
        let firstStatus = SecItemAdd(queries[0] as CFDictionary, nil)
        if firstStatus == errSecMissingEntitlement {
            logInfo("KeychainManager: Falling back to legacy keychain (missing entitlement for data protection keychain)")
            return SecItemAdd(queries[1] as CFDictionary, nil)
        }
        return firstStatus
    }

    private static func deleteWithFallback(_ baseQuery: [String: Any]) -> OSStatus {
        let queries = withOptionalDataProtectionKeychain(baseQuery)
        let firstStatus = SecItemDelete(queries[0] as CFDictionary)
        if firstStatus == errSecMissingEntitlement {
            return SecItemDelete(queries[1] as CFDictionary)
        }
        return firstStatus
    }

    private static func copyMatchingWithFallback(_ baseQuery: [String: Any], result: inout AnyObject?) -> OSStatus {
        let queries = withOptionalDataProtectionKeychain(baseQuery)
        let firstStatus = SecItemCopyMatching(queries[0] as CFDictionary, &result)
        if firstStatus == errSecMissingEntitlement {
            result = nil
            return SecItemCopyMatching(queries[1] as CFDictionary, &result)
        }
        return firstStatus
    }

    static func saveAPIKey(_ key: String) {
        guard let data = key.data(using: .utf8) else { return }

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount
        ]
        _ = deleteWithFallback(deleteQuery)

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
        } else {
            logError("KeychainManager: Failed to save API key (status: \(status))")
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

    static func deleteAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount
        ]
        let status = deleteWithFallback(query)
        if status == errSecSuccess {
            logInfo("KeychainManager: API key deleted from keychain")
        } else if status != errSecItemNotFound {
            logError("KeychainManager: Failed to delete API key (status: \(status))")
        }
    }
}
