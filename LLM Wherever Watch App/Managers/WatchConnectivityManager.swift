//
//  WatchConnectivityManager.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var apiProviders: [APIProvider] = []
    @Published var selectedProvider: APIProvider?
    @Published var selectedModel: LLMModel?
    @Published var isConnected = false
    @Published var isSyncing = false
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        
        // Load locally saved API providers first
        loadAPIProviders()
        // Then load selection settings
        loadSelections()
        
        // If no local data exists, try to load from application context
        if apiProviders.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.loadDataFromApplicationContext()
            }
        }
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
    
    // Additional methods for history support
    func setSelectedProvider(_ provider: APIProvider) {
        selectProvider(provider)
    }
    
    func setSelectedModel(_ model: LLMModel) {
        selectModel(model)
    }
    

    
    // Save API providers to local storage
    private func saveAPIProviders() {
        if let encoded = try? JSONEncoder().encode(apiProviders) {
            UserDefaults.standard.set(encoded, forKey: "apiProviders")
        }
    }
    
    // Load API providers from local storage
    private func loadAPIProviders() {
        if let data = UserDefaults.standard.data(forKey: "apiProviders"),
           let decoded = try? JSONDecoder().decode([APIProvider].self, from: data) {
            apiProviders = decoded
        } else {
            // No configuration on initial startup, wait for sync from phone
            apiProviders = []
        }
    }
    
    private func saveSelections() {
        if let provider = selectedProvider,
           let providerData = try? JSONEncoder().encode(provider) {
            UserDefaults.standard.set(providerData, forKey: "selectedProvider")
        } else {
            // Clear saved selection if no provider is selected
            UserDefaults.standard.removeObject(forKey: "selectedProvider")
        }
        
        if let model = selectedModel,
           let modelData = try? JSONEncoder().encode(model) {
            UserDefaults.standard.set(modelData, forKey: "selectedModel")
        } else {
            // Clear saved selection if no model is selected
            UserDefaults.standard.removeObject(forKey: "selectedModel")
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
        
        // If no provider is selected, automatically select the first available one
        if selectedProvider == nil && !apiProviders.isEmpty {
            selectedProvider = apiProviders.first(where: { $0.isActive }) ?? apiProviders.first
            selectedModel = selectedProvider?.models.first
            saveSelections()
        }
    }
    
    // Sync TTS settings from Watch to iPhone
    func syncTTSToPhone() {
        guard WCSession.default.isReachable else {
            print("iPhone is not reachable, TTS settings will sync in background")
            return
        }
        
        guard let ttsData = try? JSONEncoder().encode(TTSSettings.shared) else {
            print("Failed to encode TTS settings")
            return
        }
        
        let message = [
            "action": "updateTTSFromWatch",
            "ttsSettingsBase64": ttsData.base64EncodedString()
        ]
        
        WCSession.default.sendMessage(message, replyHandler: { response in
            print("TTS settings successfully synced to iPhone")
        }) { error in
            print("Failed to sync TTS settings to iPhone: \(error.localizedDescription)")
        }
    }
    
    // Sync data to local storage
    private func syncLocalData(providers: [APIProvider], selectedProvider: APIProvider?, selectedModel: LLMModel?) {
        // Update local API providers
        self.apiProviders = providers
        saveAPIProviders()
        
        // Handle provider and model selection based on received data and available providers
        if providers.isEmpty {
            // All providers were deleted - clear selections
            self.selectedProvider = nil
            self.selectedModel = nil
            print("All API providers deleted - cleared selections")
        } else {
            // Update selected provider and model if valid
            if let provider = selectedProvider, 
               provider.isActive,
               providers.contains(where: { $0.id == provider.id }) {
                self.selectedProvider = provider
            } else {
                // Selected provider not available, auto-select first active provider
                self.selectedProvider = providers.first(where: { $0.isActive }) ?? providers.first
            }
            
            // Update selected model
            if let model = selectedModel,
               let currentProvider = self.selectedProvider,
               currentProvider.models.contains(where: { $0.id == model.id }) {
                self.selectedModel = model
            } else {
                // Selected model not available, auto-select first model of current provider
                self.selectedModel = self.selectedProvider?.models.first
            }
        }
        
        // Save updated selections
        saveSelections()
        
        print("Synced data to watch local storage, total \(providers.count) API providers")
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
                // Immediately check application context after activation
                self.loadDataFromApplicationContext()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            print("Received application context update")
            self.processApplicationContext(applicationContext)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            // Handle sync notification
            if let action = message["action"] as? String, action == "syncCheck" {
                print("Received sync check notification")
                self.loadDataFromApplicationContext()
                // Reply with confirmation message
                replyHandler(["status": "syncCompleted", "providersCount": self.apiProviders.count])
                return
            }
            
            // Handle TTS settings update
            if let ttsBase64 = message["ttsSettingsBase64"] as? String,
               let data = Data(base64Encoded: ttsBase64),
               let ttsSettings = try? JSONDecoder().decode(TTSSettings.self, from: data) {
                TTSService.shared.updateSettings(ttsSettings)
                print("Updated TTS settings from iPhone (immediate)")
                replyHandler(["status": "ttsUpdated"])
                return
            }
            
            // For other message types, simply reply with confirmation
            replyHandler(["status": "received"])
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            // Handle messages without reply handler (maintain backward compatibility)
            if let action = message["action"] as? String, action == "syncCheck" {
                print("Received sync check notification (no reply)")
                self.loadDataFromApplicationContext()
                return
            }
            
            // Maintain legacy message handling logic as backup
            self.processLegacyMessage(message)
        }
    }
    
    // Load data from application context
    @MainActor private func loadDataFromApplicationContext() {
        let context = WCSession.default.receivedApplicationContext
        guard !context.isEmpty else {
            print("Application context is empty")
            return
        }
        
        processApplicationContext(context)
    }
    
    // Process application context data
    @MainActor private func processApplicationContext(_ context: [String: Any]) {
        self.isSyncing = true
        
        var receivedProviders: [APIProvider] = []
        var receivedSelectedProvider: APIProvider?
        var receivedSelectedModel: LLMModel?
        
        // Parse Base64 encoded API providers
        if let providersBase64 = context["apiProvidersBase64"] as? [String] {
            receivedProviders = providersBase64.compactMap { base64String in
                guard let data = Data(base64Encoded: base64String),
                      let provider = try? JSONDecoder().decode(APIProvider.self, from: data) else {
                    return nil
                }
                return provider
            }.filter { $0.isActive }
        }
        
        // Parse selected provider
        if let providerBase64 = context["selectedProviderBase64"] as? String,
           let data = Data(base64Encoded: providerBase64),
           let provider = try? JSONDecoder().decode(APIProvider.self, from: data),
           provider.isActive {
            receivedSelectedProvider = provider
        }
        
        // Parse selected model
        if let modelBase64 = context["selectedModelBase64"] as? String,
           let data = Data(base64Encoded: modelBase64),
           let model = try? JSONDecoder().decode(LLMModel.self, from: data) {
            receivedSelectedModel = model
        }
        
        // Parse TTS settings
        if let ttsBase64 = context["ttsSettingsBase64"] as? String,
           let data = Data(base64Encoded: ttsBase64),
           let ttsSettings = try? JSONDecoder().decode(TTSSettings.self, from: data) {
            TTSService.shared.updateSettings(ttsSettings)
            print("Updated TTS settings from iPhone")
        }
        
        // Sync data to local storage - always sync, even if providers list is empty
        // This ensures deletions are properly reflected on the watch
        self.syncLocalData(
            providers: receivedProviders,
            selectedProvider: receivedSelectedProvider,
            selectedModel: receivedSelectedModel
        )
        
        if !receivedProviders.isEmpty {
            print("Successfully synced \(receivedProviders.count) API providers from application context")
        } else {
            print("Synced empty API providers list (all providers deleted)")
        }
        
        self.isSyncing = false
    }
    
    // Process legacy message format (backward compatibility)
    private func processLegacyMessage(_ message: [String: Any]) {
        self.isSyncing = true
        
        var receivedProviders: [APIProvider] = []
        var receivedSelectedProvider: APIProvider?
        var receivedSelectedModel: LLMModel?
        
        // Parse received API providers (legacy format)
        if let providersData = message["apiProviders"] as? [Data] {
            receivedProviders = providersData.compactMap { data in
                try? JSONDecoder().decode(APIProvider.self, from: data)
            }.filter { $0.isActive }
        }
        
        // Parse received selected provider (legacy format)
        if let providerData = message["selectedProvider"] as? Data,
           let provider = try? JSONDecoder().decode(APIProvider.self, from: providerData),
           provider.isActive {
            receivedSelectedProvider = provider
        }
        
        // Parse received selected model (legacy format)
        if let modelData = message["selectedModel"] as? Data,
           let model = try? JSONDecoder().decode(LLMModel.self, from: modelData) {
            receivedSelectedModel = model
        }
        
        // Sync data to local storage - always sync, even if providers list is empty
        // This ensures deletions are properly reflected on the watch
        self.syncLocalData(
            providers: receivedProviders,
            selectedProvider: receivedSelectedProvider,
            selectedModel: receivedSelectedModel
        )
        
        self.isSyncing = false
    }
} 
