//
//  reliefNodeApp.swift
//  reliefNode
//
//  Created by Prannvat Singh on 26/10/2024.
//

import SwiftUI
import UIKit
import CoinbaseWalletSDK

class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.swizzleOpenURL()
        
        #warning("Should use universal links in production")
        CoinbaseWalletSDK.configure(
//            host: URL(string: "samplewallet://wsegue")!,
            callback: URL(string: "reliefNode://")!
        )
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if (try? CoinbaseWalletSDK.shared.handleResponse(url)) == true {
            return true
        }
        // handle other types of deep links
        return false
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let url = userActivity.webpageURL,
           (try? CoinbaseWalletSDK.shared.handleResponse(url)) == true {
            return true
        }
        // handle other types of deep links
        return false
    }

}

extension UIApplication {
    static func swizzleOpenURL() {
        guard
            let original = class_getInstanceMethod(UIApplication.self, #selector(open(_:options:completionHandler:))),
            let swizzled = class_getInstanceMethod(UIApplication.self, #selector(swizzledOpen(_:options:completionHandler:)))
        else { return }
        method_exchangeImplementations(original, swizzled)
    }
    
    @objc func swizzledOpen(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler completion: ((Bool) -> Void)?) {
        logWalletSegueMessage(url: url)
        
        // it's not recursive. below is actually the original open(_:) method
        self.swizzledOpen(url, options: options, completionHandler: completion)
    }
    
    func logWalletSegueMessage(url: URL, function: String = #function) {
        print("URL logged from \(function): \(url)")
    }
}





@main
struct reliefNodeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            NavigationView {
                MainView()
            }
        }
    }
}




import Foundation
import CoinbaseWalletSDK
import BigInt

class WalletManager: ObservableObject {
    static let shared = WalletManager()
    
    @Published var isConnected = false
    @Published var address: String = ""
    @Published var message: String = ""
    
    private let cbwallet = CoinbaseWalletSDK.shared
    
    func connectWallet(completion: @escaping (Bool) -> Void) {
        print("Initiating wallet connection...")
        
        cbwallet.initiateHandshake(
            initialActions: [
                Action(jsonRpc: .eth_requestAccounts)
            ]
        ) { [weak self] result, account in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    print("Response: \(response.content)")
                    
                    if let account = account {
                        self.isConnected = true
                        self.address = account.address
                        self.message = "Wallet connected successfully"
                        completion(true)
                    } else {
                        self.message = "No account found"
                        completion(false)
                    }
                    
                case .failure(let error):
                    self.message = "Connection failed: \(error.localizedDescription)"
                    completion(false)
                }
            }
        }
    }
    
    func makeTransaction(to: String, amount: String) {
        guard let amountInWei = formatEthToWei(amount) else {
            message = "Invalid amount"
            return
        }
        
        // Create the transaction parameters
        let transactionParams = Web3JSONRPC.eth_sendTransaction(
                    fromAddress: address,
                    toAddress: to,
                    weiValue: amountInWei,
                    data: "0x", // Empty data for simple transfer
                    nonce: nil, // Let wallet handle nonce
                    gasPriceInWei: "0x0", // Let wallet handle gas price
                    maxFeePerGas: "0x0", // Let wallet handle max fee
                    maxPriorityFeePerGas: "0x0", // Let wallet handle priority fee
                    gasLimit: "0x5208", // 21000 gas
                    chainId: "0x14a33", // Base Testnet Chain ID (84531)
                    actionSource: nil
                )
                
                
        let action = Action(jsonRpc: transactionParams)
        
        cbwallet.makeRequest(Request(actions: [action])) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    for result in response.content {
                        switch result {
                        case .success(let txHash):
                            self.message = "Transaction sent: \(txHash)"
                        case .failure(let error):
                            self.message = "Transaction failed: \(error.message)"
                        }
                    }
                case .failure(let error):
                    self.message = "Transaction failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func deployContract(name: String, symbol: String, initialSupply: String) {
        // Contract bytecode for ERC20 token
        let bytecode = "0x60806040523480156100105760006000fd5b506040518060400160405280600981526020016000815260200160405180910390f35b50"
               
               let transactionParams = Web3JSONRPC.eth_sendTransaction(
                   fromAddress: address,
                   toAddress: "0x", // Empty address for contract creation
                   weiValue: "0x0",
                   data: bytecode,
                   nonce: nil, // Let wallet handle nonce
                   gasPriceInWei: "0x0", // Let wallet handle gas price
                   maxFeePerGas: "0x0", // Let wallet handle max fee
                   maxPriorityFeePerGas: "0x0", // Let wallet handle priority fee
                   gasLimit: "0x100000", // Higher gas limit for contract deployment
                   chainId: "0x14a33", // Base Testnet Chain ID (84531)
                   actionSource: nil
               )
               
               let action = Action(jsonRpc: transactionParams)
        
        cbwallet.makeRequest(Request(actions: [action])) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    for result in response.content {
                        switch result {
                        case .success(let txHash):
                            self.message = "Contract deployment initiated: \(txHash)"
                        case .failure(let error):
                            self.message = "Contract deployment failed: \(error.message)"
                        }
                    }
                case .failure(let error):
                    self.message = "Contract deployment failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func formatEthToWei(_ ethAmount: String) -> String? {
        guard let amount = Double(ethAmount),
              amount > 0 else {
            return nil
        }
        
        // Convert ETH to Wei (1 ETH = 10^18 Wei)
        let weiAmount = Int(amount * pow(10, 18))
        return "0x" + String(weiAmount, radix: 16)
    }
    
    func resetConnection() {
        address = ""
        isConnected = false
        _ = cbwallet.resetSession()
    }
}
