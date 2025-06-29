//
//  SettingsTabView.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct SettingsTabView: View {
    @StateObject private var viewModel = DefaultSettingsViewModel()
    
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
                
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Global Default Settings")
                                .font(.headline)
                            Text("These settings apply to all new models that don't have custom configurations. Existing models with custom settings will not be affected.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Information")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveSettings()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    SettingsTabView()
} 