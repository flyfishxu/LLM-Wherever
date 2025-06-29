//
//  AddAPIProviderView.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/1/16.
//

import SwiftUI

struct AddAPIProviderView: View {
    @StateObject private var viewModel = AddAPIProviderViewModel()
    @Environment(\.dismiss) private var dismiss

    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(AddAPIProviderViewModel.ProviderTemplate.allCases) { template in
                        Button(action: {
                            viewModel.selectTemplate(template)
                        }) {
                            HStack {
                                Image(systemName: template.icon)
                                    .foregroundStyle(.blue)
                                    .frame(width: 24)
                                
                                Text(template.displayName)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if viewModel.selectedTemplate == template {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Select API Provider")
                } footer: {
                    Text("Choose a preset API provider or create custom configuration.")
                }
                
                if viewModel.selectedTemplate != nil {
                    Section {
                        if viewModel.isCustomProvider {
                            TextField("Name", text: $viewModel.customName)
                            TextField("Base URL", text: $viewModel.customBaseURL)
                                .keyboardType(.URL)
                                .textContentType(.URL)
                        } else {
                            HStack {
                                Text("Name")
                                Spacer()
                                Text(viewModel.customName)
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Text("Base URL")
                                Spacer()
                                Text(viewModel.customBaseURL)
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        
                        HStack {
                            SecureField("API Key", text: $viewModel.apiKey)
                                .textContentType(.password)
                                .onChange(of: viewModel.apiKey) { _, newValue in
                                    viewModel.updateAPIKey(newValue)
                                }
                            
                            // Fetch models button - right next to API Key input field
                            if viewModel.showFetchButton {
                                Button(action: {
                                    viewModel.fetchModels()
                                }) {
                                    Group {
                                        if viewModel.isFetchingModels {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else if viewModel.hasFetchedModels {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                        } else {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                                .disabled(viewModel.isFetchingModels)
                                .buttonStyle(.bordered)
                                .help(viewModel.fetchButtonText)
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("System Prompt")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("Enter system prompt...", text: $viewModel.systemPrompt, axis: .vertical)
                                .lineLimit(3...6)
                        }
                        
                        // Fetch status and action buttons
                        if viewModel.canFetchModels {
                            VStack(spacing: 8) {
                                // Main action button - more prominent
                                Button(action: {
                                    viewModel.fetchModels()
                                }) {
                                    HStack {
                                        if viewModel.isFetchingModels {
                                            ProgressView()
                                                .controlSize(.small)
                                            Text("Fetching models...")
                                        } else if viewModel.hasFetchedModels {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                            Text("Re-fetch models")
                                        } else {
                                            Image(systemName: "network")
                                            VStack(spacing: 2) {
                                                Text("Test Connection")
                                                    .font(.caption)
                                                Text("& Fetch Models")
                                                    .font(.caption2)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .disabled(viewModel.isFetchingModels)
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            }
                        }
                        
                        // Display fetch results
                        if viewModel.hasFetchedModels {
                            if viewModel.fetchedModels.isEmpty {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.orange)
                                    Text("No models found")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.orange.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                        Text("Found \(viewModel.fetchedModels.count) models")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Spacer()
                                    }
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ForEach(viewModel.fetchedModels.prefix(6)) { model in
                                                Text(model.name)
                                                    .font(.caption2)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(.blue.opacity(0.1))
                                                    .foregroundStyle(.blue)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            
                                            if viewModel.fetchedModels.count > 6 {
                                                Text("...")
                                                    .font(.caption2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding(.horizontal, 1)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        
                        // Display error
                        if let error = viewModel.fetchError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Connection failed")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.red)
                                    Text(error)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                    } header: {
                        Text("Configuration")
                    } footer: {
                        if viewModel.selectedTemplate == .custom {
                            Text("Enter the configuration information for your custom API provider. The API Key will be stored securely. The system prompt will be shown as the first message when starting a conversation on Apple Watch.")
                        } else {
                            Text("Enter your API Key and customize the system prompt. Tap the button to test connection and automatically fetch available models. The system prompt will be shown as the first message when starting a conversation on Apple Watch.")
                        }
                    }
                    
                    // AI Parameters Section
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
                        Text("Temperature controls creativity (0.0 = focused, 2.0 = creative). Max tokens limits response length. Higher values use more API quota.")
                    }
                }
            }
            .navigationTitle("Add API Provider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.addProvider()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.canAddProvider)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddAPIProviderView()
} 