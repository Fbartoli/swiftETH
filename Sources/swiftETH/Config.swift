import Foundation

/// Configuration manager for swiftETH
/// Loads settings from environment variables or .env file
public struct Config {
    public static let shared = Config()
    
    private let environment: [String: String]
    
    private init() {
        var env = ProcessInfo.processInfo.environment
        
        // Try to load .env file if it exists
        if let envPath = Config.findEnvFile() {
            if let envVars = Config.loadEnvFile(at: envPath) {
                env.merge(envVars) { (_, new) in new }
            }
        }
        
        self.environment = env
    }
    
    // MARK: - RPC Configuration
    
    public var rpcURL: String {
        return get(key: "RPC_URL", default: "https://eth.llamarpc.com")
    }
    
    public var rpcURLTestnet: String {
        return get(key: "RPC_URL_TESTNET", default: "")
    }
    
    // MARK: - Network Configuration
    
    public var chainId: UInt64 {
        return UInt64(get(key: "CHAIN_ID", default: "1")) ?? 1
    }
    
    public var networkName: String {
        return get(key: "NETWORK_NAME", default: "mainnet")
    }
    
    // MARK: - Test Configuration
    
    public var testPrivateKey: String? {
        let key = get(key: "TEST_PRIVATE_KEY", default: "")
        return key.isEmpty ? nil : key
    }
    
    // MARK: - API Keys
    
    public var infuraAPIKey: String? {
        let key = get(key: "INFURA_API_KEY", default: "")
        return key.isEmpty ? nil : key
    }
    
    public var alchemyAPIKey: String? {
        let key = get(key: "ALCHEMY_API_KEY", default: "")
        return key.isEmpty ? nil : key
    }
    
    // MARK: - Gas Configuration
    
    public var defaultGasLimit: UInt64 {
        return UInt64(get(key: "DEFAULT_GAS_LIMIT", default: "21000")) ?? 21000
    }
    
    public var gasPriceMultiplier: Double {
        return Double(get(key: "GAS_PRICE_MULTIPLIER", default: "1.0")) ?? 1.0
    }
    
    // MARK: - Application Settings
    
    public var logLevel: String {
        return get(key: "LOG_LEVEL", default: "info")
    }
    
    public var debugMode: Bool {
        return get(key: "DEBUG_MODE", default: "false").lowercased() == "true"
    }
    
    // MARK: - Helper Methods
    
    private func get(key: String, default defaultValue: String) -> String {
        environment[key] ?? defaultValue
    }
    
    private static func findEnvFile() -> String? {
        let fileManager = FileManager.default
        let currentPath = fileManager.currentDirectoryPath
        
        // Check current directory
        let envPath = "\(currentPath)/.env"
        if fileManager.fileExists(atPath: envPath) {
            return envPath
        }
        
        // Check parent directories (up to 3 levels)
        var searchPath = currentPath
        for _ in 0..<3 {
            searchPath = (searchPath as NSString).deletingLastPathComponent
            let path = "\(searchPath)/.env"
            if fileManager.fileExists(atPath: path) {
                return path
            }
        }
        
        return nil
    }
    
    private static func loadEnvFile(at path: String) -> [String: String]? {
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }
        
        var env: [String: String] = [:]
        
        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            // Parse KEY=VALUE
            let parts = trimmed.components(separatedBy: "=")
            guard parts.count >= 2 else { continue }
            
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts.dropFirst().joined(separator: "=").trimmingCharacters(in: .whitespaces)
            
            // Remove quotes if present
            let cleanValue = value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            
            env[key] = cleanValue
        }
        
        return env
    }
}

// MARK: - Convenience Extensions

public extension RPCClient {
    /// Create RPC client using configuration
    static func fromConfig(testnet: Bool = false) throws -> RPCClient {
        let url = testnet ? Config.shared.rpcURLTestnet : Config.shared.rpcURL
        return try RPCClient(urlString: url)
    }
}
