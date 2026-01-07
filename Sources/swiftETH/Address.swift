import Foundation
import CryptoSwift

public struct Address {
    public let raw: Data
    
    public init(publicKey: PublicKey) {
        let publicKeyBytes = publicKey.raw
        
        let publicKeyWithoutPrefix = publicKeyBytes.dropFirst()
        
        let hash = publicKeyWithoutPrefix.sha3(.keccak256)
        
        let addressBytes = hash.suffix(20)
        self.raw = Data(addressBytes)
    }
    
    public init?(hex: String) {
        let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        guard let data = Data(hexString: cleaned), data.count == 20 else {
            return nil
        }
        self.raw = data
    }
    
    public func toHex() -> String {
        return raw.map { String(format: "%02x", $0) }.joined()
    }
    
    public func toHexPrefixed() -> String {
        return "0x" + toHex()
    }
    
    public func toChecksummed() -> String {
        let address = toHex()
        guard let addressData = address.data(using: .utf8) else {
            return toHexPrefixed()
        }
        let hash = addressData.sha3(.keccak256)
        let hashHex = hash.map { String(format: "%02x", $0) }.joined()
        
        var checksummed = "0x"
        for (index, char) in address.enumerated() {
            let hashChar = hashHex[hashHex.index(hashHex.startIndex, offsetBy: index)]
            if let intValue = Int(String(hashChar), radix: 16), intValue >= 8 {
                checksummed += String(char).uppercased()
            } else {
                checksummed += String(char).lowercased()
            }
        }
        
        return checksummed
    }
}

extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        var i = hexString.startIndex
        for _ in 0..<len {
            let j = hexString.index(i, offsetBy: 2)
            let bytes = hexString[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
}
