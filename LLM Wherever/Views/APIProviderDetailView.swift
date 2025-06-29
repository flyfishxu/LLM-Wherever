//
//  APIProviderDetailView.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/1/16.
//

import SwiftUI

struct APIProviderDetailView: View {
    @StateObject private var viewModel: APIProviderDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(provider: APIProvider) {
        _viewModel = StateObject(wrappedValue: APIProviderDetailViewModel(provider: provider))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $viewModel.provider.name)
                    TextField("Base URL", text: $viewModel.provider.baseURL)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                    SecureField("API Key", text: $viewModel.provider.apiKey)
                        .textContentType(.password)
                } header: {
                    Text("Basic Information")
                } footer: {
                    Text("Enter the basic information for the API provider. The API Key will be stored securely.")
                }
                
                Section {
                    VStack(alignment: .leading) {
                        Text("System Prompt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Enter system prompt...", text: $viewModel.provider.systemPrompt, axis: .vertical)
                            .lineLimit(3...6)
                    }
                } header: {
                    Text("AI Assistant Settings")
                } footer: {
                    Text("The system prompt will be shown as the first message when starting a conversation on Apple Watch.")
                }
                
                Section {
                    Toggle("Enable", isOn: $viewModel.provider.isActive)
                } header: {
                    Text("Status")
                }
                
                Section {
                    ForEach(viewModel.provider.models) { model in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(model.name)
                                    .font(.headline)
                                Text(model.identifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteModel(model)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: viewModel.deleteModel)
                    
                    // Fetch models from API button
                    Button(action: {
                        viewModel.fetchModels()
                    }) {
                        HStack {
                            if viewModel.isFetchingModels {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Fetching models...")
                            } else {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Fetch models from API")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(!viewModel.canFetchModels)
                    .buttonStyle(.borderedProminent)
                    
                    // Show fetch error
                    if viewModel.hasFetchError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(viewModel.fetchErrorMessage)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button(action: viewModel.showAddModel) {
                        Label("Manually add model", systemImage: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                } header: {
                    Text("Supported Models")
                } footer: {
                    Text("Tap \"Fetch models from API\" to automatically get the latest available models, or manually add custom models.")
                }
            }
            .navigationTitle(viewModel.provider.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveProvider()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddModel) {
                AddModelView { model in
                    viewModel.addModel(model)
                }
            }
        }
    }

}

struct AddModelView: View {
    @StateObject private var viewModel = AddModelViewModel()
    @Environment(\.dismiss) private var dismiss
    
    let onAdd: (LLMModel) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Model Name", text: $viewModel.modelName)
                        .textContentType(.name)
                    TextField("Model Identifier", text: $viewModel.modelIdentifier)
                        .textContentType(.name)
                } header: {
                    Text("Model Information")
                } footer: {
                    Text("Enter the display name and API identifier for the model.")
                }
            }
            .navigationTitle("Add Model")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if let model = viewModel.createModel() {
                            onAdd(model)
                            viewModel.reset()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.canCreateModel)
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
    APIProviderDetailView(provider: APIProvider(
        name: "OpenAI",
        baseURL: "https://api.openai.com/v1",
        apiKey: "test-key",
        models: [],
        isActive: true
    ))
} 
