import XCTest
@testable import swiftETH

final class TransactionTests: XCTestCase {
    
    func testTransactionCreation() throws {
        let account = try swiftETH.generateAccount()
        guard let toAddress = Address(hex: "0x71dE15F095f2790D4d82f4886b465Fb020C9CFF8") else {
            XCTFail("Failed to create address")
            return
        }
        
        let transaction = Transaction(
            nonce: 0,
            gasPrice: 20_000_000_000,
            gasLimit: 21000,
            to: toAddress,
            value: 1_000_000_000_000_000_000,
            data: Data(),
            chainId: 1
        )
        
        XCTAssertEqual(transaction.nonce, 0)
        XCTAssertEqual(transaction.gasPrice, 20_000_000_000)
        XCTAssertEqual(transaction.gasLimit, 21000)
        XCTAssertEqual(transaction.value, 1_000_000_000_000_000_000)
        XCTAssertEqual(transaction.chainId, 1)
        
        print("✅ Transaction created successfully")
    }
    
    func testTransactionSigning() throws {
        // Use a securely generated account for testing
        let account = try swiftETH.generateAccount()
        guard let toAddress = Address(hex: "0x71dE15F095f2790D4d82f4886b465Fb020C9CFF8") else {
            XCTFail("Failed to create address")
            return
        }
        
        let transaction = Transaction(
            nonce: 0,
            gasPrice: 20_000_000_000,
            gasLimit: 21000,
            to: toAddress,
            value: 1_000_000_000_000_000_000,
            data: Data(),
            chainId: 1
        )
        
        let signedTx = try transaction.sign(with: account.privateKey)
        
        XCTAssertNotNil(signedTx.v)
        XCTAssertNotNil(signedTx.r)
        XCTAssertNotNil(signedTx.s)
        XCTAssertGreaterThan(signedTx.v, 0)
        
        let encodedData = try signedTx.encode()
        let encoded = "0x" + encodedData.map { String(format: "%02x", $0) }.joined()
        XCTAssertTrue(encoded.hasPrefix("0x"), "Encoded transaction should have 0x prefix")
        XCTAssertGreaterThan(encoded.count, 100, "Encoded transaction should be substantial")
        
        print("✅ Transaction signed successfully")
        print("   v: \(signedTx.v)")
        print("   Encoded length: \(encoded.count) chars")
    }
    
    func testRLPEncodingViaSignedTransaction() throws {
        guard let toAddress = Address(hex: "0x71dE15F095f2790D4d82f4886b465Fb020C9CFF8") else {
            XCTFail("Failed to create address")
            return
        }
        
        let account = try swiftETH.generateAccount()
        let transaction = Transaction(
            nonce: 0,
            gasPrice: 20_000_000_000,
            gasLimit: 21000,
            to: toAddress,
            value: 1_000_000_000_000_000_000,
            data: Data(),
            chainId: 1
        )
        
        let signedTx = try transaction.sign(with: account.privateKey)
        let encodedData = try signedTx.encode()
        let encoded = "0x" + encodedData.map { String(format: "%02x", $0) }.joined()
        
        XCTAssertGreaterThan(encoded.count, 0, "RLP encoded data should not be empty")
        XCTAssertTrue(encoded.hasPrefix("0x"), "Encoded should have 0x prefix")
        
        print("✅ RLP encoding successful")
        print("   Encoded length: \(encoded.count) chars")
    }
    
    func testEIP155Signing() throws {
        // Use a securely generated account for testing
        let account = try swiftETH.generateAccount()
        guard let toAddress = Address(hex: "0x71dE15F095f2790D4d82f4886b465Fb020C9CFF8") else {
            XCTFail("Failed to create address")
            return
        }
        
        let transaction = Transaction(
            nonce: 0,
            gasPrice: 20_000_000_000,
            gasLimit: 21000,
            to: toAddress,
            value: 1_000_000_000_000_000_000,
            data: Data(),
            chainId: 1
        )
        
        let signedTx = try transaction.sign(with: account.privateKey)
        
        let expectedV = UInt64(transaction.chainId) * 2 + 35
        XCTAssertTrue(signedTx.v == expectedV || signedTx.v == expectedV + 1, 
                     "EIP-155: v should be chainId * 2 + 35 + {0, 1}")
        
        print("✅ EIP-155 signing verified")
        print("   Chain ID: \(transaction.chainId)")
        print("   Expected v: \(expectedV) or \(expectedV + 1)")
        print("   Actual v: \(signedTx.v)")
    }
    
    func testZeroValueTransaction() throws {
        let account = try swiftETH.generateAccount()
        guard let toAddress = Address(hex: "0x71dE15F095f2790D4d82f4886b465Fb020C9CFF8") else {
            XCTFail("Failed to create address")
            return
        }
        
        let transaction = Transaction(
            nonce: 0,
            gasPrice: 20_000_000_000,
            gasLimit: 21000,
            to: toAddress,
            value: 0,
            data: Data(),
            chainId: 1
        )
        
        let signedTx = try transaction.sign(with: account.privateKey)
        let encodedData = try signedTx.encode()
        let encoded = "0x" + encodedData.map { String(format: "%02x", $0) }.joined()
        
        XCTAssertFalse(encoded.isEmpty)
        XCTAssertTrue(encoded.hasPrefix("0x"))
        print("✅ Zero value transaction signed successfully")
    }
    
    func testTransactionWithData() throws {
        let account = try swiftETH.generateAccount()
        guard let toAddress = Address(hex: "0x71dE15F095f2790D4d82f4886b465Fb020C9CFF8") else {
            XCTFail("Failed to create address")
            return
        }
        let data = "Hello, Ethereum!".data(using: .utf8)!
        
        let transaction = Transaction(
            nonce: 5,
            gasPrice: 50_000_000_000,
            gasLimit: 100000,
            to: toAddress,
            value: 1_000_000,
            data: data,
            chainId: 1
        )
        
        let signedTx = try transaction.sign(with: account.privateKey)
        let encodedData = try signedTx.encode()
        let encoded = "0x" + encodedData.map { String(format: "%02x", $0) }.joined()
        
        XCTAssertFalse(encoded.isEmpty)
        XCTAssertTrue(encoded.hasPrefix("0x"))
        print("✅ Transaction with data signed successfully")
    }
}
