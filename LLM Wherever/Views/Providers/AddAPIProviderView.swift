//
//  AddAPIProviderView.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
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
                                                Text(model.effectiveName)
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
                            Text("Enter the configuration information for your custom API provider. The API Key will be stored securely.")
                        } else {
                            Text("Enter your API Key and tap the button to test connection and automatically fetch available models.")
                        }
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