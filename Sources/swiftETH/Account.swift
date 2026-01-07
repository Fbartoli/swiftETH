import Foundation
import CryptoSwift

public struct Account {
    public let privateKey: PrivateKey
    public let publicKey: PublicKey
    public let address: Address
    
    public init() throws {
        let privateKey = try PrivateKey()
        let publicKey = try PublicKey(privateKey: privateKey)
        let address = Address(publicKey: publicKey)
        
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.address = address
    }
    
    public init(privateKey: PrivateKey) throws {
        let publicKey = try PublicKey(privateKey: privateKey)
        let address = Address(publicKey: publicKey)
        
        self.privateKey = privateKey
        self.publicKey = publicKey
        self.address = address
    }
    
    public func display() {
        print("=== Ethereum Account ===")
        print("Private Key: \(privateKey.toHexPrefixed())")
        print("Public Key:  \(publicKey.toHexPrefixed())")
        print("Address:     \(address.toChecksummed())")
        print("========================")
    }
    
    public func sign(messageHash: Data) throws -> Signature {
        return try privateKey.sign(messageHash: messageHash)
    }
    
    public func sign(message: String) throws -> Signature {
        let messageData = message.data(using: .utf8) ?? Data()
        let hash = messageData.sha3(.keccak256)
        return try sign(messageHash: hash)
    }
    
    public func getBalance(rpcClient: RPCClient) async throws -> Balance {
        return try await rpcClient.getBalance(address: address)
    }
    
    public func getNonce(rpcClient: RPCClient) async throws -> UInt64 {
        return try await rpcClient.getTransactionCount(address: address)
    }
    
    public func createTransaction(
        to: Address,
        value: UInt64,
        gasPrice: UInt64,
        gasLimit: UInt64 = 21000,
        nonce: UInt64? = nil,
        rpcClient: RPCClient? = nil
    ) async throws -> Transaction {
        let finalNonce: UInt64
        if let nonce = nonce {
            finalNonce = nonce
        } else if let client = rpcClient {
            finalNonce = try await client.getTransactionCount(address: address)
        } else {
            throw TransactionError.invalidNonce
        }
        
        return Transaction(
            nonce: finalNonce,
            gasPrice: gasPrice,
            gasLimit: gasLimit,
            to: to,
            value: value
        )
    }
    
    public func sendTransaction(
        to: Address,
        value: UInt64,
        rpcClient: RPCClient,
        gasPrice: UInt64? = nil,
        gasLimit: UInt64 = 21000
    ) async throws -> String {
        Logger.shared.log("=== Starting transaction send ===")
        Logger.shared.log("From: \(address.toChecksummed())")
        Logger.shared.log("To: \(to.toChecksummed())")
        Logger.shared.log("Value: \(value) wei (\(Double(value) / 1_000_000_000_000_000_000.0) ETH)")
        
        let finalGasPrice: UInt64
        if let price = gasPrice {
            finalGasPrice = price
            Logger.shared.log("Using provided gas price: \(price)")
        } else {
            Logger.shared.log("Fetching gas price from RPC...")
            finalGasPrice = try await rpcClient.getGasPrice()
            Logger.shared.log("Gas price: \(finalGasPrice)")
        }
        
        Logger.shared.log("Gas limit: \(gasLimit)")
        
        Logger.shared.log("Creating transaction...")
        let transaction = try await createTransaction(
            to: to,
            value: value,
            gasPrice: finalGasPrice,
            gasLimit: gasLimit,
            rpcClient: rpcClient
        )
        
        Logger.shared.log("Signing transaction...")
        let signed = try transaction.sign(with: privateKey)
        
        Logger.shared.log("Sending raw transaction...")
        let txHash = try await rpcClient.sendRawTransaction(signedTransaction: signed)
        Logger.shared.log("Transaction sent successfully! Hash: \(txHash)")
        Logger.shared.log("=== Transaction send complete ===")
        
        return txHash
    }
}
