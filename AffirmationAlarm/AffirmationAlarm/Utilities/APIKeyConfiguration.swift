import Foundation
import Security

enum APIKeyConfiguration {
    private static let keychainKey = "com.affirmationalarm.anthropic-api-key"

    static func getAPIKey() -> String? {
        // Try Keychain first
        if let keychainValue = getFromKeychain() {
            return keychainValue
        }
        // Fall back to Config.plist
        if let plistValue = getFromPlist() {
            return plistValue
        }
        return nil
    }

    static func setAPIKey(_ key: String) {
        saveToKeychain(key)
    }

    // MARK: - Keychain

    private static func getFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func saveToKeychain(_ value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: keychainKey,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    // MARK: - Config.plist

    private static func getFromPlist() -> String? {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let key = dict["ANTHROPIC_API_KEY"] as? String,
              !key.isEmpty,
              key != "YOUR_API_KEY_HERE" else {
            return nil
        }
        return key
    }
}
