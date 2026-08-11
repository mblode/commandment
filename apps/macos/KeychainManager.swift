import Foundation
import Security

enum KeychainManager {
    private static let service = "co.blode.commandment"
    private static let apiKeyAccount = "OpenAIAPIKey"

    private enum KeychainOperation {
        case add
        case copy
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
        case .copy:
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

    /// Best-effort removal of the item from BOTH the data-protection and legacy
    /// keychains. A sandboxed app's reads and writes can resolve to different stores,
    /// so a copy left in either one could shadow a freshly written value and make a
    /// "saved" key silently revert on the next launch. Benign not-found / missing-
    /// entitlement results are expected and ignored.
    private static func purgeFromAllKeychains(_ baseQuery: [String: Any]) {
        for query in [withDataProtectionKeychain(baseQuery), baseQuery] {
            let status = SecItemDelete(query as CFDictionary)
            if status != errSecSuccess,
               status != errSecItemNotFound,
               status != errSecMissingEntitlement {
                logDebug("KeychainManager: purge delete returned \(status)")
            }
        }
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

        let itemQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount
        ]

        // Clear any prior copy from both keychains so a stale value cannot shadow the new one.
        purgeFromAllKeychains(itemQuery)

        var addQuery = itemQuery
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked

        let status = addWithFallback(addQuery)
        guard status == errSecSuccess else {
            logError("KeychainManager: Failed to save API key (status: \(status))")
            return false
        }

        // Verify the value is actually retrievable and matches. The add and the load use
        // the same data-protection-then-legacy fallback, so a mismatch here means the
        // write landed in a store the load can't reach — surface it as a failure instead
        // of a false success that silently reverts on the next launch.
        guard loadAPIKey() == key else {
            logError("KeychainManager: API key save did not persist (readback mismatch)")
            return false
        }

        logInfo("KeychainManager: API key saved to keychain")
        return true
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
        purgeFromAllKeychains(query)

        // Confirm it's gone from every store the load can reach.
        guard loadAPIKey() == nil else {
            logError("KeychainManager: API key still present after delete")
            return false
        }
        logInfo("KeychainManager: API key deleted from keychain")
        return true
    }
}
