import Foundation

public class Logger {
    public static let shared = Logger()
    
    private let logFileURL: URL
    private let fileHandle: FileHandle?
    private let queue = DispatchQueue(label: "com.web3swift.logger")
    
    private init() {
        let fileManager = FileManager.default
        let currentPath = fileManager.currentDirectoryPath
        let repoPath = URL(fileURLWithPath: currentPath)
        
        logFileURL = repoPath.appendingPathComponent("web3swift_debug.log")
        
        if !fileManager.fileExists(atPath: logFileURL.path) {
            fileManager.createFile(atPath: logFileURL.path, contents: nil, attributes: nil)
        }
        
        fileHandle = try? FileHandle(forWritingTo: logFileURL)
        fileHandle?.seekToEndOfFile()
        
        let initMessage = "=== Logger initialized at \(Date()) ===\nLog file: \(logFileURL.path)\n"
        if let data = initMessage.data(using: .utf8) {
            fileHandle?.write(data)
            fileHandle?.synchronizeFile()
        }
        print(initMessage.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    public func log(_ message: String, level: LogLevel = .info) {
        queue.async {
            let timestamp = DateFormatter.logFormatter.string(from: Date())
            let logMessage = "[\(timestamp)] [\(level.rawValue)] \(message)\n"
            
            if let data = logMessage.data(using: .utf8) {
                self.fileHandle?.write(data)
                self.fileHandle?.synchronizeFile()
            }
            
            print(logMessage.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
    
    public func logError(_ error: Error, context: String = "") {
        let message = context.isEmpty ? "\(error)" : "\(context): \(error)"
        log(message, level: .error)
        
        if let rpcError = error as? RPCError {
            log("RPC Error details: \(rpcError.errorDescription ?? "Unknown")", level: .error)
        }
    }
    
    public func getLogPath() -> String {
        return logFileURL.path
    }
    
    public func clearLogs() {
        queue.async {
            try? "".write(to: self.logFileURL, atomically: true, encoding: .utf8)
            self.fileHandle?.seekToEndOfFile()
            self.log("=== Logs cleared ===")
        }
    }
}

public enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()
}
