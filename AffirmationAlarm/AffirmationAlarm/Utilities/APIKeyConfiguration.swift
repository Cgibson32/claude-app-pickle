import Foundation
import Security

struct APIKeyConfiguration {
    private static let keychainService = "com.affirmationalarm.apikey"
    private static let keychainAccount = "anthropic_api_key"

    static func getAPIKey() -> String? {
        // 1. Check Keychain first (most secure)
        if let keychainKey = readFromKeychain() {
            return keychainKey
        }

        // 2. Fall back to Config.plist
        if let plistKey = readFromConfigPlist() {
            return plistKey
        }

        return nil
    }

    static func saveAPIKey(_ key: String) -> Bool {
        // Delete existing entry if any
        deleteFromKeychain()

        let data = Data(key.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func deleteAPIKey() {
        deleteFromKeychain()
    }

    static var hasAPIKey: Bool {
        getAPIKey() != nil
    }

    // MARK: - Private

    private static func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private static func deleteFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    private static func readFromConfigPlist() -> String? {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return nil
        }
        return plist["ANTHROPIC_API_KEY"] as? String
    }
}
