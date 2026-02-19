import Foundation
import Security

enum KeychainManager {
    private static let service = "co.blode.commandment"
    private static let apiKeyAccount = "OpenAIAPIKey"

    static func saveAPIKey(_ key: String) {
        guard let data = key.data(using: .utf8) else { return }

        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecUseDataProtectionKeychain as String: true
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: apiKeyAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecUseDataProtectionKeychain as String: true
        ]

        let status = SecItemAdd(addQuery as CFDictionary, nil)
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
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseDataProtectionKeychain as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

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
            kSecAttrAccount as String: apiKeyAccount,
            kSecUseDataProtectionKeychain as String: true
        ]
        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess {
            logInfo("KeychainManager: API key deleted from keychain")
        } else if status != errSecItemNotFound {
            logError("KeychainManager: Failed to delete API key (status: \(status))")
        }
    }
}
