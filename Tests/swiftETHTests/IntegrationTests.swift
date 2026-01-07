import XCTest
@testable import swiftETH

final class IntegrationTests: XCTestCase {
    
    func testFullAccountWorkflow() async throws {
        let rpcClient = try RPCClient(urlString: "https://eth.llamarpc.com")
        
        let account = try swiftETH.generateAccount()
        print("✅ Generated account: \(account.address.toChecksummed())")
        
        let balance = try await account.getBalance(rpcClient: rpcClient)
        print("✅ Balance: \(balance.formatted())")
        XCTAssertEqual(balance.toEther(), 0.0, "New account should have 0 balance")
        
        let nonce = try await account.getNonce(rpcClient: rpcClient)
        print("✅ Nonce: \(nonce)")
        XCTAssertEqual(nonce, 0, "New account should have nonce of 0")
        
        let message = "Test message"
        let signature = try account.sign(message: message)
        print("✅ Message signed: \(signature.toHexPrefixed())")
        
        let messageData = message.data(using: .utf8)!
        let messageHash = messageData.sha3(.keccak256)
        let recoveredAddress = try signature.recoverAddress(messageHash: messageHash)
        print("✅ Address recovered from signature")
        
        XCTAssertEqual(recoveredAddress.raw, account.address.raw, 
                      "Recovered address should match original")
        
        print("✅ Full workflow completed successfully!")
    }
    
    func testKnownAddressBalance() async throws {
        let rpcClient = try RPCClient(urlString: "https://eth.llamarpc.com")
        
        let knownAddresses = [
            ("Vitalik", "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"),
            ("Uniswap V2 Router", "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"),
            ("USDT Contract", "0xdAC17F958D2ee523a2206206994597C13D831ec7")
        ]
        
        for (name, addressStr) in knownAddresses {
            guard let address = Address(hex: addressStr) else {
                XCTFail("Failed to create address for \(name)")
                continue
            }
            let balance = try await rpcClient.getBalance(address: address)
            let nonce = try await rpcClient.getTransactionCount(address: address)
            
            print("✅ \(name):")
            print("   Address: \(addressStr)")
            print("   Balance: \(balance.formatted())")
            print("   Nonce: \(nonce)")
            
            XCTAssertGreaterThanOrEqual(balance.toEther(), 0, "\(name) should have non-negative balance")
        }
    }
    
    func testChainIdAndBlockNumber() async throws {
        let rpcClient = try RPCClient(urlString: "https://eth.llamarpc.com")
        
        let chainId = try await rpcClient.getChainId()
        let blockNumber = try await rpcClient.getBlockNumber()
        
        print("✅ Network info:")
        print("   Chain ID: \(chainId)")
        print("   Block Number: \(blockNumber)")
        
        XCTAssertEqual(chainId, 1, "Should be Ethereum mainnet")
        XCTAssertGreaterThan(blockNumber, 15_000_000, "Should be post-merge")
    }
    
    func testGasPriceRange() async throws {
        let rpcClient = try RPCClient(urlString: "https://eth.llamarpc.com")
        
        let gasPrice = try await rpcClient.getGasPrice()
        let gasPriceGwei = Double(gasPrice) / 1_000_000_000.0
        
        print("✅ Gas price: \(String(format: "%.2f", gasPriceGwei)) gwei")
        
        XCTAssertGreaterThan(gasPriceGwei, 0.01, "Gas price should be at least 0.01 gwei")
        XCTAssertLessThan(gasPriceGwei, 10000, "Gas price should be reasonable (< 10000 gwei)")
    }
    
    func testCreateAndSignTransaction() throws {
        // Use a securely generated account for testing
        let account = try swiftETH.generateAccount()
        
        print("✅ Account generated: \(account.address.toChecksummed())")
        
        guard let toAddress = Address(hex: "0x71dE15F095f2790D4d82f4886b465Fb020C9CFF8") else {
            XCTFail("Failed to create address")
            return
        }
        
        let transaction = Transaction(
            nonce: 0,
            gasPrice: 20_000_000_000,
            gasLimit: 21000,
            to: toAddress,
            value: 1_000_000_000,
            data: Data(),
            chainId: 1
        )
        
        let signedTx = try transaction.sign(with: account.privateKey)
        let encodedData = try signedTx.encode()
        let encoded = "0x" + encodedData.map { String(format: "%02x", $0) }.joined()
        
        print("✅ Transaction signed and encoded")
        print("   Encoded: \(encoded.prefix(66))...")
        
        XCTAssertTrue(encoded.hasPrefix("0xf8"), "Encoded transaction should start with RLP list marker")
        XCTAssertGreaterThan(encoded.count, 100, "Encoded transaction should be substantial")
    }
    
    func testMultipleAccountsHaveUniqueKeys() throws {
        var addresses = Set<String>()
        var privateKeys = Set<String>()
        
        for _ in 0..<10 {
            let account = try swiftETH.generateAccount()
            addresses.insert(account.address.toChecksummed())
            privateKeys.insert(account.privateKey.toHexPrefixed())
        }
        
        XCTAssertEqual(addresses.count, 10, "All addresses should be unique")
        XCTAssertEqual(privateKeys.count, 10, "All private keys should be unique")
        
        print("✅ Generated 10 unique accounts")
    }
}
