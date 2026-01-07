# swiftETH

A modern Swift library for Ethereum and Web3 functionality.

## Features

- ✅ Private key generation (cryptographically secure)
- ✅ Public key derivation (secp256k1)
- ✅ Ethereum address derivation (Keccak-256)
- ✅ Address checksumming (EIP-55)
- ✅ Message signing and signature recovery
- ✅ JSON-RPC client for Ethereum nodes
- ✅ Balance reading (`eth_getBalance`)
- ✅ Nonce reading (`eth_getTransactionCount`)
- ✅ Transaction sending with EIP-155 signing
- ✅ RLP encoding for transactions

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/swiftETH.git", from: "0.1.0")
]
```

## Usage

### Generate a new account

```swift
import swiftETH

let account = try swiftETH.generateAccount()
account.display()
// Output:
// === Ethereum Account ===
// Private Key: 0x...
// Public Key:  0x...
// Address:     0x...
// ========================
```

### Create account from existing private key

```swift
let account = try swiftETH.accountFromPrivateKey("0x1111...")
print(account.address.toChecksummed()) // EIP-55 checksummed address
print(account.publicKey.toHexPrefixed()) // 0x04... (uncompressed)
```

### Access individual components

```swift
let account = try swiftETH.generateAccount()

// Private key (32 bytes)
let privateKeyHex = account.privateKey.toHexPrefixed() // "0x..."

// Public key (65 bytes, uncompressed)
let publicKeyHex = account.publicKey.toHexPrefixed() // "0x04..."

// Ethereum address (20 bytes)
let address = account.address.toChecksummed() // EIP-55 format
let addressLower = account.address.toHexPrefixed() // lowercase
```

### Sign messages and recover addresses

```swift
let account = try swiftETH.generateAccount()

// Sign a message
let signature = try account.sign(message: "Hello, Web3!")

// Recover address from signature
let messageData = "Hello, Web3!".data(using: .utf8)!
let messageHash = messageData.sha3(.keccak256)
let recoveredAddress = try signature.recoverAddress(messageHash: messageHash)

// Verify recovery matches original
assert(recoveredAddress.raw == account.address.raw)
```

### Read balance and nonce from Ethereum node

```swift
// Create RPC client
let rpcClient = try RPCClient(urlString: "https://eth.llamarpc.com")

// Get balance
let account = try swiftETH.generateAccount()
let balance = try await account.getBalance(rpcClient: rpcClient)

print(balance.formatted()) // "0.0 ETH"
print(balance.formattedWei()) // "0 wei"
print(balance.toEther()) // 0.0

// Get nonce (transaction count)
let nonce = try await account.getNonce(rpcClient: rpcClient)
print("Nonce: \(nonce)") // Number of transactions sent from this address
```

## Testing

Run the comprehensive test suite:

```bash
# Run all 36 tests
swift test

# Run specific test suites
swift test --filter RPCClientTests
swift test --filter TransactionTests
```

See [TESTING.md](TESTING.md) for detailed testing documentation.

## Run Examples

### Command Line Example

```bash
swift run swiftETHExample
```

### Interactive UI Demo

Launch the SwiftUI macOS demo app:

**Option 1: Direct run (recommended)**
```bash
swift run swiftETHDemo
```
*Note: The app window should appear. If it doesn't, try Option 2.*

**Option 2: Using the launcher script**
```bash
./launch-demo.sh
```

**Option 3: Build and run manually**
```bash
swift build --product swiftETHDemo
.build/debug/swiftETHDemo
```

The app window should appear with the demo interface. If the window doesn't appear, check:
- Make sure you're on macOS 12+ 
- The app might be running in the background - check your Dock
- Try clicking the app icon in the Dock if it appears there

The demo app provides:
- **Generate Account** button to create new Ethereum accounts
- Display of Address, Public Key, and Private Key
- Copy-to-clipboard functionality for each field
- Import from private key feature
- Modern, clean macOS interface

## Requirements

- Swift 5.9+
- macOS 12+ or iOS 15+

## Dependencies

- [secp256k1.swift](https://github.com/Boilertalk/secp256k1.swift) - Elliptic curve cryptography
- [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift) - Keccak-256 hashing

## Configuration

swiftETH uses environment variables for configuration:

```bash
# Copy the example configuration
cp .env.example .env

# Edit with your settings
nano .env
```

See [ENV.md](ENV.md) for detailed configuration options.

**Quick start:**
```bash
# .env file
RPC_URL=https://eth.llamarpc.com
TEST_PRIVATE_KEY=0xYOUR_TESTNET_KEY  # Optional, for testing only
```

**Usage in code:**
```swift
// Use configured RPC
let rpcClient = try RPCClient.fromConfig()

// Access configuration
let chainId = Config.shared.chainId
```

## Architecture

swiftETH is inspired by [oxlib.sh](https://oxlib.sh/) and follows its modular, composable design philosophy. See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed documentation.

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License - See LICENSE file for details
