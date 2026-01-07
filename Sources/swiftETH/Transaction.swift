import Foundation
import secp256k1
import CryptoSwift

public struct Transaction {
    public let nonce: UInt64
    public let gasPrice: UInt64
    public let gasLimit: UInt64
    public let to: Address
    public let value: UInt64
    public let data: Data
    public let chainId: UInt64
    
    public init(
        nonce: UInt64,
        gasPrice: UInt64,
        gasLimit: UInt64,
        to: Address,
        value: UInt64,
        data: Data = Data(),
        chainId: UInt64 = 1
    ) {
        self.nonce = nonce
        self.gasPrice = gasPrice
        self.gasLimit = gasLimit
        self.to = to
        self.value = value
        self.data = data
        self.chainId = chainId
    }
    
    public func sign(with privateKey: PrivateKey) throws -> SignedTransaction {
        Logger.shared.log("Signing transaction: nonce=\(nonce), to=\(to.toHexPrefixed()), value=\(value)")
        let rlp = try encodeRLP()
        Logger.shared.log("RLP encoded length: \(rlp.count) bytes")
        Logger.shared.log("RLP hex: \(rlp.map { String(format: "%02x", $0) }.joined())")
        let hash = rlp.sha3(.keccak256)
        Logger.shared.log("Transaction hash: \(hash.map { String(format: "%02x", $0) }.joined())")
        
        guard let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)) else {
            throw TransactionError.signingFailed
        }
        defer {
            secp256k1_context_destroy(context)
        }
        
        var recoverableSignature = secp256k1_ecdsa_recoverable_signature()
        let privateKeyBytes = privateKey.raw
        
        guard secp256k1_ecdsa_sign_recoverable(
            context,
            &recoverableSignature,
            hash.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) },
            privateKeyBytes.withUnsafeBytes { $0.baseAddress!.assumingMemoryBound(to: UInt8.self) },
            nil,
            nil
        ) == 1 else {
            throw TransactionError.signingFailed
        }
        
        var signatureBytes = [UInt8](repeating: 0, count: 64)
        var recoveryId: Int32 = 0
        
        guard secp256k1_ecdsa_recoverable_signature_serialize_compact(
            context,
            &signatureBytes,
            &recoveryId,
            &recoverableSignature
        ) == 1 else {
            throw TransactionError.signingFailed
        }
        
        let r = Data(signatureBytes.prefix(32))
        let s = Data(signatureBytes.suffix(32))
        let v = UInt8(recoveryId) + UInt8(chainId * 2) + 35
        
        let signed = SignedTransaction(
            transaction: self,
            r: r,
            s: s,
            v: v
        )
        Logger.shared.log("Transaction signed: v=\(v), r=\(r.map { String(format: "%02x", $0) }.joined().prefix(16))..., s=\(s.map { String(format: "%02x", $0) }.joined().prefix(16))...)")
        return signed
    }
    
    private func encodeRLP() throws -> Data {
        var items: [RLPItem] = []
        
        items.append(.uint(nonce))
        items.append(.uint(gasPrice))
        items.append(.uint(gasLimit))
        items.append(.data(to.raw))
        items.append(.uint(value))
        items.append(.data(data))
        items.append(.uint(chainId))
        items.append(.uint(0))
        items.append(.uint(0))
        
        let encoded = try encodeRLPItems(items: items)
        
        if encoded.count < 56 {
            var result = Data()
            result.append(0xc0 + UInt8(encoded.count))
            result.append(encoded)
            return result
        } else {
            let lengthBytes = encodeLength(encoded.count)
            var result = Data()
            result.append(0xf7 + UInt8(lengthBytes.count))
            result.append(lengthBytes)
            result.append(encoded)
            return result
        }
    }
}

public struct SignedTransaction {
    public let transaction: Transaction
    public let r: Data
    public let s: Data
    public let v: UInt8
    
    public func encode() throws -> Data {
        var items: [RLPItem] = []
        
        items.append(.uint(transaction.nonce))
        items.append(.uint(transaction.gasPrice))
        items.append(.uint(transaction.gasLimit))
        items.append(.data(transaction.to.raw))
        items.append(.uint(transaction.value))
        items.append(.data(transaction.data))
        items.append(.uint(UInt64(v)))
        items.append(.data(r))
        items.append(.data(s))
        
        let encoded = try encodeRLPItems(items: items)
        
        if encoded.count < 56 {
            var result = Data()
            result.append(0xc0 + UInt8(encoded.count))
            result.append(encoded)
            return result
        } else {
            let lengthBytes = encodeLength(encoded.count)
            var result = Data()
            result.append(0xf7 + UInt8(lengthBytes.count))
            result.append(lengthBytes)
            result.append(encoded)
            return result
        }
    }
    
    public func toHex() -> String {
        do {
            let encoded = try encode()
            let hex = "0x" + encoded.map { String(format: "%02x", $0) }.joined()
            Logger.shared.log("Signed transaction hex length: \(hex.count) chars")
            Logger.shared.log("Signed transaction hex (first 100 chars): \(String(hex.prefix(100)))...")
            return hex
        } catch {
            Logger.shared.logError(error, context: "Failed to encode signed transaction")
            return ""
        }
    }
}

enum RLPItem {
    case data(Data)
    case uint(UInt64)
    case list([RLPItem])
}

func encodeRLPItems(items: [RLPItem]) throws -> Data {
    var result = Data()
    
    for item in items {
        switch item {
        case .data(let data):
            if data.isEmpty {
                result.append(0x80)
            } else if data.count == 1 && data[0] < 0x80 {
                result.append(data[0])
            } else if data.count < 56 {
                result.append(0x80 + UInt8(data.count))
                result.append(data)
            } else {
                let lengthBytes = encodeLength(data.count)
                result.append(0xb7 + UInt8(lengthBytes.count))
                result.append(lengthBytes)
                result.append(data)
            }
            
        case .uint(let value):
            let bytes = valueToBytes(value)
            if bytes.isEmpty {
                result.append(0x80)
            } else if bytes.count == 1 && bytes[0] < 0x80 {
                result.append(bytes[0])
            } else {
                result.append(0x80 + UInt8(bytes.count))
                result.append(bytes)
            }
            
        case .list(let list):
            let encoded = try encodeRLPItems(items: list)
            if encoded.count < 56 {
                result.append(0xc0 + UInt8(encoded.count))
                result.append(encoded)
            } else {
                let lengthBytes = encodeLength(encoded.count)
                result.append(0xf7 + UInt8(lengthBytes.count))
                result.append(lengthBytes)
                result.append(encoded)
            }
        }
    }
    
    return result
}

func valueToBytes(_ value: UInt64) -> Data {
    if value == 0 {
        return Data()
    }
    var result = Data()
    var v = value
    while v > 0 {
        result.insert(UInt8(v & 0xff), at: 0)
        v >>= 8
    }
    return result
}

func encodeLength(_ length: Int) -> Data {
    var result = Data()
    var len = length
    while len > 0 {
        result.insert(UInt8(len & 0xff), at: 0)
        len >>= 8
    }
    return result
}

public enum TransactionError: Error {
    case signingFailed
    case encodingFailed
    case invalidNonce
    case invalidGasPrice
    case invalidGasLimit
}
