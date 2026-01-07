import XCTest
@testable import swiftETH

final class RPCClientTests: XCTestCase {
    var rpcClient: RPCClient!
    
    override func setUp() async throws {
        try await super.setUp()
        rpcClient = try RPCClient(urlString: "https://eth.llamarpc.com")
    }
    
    func testGetBlockNumber() async throws {
        let blockNumber = try await rpcClient.getBlockNumber()
        XCTAssertGreaterThan(blockNumber, 0, "Block number should be greater than 0")
        XCTAssertGreaterThan(blockNumber, 15_000_000, "Block number should be post-merge")
        print("✅ Current block number: \(blockNumber)")
    }
    
    func testGetBalance() async throws {
        let vitalikAddressStr = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
        guard let vitalikAddress = Address(hex: vitalikAddressStr) else {
            XCTFail("Failed to create address")
            return
        }
        let balance = try await rpcClient.getBalance(address: vitalikAddress)
        
        XCTAssertNotNil(balance, "Balance should not be nil")
        XCTAssertGreaterThanOrEqual(balance.toEther(), 0, "Balance should be non-negative")
        print("✅ Vitalik's balance: \(balance.formatted())")
    }
    
    func testGetTransactionCount() async throws {
        let vitalikAddressStr = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
        guard let vitalikAddress = Address(hex: vitalikAddressStr) else {
            XCTFail("Failed to create address")
            return
        }
        let nonce = try await rpcClient.getTransactionCount(address: vitalikAddress)
        
        XCTAssertGreaterThan(nonce, 0, "Vitalik should have sent at least one transaction")
        print("✅ Vitalik's nonce: \(nonce)")
    }
    
    func testGetTransactionCountForNewAddress() async throws {
        let newAccount = try swiftETH.generateAccount()
        let nonce = try await rpcClient.getTransactionCount(address: newAccount.address)
        
        XCTAssertEqual(nonce, 0, "New address should have nonce of 0")
        print("✅ New address nonce: \(nonce)")
    }
    
    func testGetGasPrice() async throws {
        let gasPrice = try await rpcClient.getGasPrice()
        
        XCTAssertGreaterThan(gasPrice, 0, "Gas price should be greater than 0")
        XCTAssertLessThan(gasPrice, 1_000_000_000_000, "Gas price should be reasonable")
        
        let gasPriceGwei = Double(gasPrice) / 1_000_000_000.0
        print("✅ Current gas price: \(String(format: "%.2f", gasPriceGwei)) gwei")
    }
    
    func testGetChainId() async throws {
        let chainId = try await rpcClient.getChainId()
        
        XCTAssertEqual(chainId, 1, "Should be connected to Ethereum mainnet (chain ID 1)")
        print("✅ Chain ID: \(chainId) (Ethereum Mainnet)")
    }
    
    func testGetTransactionReceipt() async throws {
        let knownTxHash = "0x260a96c30352f7774ae32353da5fb14b90cc38ecb5c3de7851e1a78f3acfe6ae"
        
        let receipt = try await rpcClient.getTransactionReceipt(txHash: knownTxHash)
        
        if let receipt = receipt {
            XCTAssertNotNil(receipt["transactionHash"], "Receipt should have transaction hash")
            XCTAssertNotNil(receipt["blockNumber"], "Receipt should have block number")
            XCTAssertNotNil(receipt["status"], "Receipt should have status")
            print("✅ Transaction receipt fetched successfully")
            print("   Block: \(receipt["blockNumber"] ?? "unknown")")
            print("   Status: \(receipt["status"] ?? "unknown")")
        } else {
            XCTFail("Expected to find transaction receipt for known transaction")
        }
    }
    
    func testInvalidRPCEndpoint() async throws {
        let invalidClient = try RPCClient(urlString: "https://invalid-rpc-endpoint-that-does-not-exist.com")
        
        do {
            _ = try await invalidClient.getBlockNumber()
            XCTFail("Should have thrown an error for invalid RPC endpoint")
        } catch {
            print("✅ Correctly throws error for invalid RPC endpoint: \(error)")
        }
    }
    
    func testAccountGetNonce() async throws {
        let account = try swiftETH.generateAccount()
        let nonce = try await account.getNonce(rpcClient: rpcClient)
        
        XCTAssertEqual(nonce, 0, "New account should have nonce of 0")
        print("✅ Account.getNonce() works correctly: \(nonce)")
    }
    
    func testAccountGetBalance() async throws {
        let vitalikAddressStr = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
        guard let vitalikAddress = Address(hex: vitalikAddressStr) else {
            XCTFail("Failed to create address")
            return
        }
        let account = try swiftETH.accountFromPrivateKey("0x1234567890123456789012345678901234567890123456789012345678901234")
        
        let balance = try await rpcClient.getBalance(address: vitalikAddress)
        
        XCTAssertGreaterThanOrEqual(balance.toEther(), 0, "Balance should be non-negative")
        print("✅ Account.getBalance() works correctly")
    }
}
