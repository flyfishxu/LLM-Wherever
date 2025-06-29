//
//  ModelConfigurationView.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct ModelConfigurationView: View {
    @Binding var model: LLMModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Display Name", text: Binding(
                        get: { model.customName ?? model.name },
                        set: { model.customName = $0.isEmpty ? nil : $0 }
                    ))
                } header: {
                    Text("Model Information")
                } footer: {
                    Text("Original name: \(model.name)\nAPI identifier: \(model.identifier)")
                }
                
                Section {
                    Toggle("Use Custom Settings", isOn: $model.useCustomSettings)
                        .onChange(of: model.useCustomSettings) { _, newValue in
                            if newValue {
                                // Initialize with current defaults if switching to custom
                                let defaults = DefaultModelSettings.shared
                                if model.systemPrompt?.isEmpty != false {
                                    model.systemPrompt = defaults.systemPrompt
                                }
                                if model.temperature == nil {
                                    model.temperature = defaults.temperature
                                }
                                if model.maxTokens == nil {
                                    model.maxTokens = defaults.maxTokens
                                }
                            }
                        }
                } header: {
                    Text("Configuration")
                                    } footer: {
                        Text("When disabled, this model will use the global default settings.")
                    }
                
                if model.useCustomSettings {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("System Prompt")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("Enter system prompt...", text: Binding(
                                get: { model.systemPrompt ?? "" },
                                set: { model.systemPrompt = $0.isEmpty ? nil : $0 }
                            ), axis: .vertical)
                                .lineLimit(3...6)
                        }
                    } header: {
                        Text("AI Assistant Settings")
                    } footer: {
                        Text("Custom system prompt for this model. Leave empty to use global default.")
                    }
                    
                    Section {
                        ParameterSliderView(
                            title: "Temperature",
                            description: "Controls randomness in responses",
                            systemImage: "thermometer",
                            value: Binding(
                                get: { model.temperature ?? DefaultModelSettings.shared.temperature },
                                set: { model.temperature = $0 }
                            ),
                            range: 0.0...2.0,
                            step: 0.1,
                            displayFormatter: { String(format: "%.1f", $0) },
                            inputValidator: { Double($0) }
                        )
                        
                        IntParameterSliderView(
                            title: "Max Tokens",
                            description: "Maximum response length",
                            systemImage: "text.alignleft",
                            value: Binding(
                                get: { model.maxTokens ?? DefaultModelSettings.shared.maxTokens },
                                set: { model.maxTokens = $0 }
                            ),
                            range: 100...8000,
                            step: 100
                        )
                    } header: {
                        Text("AI Parameters")
                    } footer: {
                        Text("Custom parameters for this model. Temperature controls creativity (0.0 = focused, 2.0 = creative).")
                    }
                } else {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "text.bubble")
                                    .foregroundStyle(.blue)
                                    .frame(width: 20)
                                Text("System Prompt")
                                    .font(.headline)
                                Spacer()
                                Text("Default")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.secondary.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                            
                            HStack {
                                Image(systemName: "thermometer")
                                    .foregroundStyle(.blue)
                                    .frame(width: 20)
                                Text("Temperature")
                                    .font(.headline)
                                Spacer()
                                Text(String(format: "%.1f", DefaultModelSettings.shared.temperature))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack {
                                Image(systemName: "text.alignleft")
                                    .foregroundStyle(.blue)
                                    .frame(width: 20)
                                Text("Max Tokens")
                                    .font(.headline)
                                Spacer()
                                Text("\(DefaultModelSettings.shared.maxTokens)")
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Current Settings (Using Global Defaults)")
                    } footer: {
                        Text("This model is using the global default settings. Enable \"Use Custom Settings\" to configure individual parameters.")
                    }
                }
            }
            .navigationTitle("Model Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    @State var sampleModel = LLMModel(name: "GPT-4", identifier: "gpt-4")
    
    return ModelConfigurationView(
        model: $sampleModel
    )
} 