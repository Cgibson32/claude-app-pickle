import Foundation
import Security

enum APIKeyConfiguration {
    private static let anthropicKeychainKey = "com.affirmationalarm.anthropic-api-key"
    private static let openAIKeychainKey = "com.affirmationalarm.openai-api-key"

    // MARK: - Anthropic (Claude)

    static func getAPIKey() -> String? {
        // Prefer build-time bundled key from Info.plist, fall back to Keychain.
        if let bundled = Bundle.main.object(forInfoDictionaryKey: "ANTHROPIC_API_KEY") as? String,
           !bundled.isEmpty, bundled != "$(ANTHROPIC_API_KEY)" {
            return bundled
        }
        return getFromKeychain(anthropicKeychainKey)
    }

    static func setAPIKey(_ key: String) {
        saveToKeychain(key, account: anthropicKeychainKey)
    }

    // MARK: - OpenAI (TTS)

    /// Bundled OpenAI API key — users do NOT configure this. The key is pulled
    /// from the Info.plist (injected at build time via an xcconfig / env var) or
    /// falls back to a Keychain entry for local development.
    ///
    /// Security note: bundling a key in an IPA means it can be extracted by a
    /// determined attacker. Accepted tradeoff here: OpenAI TTS is cheap (~$0.00004
    /// per morning) and rate limits cap abuse. Do NOT reuse this key for expensive
    /// endpoints (GPT-4, etc.).
    static var openAIKey: String? {
        if let bundled = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
           !bundled.isEmpty, bundled != "$(OPENAI_API_KEY)" {
            return bundled
        }
        return getFromKeychain(openAIKeychainKey)
    }

    static func setOpenAIKey(_ key: String) {
        saveToKeychain(key, account: openAIKeychainKey)
    }

    // MARK: - Keychain

    private static func getFromKeychain(_ account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func saveToKeychain(_ value: String, account: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
}
