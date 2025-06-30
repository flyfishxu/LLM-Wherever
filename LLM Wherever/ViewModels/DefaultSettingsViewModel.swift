//
//  DefaultSettingsViewModel.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

@MainActor
class DefaultSettingsViewModel: ObservableObject {
    @Published var systemPrompt: String = ""
    @Published var temperature: Double = 0.7
    @Published var maxTokens: Int = 2000
    
    private var originalSettings: DefaultModelSettings
    
    init() {
        // Initialize originalSettings first
        self.originalSettings = DefaultModelSettings.shared
        // Then load current settings
        self.loadCurrentSettings()
    }
    
    private func loadCurrentSettings() {
        let settings = DefaultModelSettings.shared
        systemPrompt = settings.systemPrompt
        temperature = settings.temperature
        maxTokens = settings.maxTokens
    }
    
    func saveSettings() {
        let settings = DefaultModelSettings(
            systemPrompt: systemPrompt,
            temperature: temperature,
            maxTokens: maxTokens
        )
        
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "DefaultModelSettings")
        }
        
        // Update the shared instance
        updateSharedSettings(settings)
    }
    
    func discardChanges() {
        loadCurrentSettings()
    }
    
    func resetToSystemDefaults() {
        systemPrompt = "You are a helpful AI assistant."
        temperature = 0.7
        maxTokens = 2000
    }
    
    private func updateSharedSettings(_ settings: DefaultModelSettings) {
        // This is a simple way to update the shared instance
        // In a real app, you might want to use a more sophisticated state management approach
        let sharedSettings = DefaultModelSettings.shared
        // Since DefaultModelSettings.shared is a static let, we need to notify other parts of the app
        // about the change through UserDefaults or a proper state management system
        NotificationCenter.default.post(name: .defaultSettingsChanged, object: settings)
    }
}

extension Notification.Name {
    static let defaultSettingsChanged = Notification.Name("defaultSettingsChanged")
}
