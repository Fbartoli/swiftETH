import Foundation
import secp256k1

public struct Signature {
    public let r: Data
    public let s: Data
    public let v: UInt8
    
    public init(r: Data, s: Data, v: UInt8) {
        self.r = r
        self.s = s
        self.v = v
    }
    
    public init(raw: Data) throws {
        guard raw.count == 65 else {
            throw SignatureError.invalidLength
        }
        self.r = raw.prefix(32)
        self.s = raw.dropFirst(32).prefix(32)
        self.v = raw[64]
    }
    
    public func toHex() -> String {
        return (r + s + Data([v])).map { String(format: "%02x", $0) }.joined()
    }
    
    public func toHexPrefixed() -> String {
        return "0x" + toHex()
    }
    
    public var raw: Data {
        return r + s + Data([v])
    }
}

public enum SignatureError: Error {
    case invalidLength
    case signingFailed
    case recoveryFailed
    case invalidMessageHash
}

extension PrivateKey {
    public func sign(messageHash: Data) throws -> Signature {
        guard messageHash.count == 32 else {
            throw SignatureError.invalidMessageHash
        }
        
        guard let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)) else {
            throw SignatureError.signingFailed
        }
        defer {
            secp256k1_context_destroy(context)
        }
        
        var recoverableSignature = secp256k1_ecdsa_recoverable_signature()
        let privateKeyBytes = self.raw
        
        guard secp256k1_ecdsa_sign_recoverable(
            context,
            &recoverableSignature,
            messageHash.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) },
            privateKeyBytes.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) },
            nil,
            nil
        ) == 1 else {
            throw SignatureError.signingFailed
        }
        
        var signatureBytes = [UInt8](repeating: 0, count: 64)
        var recoveryId: Int32 = 0
        
        guard secp256k1_ecdsa_recoverable_signature_serialize_compact(
            context,
            &signatureBytes,
            &recoveryId,
            &recoverableSignature
        ) == 1 else {
            throw SignatureError.signingFailed
        }
        
        let r = Data(signatureBytes.prefix(32))
        let s = Data(signatureBytes.suffix(32))
        
        return Signature(r: r, s: s, v: UInt8(recoveryId + 27))
    }
}

extension Signature {
    public func recoverPublicKey(messageHash: Data) throws -> PublicKey {
        guard messageHash.count == 32 else {
            throw SignatureError.invalidMessageHash
        }
        
        guard let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_VERIFY)) else {
            throw SignatureError.recoveryFailed
        }
        defer {
            secp256k1_context_destroy(context)
        }
        
        var signature = secp256k1_ecdsa_recoverable_signature()
        let signatureBytes = r + s
        
        guard secp256k1_ecdsa_recoverable_signature_parse_compact(
            context,
            &signature,
            signatureBytes.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) },
            Int32(v - 27)
        ) == 1 else {
            throw SignatureError.recoveryFailed
        }
        
        var publicKey = secp256k1_pubkey()
        guard secp256k1_ecdsa_recover(
            context,
            &publicKey,
            &signature,
            messageHash.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) }
        ) == 1 else {
            throw SignatureError.recoveryFailed
        }
        
        var publicKeyBytes = [UInt8](repeating: 0, count: 65)
        var outputLength = 65
        
        guard secp256k1_ec_pubkey_serialize(
            context,
            &publicKeyBytes,
            &outputLength,
            &publicKey,
            UInt32(SECP256K1_EC_UNCOMPRESSED)
        ) == 1 else {
            throw SignatureError.recoveryFailed
        }
        
        return try PublicKey(raw: Data(publicKeyBytes))
    }
    
    public func recoverAddress(messageHash: Data) throws -> Address {
        let publicKey = try recoverPublicKey(messageHash: messageHash)
        return Address(publicKey: publicKey)
    }
}

extension PublicKey {
    public init(raw: Data) throws {
        guard raw.count == 65 else {
            throw PublicKeyError.serializationFailed
        }
        self.raw = raw
    }
}
