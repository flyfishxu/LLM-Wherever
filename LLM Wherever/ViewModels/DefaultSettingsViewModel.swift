//
//  DefaultSettingsViewModel.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

@MainActor
class DefaultSettingsViewModel: ObservableObject {
    @Published var systemPrompt: String = "" {
        didSet { updateUnsavedChangesState() }
    }
    @Published var temperature: Double = 0.7 {
        didSet { updateUnsavedChangesState() }
    }
    @Published var maxTokens: Int = 2000 {
        didSet { updateUnsavedChangesState() }
    }
    @Published var hasUnsavedChanges: Bool = false
    
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
        
        // Update original settings and reset unsaved changes flag
        originalSettings = settings
        hasUnsavedChanges = false
    }
    
    func discardChanges() {
        loadCurrentSettings()
        hasUnsavedChanges = false
    }
    
    func resetToSystemDefaults() {
        systemPrompt = "You are a helpful AI assistant."
        temperature = 0.7
        maxTokens = 2000
        // Note: hasUnsavedChanges will be updated automatically by didSet
    }
    
    private func updateSharedSettings(_ settings: DefaultModelSettings) {
        // This is a simple way to update the shared instance
        // In a real app, you might want to use a more sophisticated state management approach
        let sharedSettings = DefaultModelSettings.shared
        // Since DefaultModelSettings.shared is a static let, we need to notify other parts of the app
        // about the change through UserDefaults or a proper state management system
        NotificationCenter.default.post(name: .defaultSettingsChanged, object: settings)
    }
    
    private func updateUnsavedChangesState() {
        hasUnsavedChanges = systemPrompt != originalSettings.systemPrompt ||
                           temperature != originalSettings.temperature ||
                           maxTokens != originalSettings.maxTokens
    }
}

extension Notification.Name {
    static let defaultSettingsChanged = Notification.Name("defaultSettingsChanged")
}
