//
//  WatchConnectivityManager.swift
//  LLM Wherever
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
        
        // If we're deleting the selected provider, select a new one or clear selection if no providers left
        if selectedProvider?.id == provider.id {
            if !apiProviders.isEmpty {
                selectedProvider = apiProviders.first
                selectedModel = selectedProvider?.models.first
            } else {
                // No providers left - clear selections
                selectedProvider = nil
                selectedModel = nil
            }
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
            // No default API providers - start with empty list
            apiProviders = []
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
    }
    
    func syncWithWatch() {
        guard WCSession.default.isReachable else { 
            print("Watch is not reachable, using background sync")
            // Even if watch is not reachable, try to sync using application context
            syncWithApplicationContext()
            return 
        }
        
        // First try using application context (recommended approach)
        syncWithApplicationContext()
        
        // If immediate notification is needed, send a simple message
        sendSyncNotification()
    }
    
    private func syncWithApplicationContext() {
        // Only sync active (enabled) providers
        let activeProviders = apiProviders.filter { $0.isActive }
        
        var context: [String: Any] = [:]
        
        // Encode API providers
        let providersData = activeProviders.compactMap { provider in
            try? JSONEncoder().encode(provider)
        }
        
        // Convert Data array to Base64 string array to avoid transmission issues
        let providersBase64 = providersData.map { $0.base64EncodedString() }
        context["apiProvidersBase64"] = providersBase64
        
        // Include selected provider and model (only if active and exists in current providers)
        if let provider = selectedProvider,
           provider.isActive,
           activeProviders.contains(where: { $0.id == provider.id }),
           let providerData = try? JSONEncoder().encode(provider) {
            context["selectedProviderBase64"] = providerData.base64EncodedString()
        }
        
        if let model = selectedModel,
           let provider = selectedProvider,
           provider.models.contains(where: { $0.id == model.id }),
           let modelData = try? JSONEncoder().encode(model) {
            context["selectedModelBase64"] = modelData.base64EncodedString()
        }
        
        // Add TTS settings
        if let ttsData = try? JSONEncoder().encode(TTSSettings.shared) {
            context["ttsSettingsBase64"] = ttsData.base64EncodedString()
        }
        
        // Add timestamp to ensure update
        context["syncTimestamp"] = Date().timeIntervalSince1970
        
        do {
            try WCSession.default.updateApplicationContext(context)
            print("Successfully updated application context: \(activeProviders.count) active API providers (total: \(apiProviders.count))")
            if activeProviders.isEmpty {
                print("Sent empty providers list to watch (all providers deleted or inactive)")
            }
        } catch {
            print("Failed to update application context: \(error.localizedDescription)")
            // Retry logic can be added here
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.retrySyncWithWatch()
            }
        }
    }
    
    private func sendSyncNotification() {
        // Send a small notification message telling watch to check application context
        let notification = ["action": "syncCheck", "timestamp": Date().timeIntervalSince1970] as [String : Any]
        
        WCSession.default.sendMessage(notification, replyHandler: { response in
            print("Watch successfully received sync notification and completed processing")
        }) { error in
            let nsError = error as NSError
            if nsError.code == 7004 { // WCErrorCodeDeliveryFailed
                print("Sync notification delivery failed, but application context will sync in background")
            } else {
                print("Failed to send sync notification: \(error.localizedDescription) (Code: \(nsError.code))")
            }
            // This failure is not critical because application context will sync in background
        }
    }
    
    private func retrySyncWithWatch() {
        print("Retrying sync data to watch...")
        syncWithApplicationContext()
    }
    
    func syncTTSSettings(_ settings: TTSSettings) {
        guard WCSession.default.isReachable else {
            print("Watch is not reachable, TTS settings will sync in background")
            return
        }
        
        guard let ttsData = try? JSONEncoder().encode(settings) else {
            print("Failed to encode TTS settings")
            return
        }
        
        let message = ["ttsSettingsBase64": ttsData.base64EncodedString()]
        
        WCSession.default.sendMessage(message, replyHandler: { response in
            print("TTS settings successfully synced to watch")
        }) { error in
            print("Failed to sync TTS settings to watch: \(error.localizedDescription)")
        }
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                print("WCSession activation failed: \(error.localizedDescription)")
            } else {
                print("WCSession activation successful")
                // Immediately sync data to watch after session activation
                self.syncWithWatch()
                // Also sync TTS settings immediately if watch is reachable
                if session.isReachable {
                    self.syncTTSSettings(TTSSettings.shared)
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            // Handle TTS settings update from Watch
            if let action = message["action"] as? String, action == "updateTTSFromWatch",
               let ttsBase64 = message["ttsSettingsBase64"] as? String,
               let data = Data(base64Encoded: ttsBase64),
               let ttsSettings = try? JSONDecoder().decode(TTSSettings.self, from: data) {
                TTSService.shared.updateSettings(ttsSettings)
                print("Updated TTS settings from Watch")
                return
            }
            
            print("Received message from watch: \(message)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            // Handle TTS settings update from Watch with reply
            if let action = message["action"] as? String, action == "updateTTSFromWatch",
               let ttsBase64 = message["ttsSettingsBase64"] as? String,
               let data = Data(base64Encoded: ttsBase64),
               let ttsSettings = try? JSONDecoder().decode(TTSSettings.self, from: data) {
                TTSService.shared.updateSettings(ttsSettings)
                print("Updated TTS settings from Watch (with reply)")
                replyHandler(["status": "ttsUpdated"])
                return
            }
            
            replyHandler(["status": "received"])
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            if session.isReachable {
                print("Watch became reachable, syncing data...")
                self.syncWithWatch()
                // Also sync TTS settings when watch becomes reachable
                self.syncTTSSettings(TTSSettings.shared)
            }
        }
    }
} 