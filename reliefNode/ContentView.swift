//
//  ContentView.swift
//  reliefNode
//
//  Created by Prannvat Singh on 26/10/2024.
//

import SwiftUI
import CoinbaseWalletSDK
import Foundation

struct Charity: Identifiable {
    let id = UUID()
    let name: String
    let walletAddress: String
    let imageName: String
}

struct FundPeople: Identifiable {
    let id: UUID =  UUID()
    let coinName: String
    let coinSymbol: String
    let initialSupply: String
    let description: String
}

import SwiftUI
struct MainView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            
            CreateMemeCoinView()
                .tabItem {
                    Label("Create Coin", systemImage: "plus.circle")
                }
        }
    }
}


struct CreateMemeCoinView: View {
    @StateObject private var walletManager = WalletManager.shared
    @State private var coinName: String = ""
    @State private var coinSymbol: String = ""
    @State private var initialSupply: String = ""
    @State private var description: String = ""
    
    var body: some View {
        VStack {
           
                Text("Create Your Own Coin")
                               .font(.title)
                               .fontWeight(.bold)
                               .padding()
                TextField("Coin Name", text: $coinName)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal)

                        TextField("Coin Symbol", text: $coinSymbol)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .padding(.horizontal)
                TextField("Initial Supply", text: $initialSupply)
                               .keyboardType(.numberPad)
                               .padding()
                               .background(Color(.systemGray6))
                               .cornerRadius(8)
                               .padding(.horizontal)
                           
                           TextField("Description", text: $description)
                               .padding()
                               .background(Color(.systemGray6))
                               .cornerRadius(8)
                               .padding(.horizontal)
                
                Button(action: createCoin) {
                    Text("Create Coin")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            
            if !walletManager.isConnected {
                Button(action: connectWallet) {
                    Text("Connect Wallet")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }
            
            
            Text(walletManager.message)
                .font(.footnote)
                .foregroundColor(.red)
                .padding()
            
            Image("logo")
                .resizable()
                .frame(width: UIScreen.main.bounds.width * 0.8, height: 60)
                .padding()
            Spacer()
        }
        
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.green.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
    }
    
    func connectWallet() {
        walletManager.connectWallet { success in
            // Handle post-connection actions if needed
        }
    }
    
    func createCoin() {
        guard !coinName.isEmpty && !coinSymbol.isEmpty && !initialSupply.isEmpty else {
            walletManager.message = "Please fill in all fields"
            return
        }
        
        walletManager.deployContract(
            name: coinName,
            symbol: coinSymbol,
            initialSupply: initialSupply
        )
    }
}
struct HomeView: View {
    @State private var charityView: Bool = true
    let foundations = [
        Charity(name: "Global Aid", walletAddress: "0xGlobalAidWalletAddress", imageName: "globalAid"),
        Charity(name: "Relief Now", walletAddress: "0xReliefNowWalletAddress", imageName: "reliefNow"),
        Charity(name: "WWF", walletAddress: "0xHelpHandsWalletAddress", imageName: "wwf"),
        Charity(name: "Care Foundation", walletAddress: "0xCareFoundationWalletAddress", imageName: "careFoundation"),
        Charity(name: "Hope Alliance", walletAddress: "0xHopeAllianceWalletAddress", imageName: "hopeAlliance")
    ]

    var body: some View {
        NavigationStack {
            VStack {
                Image("logo")
                    .resizable()
                    .frame(width: UIScreen.main.bounds.width * 0.8, height: 60)
                    .padding()
                HStack(spacing: 0){
                    Button {
                        charityView = true
                    }
                label: {
                    VStack{
                        Text("Charities")
                            .foregroundStyle(.black)
                            
                        Divider()
                            .frame(height: charityView ? 2 : 1)
                            .background(Color.black)
                    }
                }
                    
                    Button {
                        charityView = false
                    }
                label: {
                    VStack{
                        Text("Fund People")
                            .foregroundStyle(.black)
                        Divider()
                            .frame(height: charityView ? 1 : 2 )
                            .background(Color.black)
                    }
                }
                }
                if charityView{
                    List(foundations) { foundation in
                        NavigationLink(destination: FoundationDetailView(foundation: foundation)) {
                            HStack {
                                Image(foundation.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Rectangle())
                                    .padding(.trailing, 10)
                                
                                Text(foundation.name)
                                    .font(.headline)
                                    .padding()
                            }
                        }
                        .listRowBackground(Color(.clear))
                    }
                    .listStyle(PlainListStyle())
                } else {
                    
                }

                Spacer()
            }
            .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.green.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
        }
        .preferredColorScheme(.light)
    }
}

struct FoundationDetailView: View {
    let foundation: Charity
    @State private var isConnected = false
    @State private var address: String = ""
    @State private var donationAmount: String = ""
    @State private var message: String = ""
    @State private var logText: String = ""

    var body: some View {
        VStack {
            Text(foundation.name)
                .font(.title)
                .fontWeight(.bold)
                .padding()

            if isConnected {
                Text("Connected: \(address)")
                    .font(.subheadline)
                    .padding()

                TextField("Donation Amount (ETH)", text: $donationAmount)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)

                Button(action: donate) {
                    Text("Donate")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            } else {
                Button(action: connectWallet) {
                    Text("Connect Wallet")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
            }

            Text(message)
                .font(.footnote)
                .foregroundColor(.red)
                .padding()

            Text(logText)
                .multilineTextAlignment(.center)
                .font(.footnote)
                .foregroundColor(.gray)
                .padding()

            Spacer()
        }
        .navigationTitle("Donate")
        .background(LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.3), Color.orange.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
    }

    func connectWallet() {
        print("test")
        log("Connect Wallet")
        CoinbaseWalletSDK.shared.initiateHandshake(initialActions: [Action(jsonRpc: .eth_requestAccounts)]) { result, account in
            log("Connect Wallet!")
            switch result {
            case .success(let response):
                if let account = account {
                    DispatchQueue.main.async {
                        self.isConnected = true
                        self.address = account.address
                        self.message = "Wallet connected"
                        log("Wallet connected: \(self.isConnected)")
                        log("Address: \(self.address)")
                    }
                } else {
                    DispatchQueue.main.async {
                        self.message = "No account found"
                        log("No account found")
                    }
                }
                log("Response callback URL: \(response.callbackUrl)")
            case .failure(let error):
                DispatchQueue.main.async {
                    self.message = "Connection failed: \(error.localizedDescription)"
                    log("Connection failed: \(error.localizedDescription)")
                }
            }
        }
        log("Message: \(message)")
    }

    func donate() {
        guard let amount = Double(donationAmount) else {
            message = "Invalid donation amount"
            return
        }

        // Implement donation logic here
        // For now, just simulate a successful donation
        DispatchQueue.main.async {
            self.message = "Donation successful to \(foundation.name)!"
        }
    }

    private func log(_ text: String) {
        DispatchQueue.main.async {
            self.logText = "\(text)\n\(self.logText)"
        }
    }
}

#Preview {
    MainView()
}

