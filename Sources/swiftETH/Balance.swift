import Foundation

public struct Balance {
    public let raw: String
    private let weiString: String
    
    public init(hex: String) throws {
        let cleaned = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        guard cleaned.allSatisfy({ $0.isHexDigit }) else {
            throw BalanceError.invalidHex
        }
        self.raw = hex.hasPrefix("0x") ? hex : "0x" + hex
        self.weiString = cleaned
    }
    
    public init(wei: String) {
        self.weiString = wei
        self.raw = wei.hasPrefix("0x") ? wei : "0x" + wei
    }
    
    private func hexToDecimal(_ hex: String) -> String {
        var result = [0]
        
        for char in hex.lowercased() {
            let digit: Int
            if let num = Int(String(char)) {
                digit = num
            } else if let ascii = char.asciiValue, ascii >= 97 && ascii <= 102 {
                digit = Int(ascii) - 87
            } else {
                continue
            }
            
            var carry = digit
            for i in 0..<result.count {
                let temp = result[i] * 16 + carry
                result[i] = temp % 10
                carry = temp / 10
            }
            
            while carry > 0 {
                result.append(carry % 10)
                carry /= 10
            }
        }
        
        return result.reversed().map { String($0) }.joined()
    }
    
    public func toEther() -> Double {
        let trimmed = weiString.trimmingCharacters(in: CharacterSet(charactersIn: "0"))
        if trimmed.isEmpty {
            return 0.0
        }
        
        let decimalWei = hexToDecimal(weiString)
        
        guard decimalWei.count <= 18 else {
            let splitIndex = decimalWei.index(decimalWei.endIndex, offsetBy: -18)
            let wholePart = String(decimalWei[..<splitIndex])
            let remainderPart = String(decimalWei[splitIndex...])
            let whole = Double(wholePart) ?? 0.0
            let remainder = Double(remainderPart) ?? 0.0
            return whole + remainder / 1_000_000_000_000_000_000.0
        }
        
        let padding = String(repeating: "0", count: max(0, 18 - decimalWei.count))
        let padded = padding + decimalWei
        let wholePart = Double(String(padded.prefix(padded.count - 18))) ?? 0.0
        let remainderPart = Double(String(padded.suffix(18))) ?? 0.0
        
        return wholePart + remainderPart / 1_000_000_000_000_000_000.0
    }
    
    public func formatted(decimals: Int = 6) -> String {
        let ether = toEther()
        if ether == 0.0 {
            return "0 ETH"
        }
        return String(format: "%.\(decimals)f ETH", ether)
    }
    
    public func formattedWei() -> String {
        return "\(weiString) wei"
    }
    
    public var isZero: Bool {
        return weiString.trimmingCharacters(in: CharacterSet(charactersIn: "0")).isEmpty
    }
    
    public func toWeiDecimal() -> String {
        return hexToDecimal(weiString)
    }
}

extension Character {
    var isHexDigit: Bool {
        return ("0"..."9").contains(self) || ("a"..."f").contains(self.lowercased())
    }
}

public enum BalanceError: Error {
    case invalidHex
    case rpcError(String)
}

extension RPCClient {
    public func getBalance(address: Address, block: String = "latest") async throws -> Balance {
        let addressHex = address.toHexPrefixed()
        let result: String = try await call(method: "eth_getBalance", params: [addressHex, block])
        return try Balance(hex: result)
    }
    
    public func getBlockNumber() async throws -> UInt64 {
        let result: String = try await call(method: "eth_blockNumber", params: [])
        let cleaned = result.hasPrefix("0x") ? String(result.dropFirst(2)) : result
        guard let blockNumber = UInt64(cleaned, radix: 16) else {
            throw RPCError.decodingError
        }
        return blockNumber
    }
    
    public func getTransactionCount(address: Address, block: String = "latest") async throws -> UInt64 {
        let addressHex = address.toHexPrefixed()
        let result: String = try await call(method: "eth_getTransactionCount", params: [addressHex, block])
        let cleaned = result.hasPrefix("0x") ? String(result.dropFirst(2)) : result
        guard let count = UInt64(cleaned, radix: 16) else {
            throw RPCError.decodingError
        }
        return count
    }
    
    public func sendRawTransaction(signedTransaction: SignedTransaction) async throws -> String {
        let hex = signedTransaction.toHex()
        let result: String = try await call(method: "eth_sendRawTransaction", params: [hex])
        return result
    }
    
    public func getGasPrice() async throws -> UInt64 {
        let result: String = try await call(method: "eth_gasPrice", params: [])
        let cleaned = result.hasPrefix("0x") ? String(result.dropFirst(2)) : result
        guard let gasPrice = UInt64(cleaned, radix: 16) else {
            throw RPCError.decodingError
        }
        return gasPrice
    }
    
    public func getChainId() async throws -> UInt64 {
        let result: String = try await call(method: "eth_chainId", params: [])
        let cleaned = result.hasPrefix("0x") ? String(result.dropFirst(2)) : result
        guard let chainId = UInt64(cleaned, radix: 16) else {
            throw RPCError.decodingError
        }
        return chainId
    }
    
    public func getTransactionReceipt(txHash: String) async throws -> [String: Any]? {
        struct AnyDecodable: Decodable {
            let value: Any
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let string = try? container.decode(String.self) {
                    value = string
                } else if let int = try? container.decode(Int.self) {
                    value = int
                } else if let bool = try? container.decode(Bool.self) {
                    value = bool
                } else {
                    value = "null"
                }
            }
        }
        
        do {
            let result: [String: AnyDecodable] = try await call(method: "eth_getTransactionReceipt", params: [txHash])
            return result.mapValues { $0.value }
        } catch RPCError.noResult {
            return nil
        }
    }
}
