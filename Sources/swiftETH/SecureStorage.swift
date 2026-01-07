import Foundation
import Security
import LocalAuthentication

public enum SecureStorageError: Error, LocalizedError {
    case keychainError(OSStatus)
    case itemNotFound
    case authenticationFailed
    case invalidData
    case biometricsNotAvailable
    case duplicateItem
    
    public var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return "Keychain error: \(status) - \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown")"
        case .itemNotFound:
            return "Item not found in Keychain"
        case .authenticationFailed:
            return "Authentication failed - Touch ID or password required"
        case .invalidData:
            return "Invalid data in Keychain"
        case .biometricsNotAvailable:
            return "Touch ID not available on this device"
        case .duplicateItem:
            return "An account with this identifier already exists"
        }
    }
}

public struct SecureStorage {
    
    private static let service = "com.swiftETH.accounts"
    
    public static func save(
        privateKey: PrivateKey,
        identifier: String,
        label: String? = nil,
        requireBiometrics: Bool = true
    ) throws {
        let privateKeyData = privateKey.raw
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: privateKeyData
        ]
        
        if let label = label {
            query[kSecAttrLabel as String] = label
        }
        
        if requireBiometrics {
            guard biometricsAvailable() else {
                throw SecureStorageError.biometricsNotAvailable
            }
            
            let access = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [.biometryCurrentSet, .or, .devicePasscode],
                nil
            )
            
            if let access = access {
                query[kSecAttrAccessControl as String] = access
            }
        } else {
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            throw SecureStorageError.duplicateItem
        } else if status != errSecSuccess {
            throw SecureStorageError.keychainError(status)
        }
        
        Logger.shared.log("Private key saved to Keychain: \(identifier)")
    }
    
    public static func load(identifier: String, context: LAContext? = nil) throws -> PrivateKey {
        let authContext = context ?? LAContext()
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: authContext
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw SecureStorageError.itemNotFound
            } else if status == errSecUserCanceled {
                throw SecureStorageError.authenticationFailed
            } else {
                throw SecureStorageError.keychainError(status)
            }
        }
        
        guard let privateKeyData = result as? Data else {
            throw SecureStorageError.invalidData
        }
        
        Logger.shared.log("Private key loaded from Keychain: \(identifier)")
        return try PrivateKey(raw: privateKeyData)
    }
    
    public static func delete(identifier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStorageError.keychainError(status)
        }
        
        Logger.shared.log("Private key deleted from Keychain: \(identifier)")
    }
    
    public static func listAccounts() throws -> [(identifier: String, label: String?)] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return []
            }
            throw SecureStorageError.keychainError(status)
        }
        
        guard let items = result as? [[String: Any]] else {
            return []
        }
        
        return items.compactMap { item in
            guard let identifier = item[kSecAttrAccount as String] as? String else {
                return nil
            }
            let label = item[kSecAttrLabel as String] as? String
            return (identifier: identifier, label: label)
        }
    }
    
    public static func exists(identifier: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: identifier
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    public static func biometricsAvailable() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    public static func biometricsType() -> String? {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return nil
        }
        
        switch context.biometryType {
        case .touchID:
            return "Touch ID"
        case .faceID:
            return "Face ID"
        case .opticID:
            return "Optic ID"
        case .none:
            return nil
        @unknown default:
            return "Biometrics"
        }
    }
}

public extension Account {
    func saveToKeychain(
        identifier: String,
        label: String? = nil,
        requireBiometrics: Bool = true
    ) throws {
        try SecureStorage.save(
            privateKey: privateKey,
            identifier: identifier,
            label: label,
            requireBiometrics: requireBiometrics
        )
    }
    
    static func loadFromKeychain(identifier: String) throws -> Account {
        let privateKey = try SecureStorage.load(identifier: identifier)
        return try Account(privateKey: privateKey)
    }
    
    static func deleteFromKeychain(identifier: String) throws {
        try SecureStorage.delete(identifier: identifier)
    }
}
