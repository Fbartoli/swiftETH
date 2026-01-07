import Foundation
import swiftETH

// ⚠️  SECURITY WARNING ⚠️
// This test requires a funded Ethereum account for integration testing.
// 
// NEVER commit real private keys to version control!
// 
// To run this test:
// 1. Copy .env.example to .env
// 2. Add your test private key to .env file:
//    TEST_PRIVATE_KEY=0xYOUR_TESTNET_PRIVATE_KEY_HERE
// 3. Run: swift run swiftETHTest
//
// The .env file is in .gitignore and won't be committed.

print("⚠️  Transaction Integration Test")
print("⚠️  This test requires a funded test account")
print("")

// Load test private key from environment
guard let privateKey = Config.shared.testPrivateKey, !privateKey.isEmpty else {
    print("❌ No test private key configured")
    print("")
    print("To configure:")
    print("  1. Copy .env.example to .env")
    print("  2. Add your test private key:")
    print("     TEST_PRIVATE_KEY=0xYOUR_TESTNET_PRIVATE_KEY_HERE")
    print("  3. Run: swift run swiftETHTest")
    print("")
    print("⚠️  SECURITY WARNING:")
    print("   • Use testnet accounts only (Sepolia, Goerli, etc.)")
    print("   • NEVER use accounts with real funds")
    print("   • The .env file is already in .gitignore")
    print("")
    exit(1)
}

let recipientAddress = "0x71dE15F095f2790D4d82f4886b465Fb020C9CFF8"

do {
    Logger.shared.log("=== Starting Transaction Test ===")
    
    let account = try swiftETH.accountFromPrivateKey(privateKey)
    Logger.shared.log("Account: \(account.address.toChecksummed())")
    
    let rpcClient = try RPCClient(urlString: "https://eth.llamarpc.com")
    
    let balance = try await account.getBalance(rpcClient: rpcClient)
    Logger.shared.log("Balance: \(balance.formatted())")
    Logger.shared.log("Balance wei: \(balance.raw)")
    
    let gasPrice = try await rpcClient.getGasPrice()
    Logger.shared.log("Gas price: \(gasPrice)")
    
    let gasLimit: UInt64 = 21000
    let gasCost = gasPrice * gasLimit
    Logger.shared.log("Gas cost: \(gasCost) wei")
    
    let balanceDecimal = balance.toWeiDecimal()
    Logger.shared.log("Balance decimal: \(balanceDecimal)")
    
    let testValue: UInt64 = 10000000000  // 0.00000001 ETH
    Logger.shared.log("Test value: \(testValue) wei")
    
    let totalNeeded = testValue + gasCost
    Logger.shared.log("Total needed: \(totalNeeded) wei")
    
    guard let balanceUInt = UInt64(balanceDecimal), balanceUInt >= totalNeeded else {
        Logger.shared.log("Insufficient balance for transaction", level: .error)
        Logger.shared.log("Need: \(totalNeeded) wei, Have: \(balanceDecimal) wei", level: .error)
        exit(1)
    }
    
    guard let toAddress = Address(hex: recipientAddress) else {
        Logger.shared.log("Invalid recipient address", level: .error)
        exit(1)
    }
    Logger.shared.log("Sending to: \(toAddress.toChecksummed())")
    
    Logger.shared.log("Creating transaction...")
    let transaction = Transaction(
        nonce: 0,
        gasPrice: gasPrice,
        gasLimit: gasLimit,
        to: toAddress,
        value: testValue
    )
    
    Logger.shared.log("Signing transaction...")
    let signed = try transaction.sign(with: account.privateKey)
    
    Logger.shared.log("Encoded transaction hex: \(signed.toHex())")
    
    Logger.shared.log("Sending transaction...")
    let txHash = try await rpcClient.sendRawTransaction(signedTransaction: signed)
    Logger.shared.log("Transaction sent! Hash: \(txHash)")
    Logger.shared.log("=== Test completed successfully ===")
    
    print("\n✅ SUCCESS!")
    print("Transaction Hash: \(txHash)")
    print("View on Etherscan: https://etherscan.io/tx/\(txHash)")
    
} catch {
    Logger.shared.logError(error, context: "Test failed")
    print("\n❌ FAILED: \(error)")
    if let rpcError = error as? RPCError {
        print("RPC Error: \(rpcError.errorDescription ?? "Unknown")")
    }
    exit(1)
}
