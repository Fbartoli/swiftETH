import Foundation
import swiftETH

print("=== Web3Swift Demo ===\n")

do {
    print("1. Generating new Ethereum account...\n")
    let account = try swiftETH.generateAccount()
    account.display()
    
    print("\n2. Testing with known private key...")
    let testPrivateKey = "0x" + String(repeating: "1", count: 64)
    let testAccount = try swiftETH.accountFromPrivateKey(testPrivateKey)
    print("Private Key: \(testAccount.privateKey.toHexPrefixed())")
    print("Public Key:  \(testAccount.publicKey.toHexPrefixed())")
    print("Address:    \(testAccount.address.toChecksummed())")
    
    print("\n3. Generating another random account...\n")
    let account2 = try swiftETH.generateAccount()
    account2.display()
    
} catch {
    print("Error: \(error)")
    exit(1)
}
