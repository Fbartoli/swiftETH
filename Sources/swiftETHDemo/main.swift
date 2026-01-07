import SwiftUI
import AppKit
import swiftETH
import CryptoSwift

@main
struct Web3SwiftDemoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 500)
        }
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 Web3Swift Demo launching...")
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApplication.shared.windows.first {
                window.center()
                window.makeKeyAndOrderFront(nil)
                window.level = .normal
                print("✅ Window should be visible now!")
                print("   If you don't see it, check your Dock or press Cmd+Tab")
            } else {
                print("⚠️  Window not found - this might take a moment")
            }
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }
}

struct ContentView: View {
    @StateObject private var viewModel = AccountViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            contentView
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.isRPCConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                        .opacity(viewModel.isRPCConnected ? 1.0 : 0.5)
                    
                    if let blockNumber = viewModel.currentBlockNumber {
                        Text("Block #\(blockNumber)")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary)
                    } else {
                        Text("Block #...")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
                
                Text("Web3Swift Demo")
                    .font(.system(size: 24, weight: .bold))
                Text("Generate Ethereum accounts and view keys")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: viewModel.generateNewAccount) {
                Label("Generate Account", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(20)
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let account = viewModel.currentAccount {
                    accountCard(account: account)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "signature")
                                .foregroundColor(.purple)
                            Text("Sign & Recover")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        
                        HStack {
                            TextField("Enter message to sign...", text: $viewModel.messageToSign)
                                .textFieldStyle(.roundedBorder)
                            
                            Button("Sign") {
                                viewModel.signMessage()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.messageToSign.isEmpty)
                        }
                        
                        if !viewModel.signatureHex.isEmpty {
                            KeyValueRow(
                                label: "Signature",
                                value: viewModel.signatureHex,
                                icon: "signature",
                                color: .purple
                            )
                            
                            if let recoveredAddress = viewModel.recoveredAddress {
                                HStack {
                                    Image(systemName: recoveredAddress == account.address.raw ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(recoveredAddress == account.address.raw ? .green : .red)
                                    Text(recoveredAddress == account.address.raw ? "Recovery successful!" : "Recovery failed")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(recoveredAddress == account.address.raw ? .green : .red)
                                }
                                .padding(.top, 4)
                            }
                        }
                        
                        if let error = viewModel.signingError {
                            Text(error)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                    }
                    .padding(20)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    
                    sendTransactionSection(account: account)
                } else {
                    emptyStateView
                }
                
                customPrivateKeySection
                
                rpcSettingsSection
            }
            .padding(20)
        }
    }
    
    private var rpcSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RPC Settings")
                .font(.system(size: 16, weight: .semibold))
            
            HStack {
                TextField("RPC Endpoint URL", text: $viewModel.rpcURL)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                
                Button("Save") {
                    viewModel.saveRPCSettings()
                }
                .buttonStyle(.bordered)
            }
            
            Text("Example: https://eth.llamarpc.com or https://rpc.ankr.com/eth")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            if let error = viewModel.rpcError {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func accountCard(account: Account) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Image(systemName: "key.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Ethereum Account")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Generated \(Date().formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Divider()
            
            KeyValueRow(
                label: "Address",
                value: account.address.toChecksummed(),
                icon: "wallet.pass.fill",
                color: .green
            )
            
            HStack {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundColor(.orange)
                    .frame(width: 16)
                Text("Balance")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                
                HStack(spacing: 4) {
                    if viewModel.isLoadingBalance {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Loading...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else if let balance = viewModel.balance {
                        Text(balance.formatted())
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                Button(viewModel.balance == nil ? "Load" : "Refresh") {
                    viewModel.loadBalance(for: account)
                    viewModel.loadNonce(for: account)
                }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            if let balance = viewModel.balance {
                Text(balance.formattedWei())
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.leading, 24)
            }
            
            HStack {
                Image(systemName: "number.circle.fill")
                    .foregroundColor(.cyan)
                    .frame(width: 16)
                Text("Nonce")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                
                HStack(spacing: 4) {
                    if viewModel.isLoadingNonce {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Loading...")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    } else if let nonce = viewModel.nonce {
                        Text("\(nonce)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.primary)
                    }
                    
                    Button(viewModel.nonce == nil ? "Load" : "Refresh") {
                        viewModel.loadNonce(for: account)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            KeyValueRow(
                label: "Public Key",
                value: account.publicKey.toHexPrefixed(),
                icon: "key.fill",
                color: .blue
            )
            
            KeyValueRow(
                label: "Private Key",
                value: account.privateKey.toHexPrefixed(),
                icon: "lock.fill",
                isSensitive: true,
                color: .red
            )
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No account generated")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
            Text("Click 'Generate Account' to create a new Ethereum account")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
    
    private func sendTransactionSection(account: Account) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.blue)
                Text("Send Ethereum")
                    .font(.system(size: 16, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("To Address")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                TextField("0x...", text: $viewModel.sendToAddress)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount (ETH)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    TextField("0.0", text: $viewModel.sendAmount)
                        .textFieldStyle(.roundedBorder)
                }
                
                Button("Send") {
                    viewModel.sendTransaction(from: account)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.sendToAddress.isEmpty || viewModel.sendAmount.isEmpty || viewModel.isSendingTransaction)
            }
            
            if viewModel.isSendingTransaction {
                HStack {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Sending transaction...")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            if let txHash = viewModel.lastTransactionHash {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Transaction Sent Successfully!")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.green)
                    }
                    
                    Text("Transaction Hash:")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(txHash)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.blue)
                        .textSelection(.enabled)
                    
                    Button("View on Etherscan") {
                        let url = URL(string: "https://etherscan.io/tx/\(txHash)")!
                        NSWorkspace.shared.open(url)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            }
            
            if let error = viewModel.sendError {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
            
            HStack {
                Text("Log file: \(Logger.shared.getLogPath())")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Button("View Logs") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: Logger.shared.getLogPath()).deletingLastPathComponent())
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var customPrivateKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Import from Private Key")
                .font(.system(size: 16, weight: .semibold))
            
            HStack {
                TextField("0x...", text: $viewModel.privateKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                
                Button("Import") {
                    viewModel.importFromPrivateKey()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.privateKeyInput.isEmpty)
            }
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.red)
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct KeyValueRow: View {
    let label: String
    let value: String
    let icon: String
    var isSensitive: Bool = false
    var color: Color = .blue
    
    @State private var copied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 16)
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: copyToClipboard) {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                        Text(copied ? "Copied!" : "Copy")
                    }
                    .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .foregroundColor(copied ? .green : color)
                .animation(.easeInOut(duration: 0.2), value: copied)
            }
            
            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isSensitive ? Color.red.opacity(0.1) : Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSensitive ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
        
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copied = false
        }
    }
}

class AccountViewModel: ObservableObject {
    @Published var currentAccount: Account?
    @Published var privateKeyInput: String = ""
    @Published var errorMessage: String?
    @Published var messageToSign: String = ""
    @Published var signatureHex: String = ""
    @Published var recoveredAddress: Data?
    @Published var signingError: String?
    @Published var balance: Balance?
    @Published var isLoadingBalance: Bool = false
    @Published var nonce: UInt64?
    @Published var isLoadingNonce: Bool = false
    @Published var rpcURL: String = "https://eth.llamarpc.com"
    @Published var rpcError: String?
    @Published var currentBlockNumber: UInt64?
    @Published var isRPCConnected: Bool = false
    @Published var sendToAddress: String = ""
    @Published var sendAmount: String = ""
    @Published var isSendingTransaction: Bool = false
    @Published var lastTransactionHash: String?
    @Published var sendError: String?
    
    private var rpcClient: RPCClient?
    private var blockNumberTask: Task<Void, Never>?
    
    init() {
        Logger.shared.log("=== App initialized ===")
        Logger.shared.log("Log file location: \(Logger.shared.getLogPath())")
        loadRPCSettings()
        loadTestAccount()
    }
    
    private func loadTestAccount() {
        // No longer auto-loading test account for security
        // User must generate or import their own account
        Logger.shared.log("Demo started - user must generate or import account")
    }
    
    private func loadRPCSettings() {
        if let savedURL = UserDefaults.standard.string(forKey: "rpcURL"), !savedURL.isEmpty {
            rpcURL = savedURL
        }
        updateRPCClient()
    }
    
    func saveRPCSettings() {
        UserDefaults.standard.set(rpcURL, forKey: "rpcURL")
        updateRPCClient()
        rpcError = nil
    }
    
    private func updateRPCClient() {
        blockNumberTask?.cancel()
        blockNumberTask = nil
        
        do {
            rpcClient = try RPCClient(urlString: rpcURL)
            rpcError = nil
            startBlockNumberMonitoring()
        } catch {
            rpcError = "Invalid RPC URL: \(error.localizedDescription)"
            isRPCConnected = false
            currentBlockNumber = nil
        }
    }
    
    private func startBlockNumberMonitoring() {
        guard let client = rpcClient else { return }
        
        blockNumberTask = Task {
            while !Task.isCancelled {
                do {
                    let blockNumber = try await client.getBlockNumber()
                    await MainActor.run {
                        self.currentBlockNumber = blockNumber
                        self.isRPCConnected = true
                        self.rpcError = nil
                    }
                } catch {
                    await MainActor.run {
                        self.isRPCConnected = false
                        self.rpcError = "RPC error: \(error.localizedDescription)"
                    }
                }
                
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }
    
    func loadBalance(for account: Account) {
        guard let client = rpcClient else {
            rpcError = "Please configure a valid RPC endpoint"
            return
        }
        
        isLoadingBalance = true
        rpcError = nil
        
        Task {
            do {
                let balance = try await account.getBalance(rpcClient: client)
                    await MainActor.run {
                        self.balance = balance
                        self.isLoadingBalance = false
                    }
            } catch {
                await MainActor.run {
                    self.rpcError = "Failed to load balance: \(error.localizedDescription)"
                    self.isLoadingBalance = false
                }
            }
        }
    }
    
    func loadNonce(for account: Account) {
        guard let client = rpcClient else {
            return
        }
        
        isLoadingNonce = true
        
        Task {
            do {
                let nonceValue = try await account.getNonce(rpcClient: client)
                await MainActor.run {
                    self.nonce = nonceValue
                    self.isLoadingNonce = false
                }
                Logger.shared.log("Nonce loaded: \(nonceValue)")
            } catch {
                await MainActor.run {
                    self.isLoadingNonce = false
                }
                Logger.shared.log("Failed to load nonce: \(error)", level: .error)
            }
        }
    }
    
    
    func generateNewAccount() {
        do {
            currentAccount = try swiftETH.generateAccount()
            errorMessage = nil
            clearSigningState()
            balance = nil
        } catch {
            errorMessage = "Failed to generate account: \(error.localizedDescription)"
        }
    }
    
    func importFromPrivateKey() {
        errorMessage = nil
        do {
            let account = try swiftETH.accountFromPrivateKey(privateKeyInput)
            currentAccount = account
            privateKeyInput = ""
            clearSigningState()
            balance = nil
        } catch {
            errorMessage = "Invalid private key: \(error.localizedDescription)"
        }
    }
    
    deinit {
        blockNumberTask?.cancel()
    }
    
    func signMessage() {
        guard let account = currentAccount else { return }
        signingError = nil
        recoveredAddress = nil
        signatureHex = ""
        
        do {
            let signature = try account.sign(message: messageToSign)
            self.signatureHex = signature.toHexPrefixed()
            
            let messageData = messageToSign.data(using: .utf8)!
            let messageHash = messageData.sha3(.keccak256)
            let recovered = try signature.recoverAddress(messageHash: messageHash)
            recoveredAddress = recovered.raw
        } catch {
            signingError = "Signing failed: \(error.localizedDescription)"
        }
    }
    
    private func clearSigningState() {
        signatureHex = ""
        recoveredAddress = nil
        signingError = nil
        messageToSign = ""
    }
    
    func sendTransaction(from account: Account) {
        Logger.shared.log("=== User initiated transaction send ===")
        Logger.shared.log("To address input: \(sendToAddress)")
        Logger.shared.log("Amount input: \(sendAmount)")
        
        guard let client = rpcClient else {
            Logger.shared.log("No RPC client configured", level: .error)
            sendError = "Please configure a valid RPC endpoint"
            return
        }
        
        guard let toAddress = Address(hex: sendToAddress) else {
            Logger.shared.log("Invalid recipient address: \(sendToAddress)", level: .error)
            sendError = "Invalid recipient address"
            return
        }
        
        guard let ethAmount = Double(sendAmount), ethAmount > 0 else {
            Logger.shared.log("Invalid amount: \(sendAmount)", level: .error)
            sendError = "Invalid amount"
            return
        }
        
        let weiAmount = UInt64(ethAmount * 1_000_000_000_000_000_000.0)
        Logger.shared.log("Converted amount: \(weiAmount) wei")
        
        isSendingTransaction = true
        sendError = nil
        lastTransactionHash = nil
        
        Task {
            do {
                Logger.shared.log("Checking balance before sending...")
                let currentBalance = try await account.getBalance(rpcClient: client)
                Logger.shared.log("Current balance: \(currentBalance.formatted())")
                
                let gasPrice = try await client.getGasPrice()
                let estimatedGas = 21000
                let gasCost = gasPrice * UInt64(estimatedGas)
                Logger.shared.log("Gas price: \(gasPrice), Gas limit: \(estimatedGas), Total gas cost: \(gasCost) wei")
                
                let balanceDecimal = currentBalance.toWeiDecimal()
                let totalNeeded = weiAmount + gasCost
                
                Logger.shared.log("Balance check: have \(balanceDecimal) wei, need \(totalNeeded) wei")
                
                guard let balanceUInt = UInt64(balanceDecimal), balanceUInt >= totalNeeded else {
                    let needed = Double(totalNeeded) / 1_000_000_000_000_000_000.0
                    let have = currentBalance.toEther()
                    Logger.shared.log("Insufficient balance! Need \(needed) ETH, have \(have) ETH", level: .error)
                    await MainActor.run {
                        self.sendError = "Insufficient balance. Need \(String(format: "%.8f", needed)) ETH (value + gas), have \(String(format: "%.8f", have)) ETH"
                        self.isSendingTransaction = false
                    }
                    return
                }
                
                Logger.shared.log("Balance check passed. Proceeding with transaction...")
                
                let txHash = try await account.sendTransaction(
                    to: toAddress,
                    value: weiAmount,
                    rpcClient: client
                )
                await MainActor.run {
                    self.lastTransactionHash = txHash
                    self.isSendingTransaction = false
                    self.sendToAddress = ""
                    self.sendAmount = ""
                    self.balance = nil
                    self.nonce = nil
                }
                
                loadBalance(for: account)
                loadNonce(for: account)
            } catch {
                Logger.shared.logError(error, context: "Transaction send failed")
                await MainActor.run {
                    let errorMessage: String
                    if let rpcError = error as? RPCError {
                        errorMessage = rpcError.errorDescription ?? rpcError.localizedDescription
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    self.sendError = "Failed to send transaction: \(errorMessage)"
                    self.isSendingTransaction = false
                }
            }
        }
    }
}
