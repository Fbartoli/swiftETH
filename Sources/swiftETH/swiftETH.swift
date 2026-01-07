import Foundation

public struct swiftETH {
    public static func generateAccount() throws -> Account {
        return try Account()
    }
    
    public static func accountFromPrivateKey(_ hex: String) throws -> Account {
        let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        guard let data = Data(hexString: cleaned) else {
            throw PrivateKeyError.invalidFormat
        }
        let privateKey = try PrivateKey(raw: data)
        return try Account(privateKey: privateKey)
    }
}
