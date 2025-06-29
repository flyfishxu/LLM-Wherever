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
            saveAPIProviders()
            syncWithWatch()
        }
    }
    
    func deleteAPIProvider(_ provider: APIProvider) {
        apiProviders.removeAll { $0.id == provider.id }
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
    }
    
    func syncWithWatch() {
        guard WCSession.default.isReachable else { return }
        
        let message: [String: Any] = [
            "apiProviders": apiProviders.compactMap { provider in
                try? JSONEncoder().encode(provider)
            }
        ]
        
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