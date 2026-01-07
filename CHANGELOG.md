# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial release of swiftETH library (formerly Web3Swift)
- Account generation with cryptographically secure random keys
- Private key import/export functionality
- Public key derivation using secp256k1
- Ethereum address derivation with Keccak-256
- EIP-55 checksumming for addresses
- Message signing with ECDSA
- Signature recovery (recover address from signature)
- Transaction creation and signing
- EIP-155 replay protection for transactions
- RLP encoding for transactions
- JSON-RPC client for Ethereum nodes
- Balance queries (`eth_getBalance`)
- Nonce management (`eth_getTransactionCount`)
- Gas price estimation (`eth_gasPrice`)
- Block number tracking (`eth_blockNumber`)
- Chain ID detection (`eth_chainId`)
- Transaction broadcasting (`eth_sendRawTransaction`)
- Transaction receipt fetching (`eth_getTransactionReceipt`)
- SwiftUI demo application for macOS
- Command-line example application
- Comprehensive unit test suite (36 tests)
- Integration tests with real Ethereum mainnet
- File-based logging system
- Complete documentation (README, ARCHITECTURE, TESTING, CONTRIBUTING)
- CI/CD pipeline with GitHub Actions
- Cursor AI development rules

### Developer Experience
- Type-safe APIs leveraging Swift's type system
- Async/await for all asynchronous operations
- Detailed error messages with LocalizedError conformance
- Inline documentation for all public APIs
- oxlib.sh-inspired architecture

### Security
- Secure random number generation using SecRandomCopyBytes
- No logging of sensitive data (private keys)
- Input validation for all cryptographic operations
- Thread-safe public APIs

## [0.1.0] - 2026-01-07

### Added
- Initial development version
- Core cryptographic primitives
- Basic RPC client functionality
- Transaction signing support
- Test suite foundation

[Unreleased]: https://github.com/yourusername/swiftETH/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/yourusername/swiftETH/releases/tag/v0.1.0
