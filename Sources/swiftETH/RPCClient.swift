import Foundation

public class RPCClient {
    public let url: URL
    
    public init(url: URL) {
        self.url = url
    }
    
    public convenience init(urlString: String) throws {
        guard let url = URL(string: urlString) else {
            throw RPCError.invalidURL
        }
        self.init(url: url)
    }
    
    public func call<T: Decodable>(method: String, params: [Any]) async throws -> T {
        let request = RPCRequest(
            id: Int.random(in: 1...Int.max),
            method: method,
            params: params
        )
        
        let requestBody = try JSONEncoder().encode(request)
        Logger.shared.log("RPC Call: \(method)")
        Logger.shared.log("RPC Params: \(String(data: requestBody, encoding: .utf8) ?? "Unable to encode")")
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = requestBody
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        Logger.shared.log("RPC Response status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        Logger.shared.log("RPC Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
        
        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.shared.log("Invalid HTTP response", level: .error)
            throw RPCError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            Logger.shared.log("HTTP error: \(httpResponse.statusCode)", level: .error)
            throw RPCError.httpError(statusCode: httpResponse.statusCode)
        }
        
        let rpcResponse = try JSONDecoder().decode(RPCResponse<T>.self, from: data)
        
        if let error = rpcResponse.error {
            Logger.shared.log("RPC error: code=\(error.code), message=\(error.message)", level: .error)
            throw RPCError.rpcError(code: error.code, message: error.message)
        }
        
        guard let result = rpcResponse.result else {
            Logger.shared.log("No result in RPC response", level: .error)
            throw RPCError.noResult
        }
        
        Logger.shared.log("RPC Call successful: \(method)")
        return result
    }
}

struct RPCRequest: Encodable {
    let jsonrpc = "2.0"
    let id: Int
    let method: String
    let params: [Any]
    
    enum CodingKeys: String, CodingKey {
        case jsonrpc, id, method, params
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(jsonrpc, forKey: .jsonrpc)
        try container.encode(id, forKey: .id)
        try container.encode(method, forKey: .method)
        
        var paramsContainer = container.nestedUnkeyedContainer(forKey: .params)
        for param in params {
            if let string = param as? String {
                try paramsContainer.encode(string)
            } else if let int = param as? Int {
                try paramsContainer.encode(int)
            } else if let bool = param as? Bool {
                try paramsContainer.encode(bool)
            } else if let dict = param as? [String: String] {
                var dictContainer = paramsContainer.nestedContainer(keyedBy: DynamicCodingKey.self)
                for (key, value) in dict {
                    try dictContainer.encode(value, forKey: DynamicCodingKey(stringValue: key)!)
                }
            } else {
                throw EncodingError.invalidValue(param, EncodingError.Context(codingPath: paramsContainer.codingPath, debugDescription: "Unsupported parameter type"))
            }
        }
    }
}

struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }
    
    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

struct RPCResponse<T: Decodable>: Decodable {
    let jsonrpc: String
    let id: Int?
    let result: T?
    let error: RPCErrorResponse?
}

struct RPCErrorResponse: Decodable {
    let code: Int
    let message: String
}

public enum RPCError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case rpcError(code: Int, message: String)
    case noResult
    case decodingError
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid RPC URL"
        case .invalidResponse:
            return "Invalid response from RPC server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .rpcError(let code, let message):
            return "RPC error \(code): \(message)"
        case .noResult:
            return "No result in RPC response"
        case .decodingError:
            return "Failed to decode RPC response"
        }
    }
}
