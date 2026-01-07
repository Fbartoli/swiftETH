import Foundation
import Security

public struct PrivateKey {
    public let raw: Data
    
    public init(raw: Data) throws {
        guard raw.count == 32 else {
            throw PrivateKeyError.invalidLength
        }
        self.raw = raw
    }
    
    public init() throws {
        var randomBytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, 32, &randomBytes)
        
        guard status == errSecSuccess else {
            throw PrivateKeyError.generationFailed
        }
        
        self.raw = Data(randomBytes)
    }
    
    public func toHex() -> String {
        return raw.map { String(format: "%02x", $0) }.joined()
    }
    
    public func toHexPrefixed() -> String {
        return "0x" + toHex()
    }
}

public enum PrivateKeyError: Error {
    case invalidLength
    case generationFailed
    case invalidFormat
}
