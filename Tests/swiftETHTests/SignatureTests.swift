import XCTest
@testable import swiftETH
import CryptoSwift

final class SignatureTests: XCTestCase {
    func testSignAndRecover() throws {
        let account = try Account()
        let message = "Hello, Web3!"
        let messageData = message.data(using: .utf8)!
        let messageHash = messageData.sha3(.keccak256)
        
        let signature = try account.sign(messageHash: messageHash)
        
        XCTAssertEqual(signature.r.count, 32)
        XCTAssertEqual(signature.s.count, 32)
        XCTAssertTrue(signature.v >= 27 && signature.v <= 30)
        
        let recoveredPublicKey = try signature.recoverPublicKey(messageHash: messageHash)
        XCTAssertEqual(recoveredPublicKey.raw, account.publicKey.raw)
        
        let recoveredAddress = try signature.recoverAddress(messageHash: messageHash)
        XCTAssertEqual(recoveredAddress.raw, account.address.raw)
    }
    
    func testSignMessageString() throws {
        let account = try Account()
        let message = "Test message"
        
        let signature = try account.sign(message: message)
        
        let messageData = message.data(using: .utf8)!
        let messageHash = messageData.sha3(.keccak256)
        
        let recoveredAddress = try signature.recoverAddress(messageHash: messageHash)
        XCTAssertEqual(recoveredAddress.raw, account.address.raw)
    }
    
    func testSignAndRecoverDeterministic() throws {
        // Use a securely generated key for testing
        let account = try swiftETH.generateAccount()
        
        let messageHash = Data(hexString: "0x" + String(repeating: "1", count: 64))!
        let signature = try account.sign(messageHash: messageHash)
        
        let recoveredAddress = try signature.recoverAddress(messageHash: messageHash)
        XCTAssertEqual(recoveredAddress.raw, account.address.raw, "Recovered address should match original")
        
        let recoveredPublicKey = try signature.recoverPublicKey(messageHash: messageHash)
        XCTAssertEqual(recoveredPublicKey.raw, account.publicKey.raw, "Recovered public key should match original")
    }
}

extension Data {
    init?(hexString: String) {
        let cleaned = hexString.hasPrefix("0x") ? String(hexString.dropFirst(2)) : hexString
        let len = cleaned.count / 2
        var data = Data(capacity: len)
        var i = cleaned.startIndex
        for _ in 0..<len {
            let j = cleaned.index(i, offsetBy: 2)
            let bytes = cleaned[i..<j]
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
