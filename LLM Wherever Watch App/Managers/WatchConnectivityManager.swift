//
//  WatchConnectivityManager.swift
//  LLM Wherever Watch App
//
//  Created by 徐义超 on 2025/1/16.
//

import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var apiProviders: [APIProvider] = []
    @Published var selectedProvider: APIProvider?
    @Published var selectedModel: LLMModel?
    @Published var isConnected = false
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        
        loadSelections()
    }
    
    func selectProvider(_ provider: APIProvider) {
        selectedProvider = provider
        selectedModel = provider.models.first
        saveSelections()
    }
    
    func selectModel(_ model: LLMModel) {
        selectedModel = model
        saveSelections()
    }
    
    private func saveSelections() {
        if let provider = selectedProvider,
           let providerData = try? JSONEncoder().encode(provider) {
            UserDefaults.standard.set(providerData, forKey: "selectedProvider")
        }
        
        if let model = selectedModel,
           let modelData = try? JSONEncoder().encode(model) {
            UserDefaults.standard.set(modelData, forKey: "selectedModel")
        }
    }
    
    private func loadSelections() {
        if let providerData = UserDefaults.standard.data(forKey: "selectedProvider"),
           let provider = try? JSONDecoder().decode(APIProvider.self, from: providerData) {
            selectedProvider = provider
        }
        
        if let modelData = UserDefaults.standard.data(forKey: "selectedModel"),
           let model = try? JSONDecoder().decode(LLMModel.self, from: modelData) {
            selectedModel = model
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
            if let error = error {
                print("WCSession activation failed: \(error.localizedDescription)")
            } else {
                print("WCSession activation successful")
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            // Update API providers
            if let providersData = message["apiProviders"] as? [Data] {
                self.apiProviders = providersData.compactMap { data in
                    try? JSONDecoder().decode(APIProvider.self, from: data)
                }
            }
            
            // Update selected provider
            if let providerData = message["selectedProvider"] as? Data,
               let provider = try? JSONDecoder().decode(APIProvider.self, from: providerData) {
                self.selectedProvider = provider
            }
            
            // Update selected model
            if let modelData = message["selectedModel"] as? Data,
               let model = try? JSONDecoder().decode(LLMModel.self, from: modelData) {
                self.selectedModel = model
            }
            
            // Save the received selections
            self.saveSelections()
        }
    }
} 