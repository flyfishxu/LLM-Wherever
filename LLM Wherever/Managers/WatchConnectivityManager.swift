//
//  WatchConnectivityManager.swift
//  LLM Wherever
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
    
    private override init() {
        super.init()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        
        loadAPIProviders()
    }
    
    func addAPIProvider(_ provider: APIProvider) {
        apiProviders.append(provider)
        saveAPIProviders()
        syncWithWatch()
    }
    
    func updateAPIProvider(_ provider: APIProvider) {
        if let index = apiProviders.firstIndex(where: { $0.id == provider.id }) {
            apiProviders[index] = provider
            
            // Update selected provider if it's the same one
            if selectedProvider?.id == provider.id {
                selectedProvider = provider
                // If selected model no longer exists, select the first available model
                if let selectedModel = selectedModel,
                   !provider.models.contains(where: { $0.id == selectedModel.id }) {
                    self.selectedModel = provider.models.first
                }
            }
            
            saveAPIProviders()
            saveSelections()
            syncWithWatch()
        }
    }
    
    func deleteAPIProvider(_ provider: APIProvider) {
        apiProviders.removeAll { $0.id == provider.id }
        
        // If we're deleting the selected provider, select a new one
        if selectedProvider?.id == provider.id {
            selectedProvider = apiProviders.first
            selectedModel = selectedProvider?.models.first
            saveSelections()
        }
        
        saveAPIProviders()
        syncWithWatch()
    }
    
    private func saveAPIProviders() {
        if let encoded = try? JSONEncoder().encode(apiProviders) {
            UserDefaults.standard.set(encoded, forKey: "apiProviders")
        }
    }
    
    private func loadAPIProviders() {
        if let data = UserDefaults.standard.data(forKey: "apiProviders"),
           let decoded = try? JSONDecoder().decode([APIProvider].self, from: data) {
            apiProviders = decoded
        } else {
            // Add default API providers
            apiProviders = [.openAI, .anthropic]
        }
        
        // Load saved selections
        loadSelections()
        
        // Auto-select if no selection exists
        if selectedProvider == nil && !apiProviders.isEmpty {
            selectedProvider = apiProviders.first
            selectedModel = selectedProvider?.models.first
            saveSelections()
        }
    }
    
    func selectProvider(_ provider: APIProvider) {
        selectedProvider = provider
        selectedModel = provider.models.first
        saveSelections()
        syncWithWatch()
    }
    
    func selectModel(_ model: LLMModel) {
        selectedModel = model
        saveSelections()
        syncWithWatch()
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
    
    func syncWithWatch() {
        guard WCSession.default.isReachable else { return }
        
        var message: [String: Any] = [
            "apiProviders": apiProviders.compactMap { provider in
                try? JSONEncoder().encode(provider)
            }
        ]
        
        // Include selected provider and model
        if let provider = selectedProvider,
           let providerData = try? JSONEncoder().encode(provider) {
            message["selectedProvider"] = providerData
        }
        
        if let model = selectedModel,
           let modelData = try? JSONEncoder().encode(model) {
            message["selectedModel"] = modelData
        }
        
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send data to watch: \(error.localizedDescription)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activation successful")
            syncWithWatch()
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Handle messages from watch
        print("Received message from watch: \(message)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
} 