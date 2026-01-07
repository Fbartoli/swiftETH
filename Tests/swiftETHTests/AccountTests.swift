import XCTest
@testable import swiftETH

final class AccountTests: XCTestCase {
    func testAccountGeneration() throws {
        let account = try Account()
        
        XCTAssertEqual(account.privateKey.raw.count, 32)
        XCTAssertEqual(account.publicKey.raw.count, 65)
        XCTAssertEqual(account.address.raw.count, 20)
    }
    
    func testAccountFromPrivateKey() throws {
        let privateKeyHex = "0x" + String(repeating: "1", count: 64)
        let account = try swiftETH.accountFromPrivateKey(privateKeyHex)
        
        XCTAssertEqual(account.privateKey.toHex(), String(repeating: "1", count: 64))
    }
    
    func testAddressChecksumming() throws {
        let account = try Account()
        let checksummed = account.address.toChecksummed()
        
        XCTAssertTrue(checksummed.hasPrefix("0x"))
        XCTAssertEqual(checksummed.count, 42)
    }
    
    func testPrivateKeyToAddressConsistency() throws {
        // Generate random key and verify address derivation is consistent
        let account1 = try swiftETH.generateAccount()
        let privateKeyHex = account1.privateKey.toHexPrefixed()
        
        // Import the same private key
        let account2 = try swiftETH.accountFromPrivateKey(privateKeyHex)
        
        // Verify both accounts have the same address
        XCTAssertEqual(account1.address.raw, account2.address.raw)
        XCTAssertEqual(account1.address.toChecksummed(), account2.address.toChecksummed())
        XCTAssertEqual(account1.publicKey.raw, account2.publicKey.raw)
    }
}
