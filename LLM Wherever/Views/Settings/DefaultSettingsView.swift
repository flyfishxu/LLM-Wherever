//
//  DefaultSettingsView.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct DefaultSettingsView: View {
    @StateObject private var viewModel = DefaultSettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Default System Prompt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Enter default system prompt...", text: $viewModel.systemPrompt, axis: .vertical)
                            .lineLimit(3...6)
                    }
                } header: {
                    Text("AI Assistant Settings")
                } footer: {
                    Text("This will be used as the default system prompt for all new models when they enable custom settings.")
                }
                
                Section {
                    ParameterSliderView(
                        title: "Temperature",
                        description: "Controls randomness in responses",
                        systemImage: "thermometer",
                        value: $viewModel.temperature,
                        range: 0.0...2.0,
                        step: 0.1,
                        displayFormatter: { String(format: "%.1f", $0) },
                        inputValidator: { Double($0) }
                    )
                    
                    IntParameterSliderView(
                        title: "Max Tokens",
                        description: "Maximum response length",
                        systemImage: "text.alignleft",
                        value: $viewModel.maxTokens,
                        range: 100...8000,
                        step: 100
                    )
                } header: {
                    Text("AI Parameters")
                } footer: {
                    Text("These values will be used as defaults for all new models. Temperature controls creativity (0.0 = focused, 2.0 = creative). Max tokens limits response length.")
                }
                
                Section {
                    Button("Reset to System Defaults") {
                        viewModel.resetToSystemDefaults()
                    }
                    .foregroundStyle(.red)
                } header: {
                    Text("Reset")
                } footer: {
                    Text("This will reset all default settings to their original system values.")
                }
            }
            .navigationTitle("Default Model Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.discardChanges()
                        dismiss()
                    }
                }
            }
        }
    }
}

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

#Preview {
    DefaultSettingsView()
} 