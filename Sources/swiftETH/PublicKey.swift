import Foundation
import secp256k1

public struct PublicKey {
    public let raw: Data
    
    public init(privateKey: PrivateKey) throws {
        guard let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)) else {
            throw PublicKeyError.derivationFailed
        }
        defer {
            secp256k1_context_destroy(context)
        }
        
        let privateKeyBytes = privateKey.raw
        
        var publicKey = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_create(
            context,
            &publicKey,
            privateKeyBytes.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }
        ) == 1 else {
            throw PublicKeyError.derivationFailed
        }
        
        var outputLength: Int = 65
        var publicKeyBytes = [UInt8](repeating: 0, count: outputLength)
        
        guard secp256k1_ec_pubkey_serialize(
            context,
            &publicKeyBytes,
            &outputLength,
            &publicKey,
            UInt32(SECP256K1_EC_UNCOMPRESSED)
        ) == 1 else {
            throw PublicKeyError.serializationFailed
        }
        
        self.raw = Data(publicKeyBytes)
    }
    
    public func toHex() -> String {
        return raw.map { String(format: "%02x", $0) }.joined()
    }
    
    public func toHexPrefixed() -> String {
        return "0x" + toHex()
    }
}

public enum PublicKeyError: Error {
    case derivationFailed
    case serializationFailed
}
