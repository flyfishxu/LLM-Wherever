//
//  APIProviderDetailView.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/1/16.
//

import SwiftUI

struct APIProviderDetailView: View {
    @State private var provider: APIProvider
    @State private var showingAddModel = false
    @State private var isFetchingModels = false
    @State private var fetchError: String?
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var modelFetchService = ModelFetchService.shared
    
    init(provider: APIProvider) {
        _provider = State(initialValue: provider)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $provider.name)
                    TextField("Base URL", text: $provider.baseURL)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                    SecureField("API Key", text: $provider.apiKey)
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
                        TextField("Enter system prompt...", text: $provider.systemPrompt, axis: .vertical)
                            .lineLimit(3...6)
                    }
                } header: {
                    Text("AI Assistant Settings")
                } footer: {
                    Text("The system prompt will be shown as the first message when starting a conversation on Apple Watch.")
                }
                
                Section {
                    Toggle("Enable", isOn: $provider.isActive)
                } header: {
                    Text("Status")
                }
                
                Section {
                    ForEach(provider.models) { model in
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
                                if let index = provider.models.firstIndex(where: { $0.id == model.id }) {
                                    provider.models.remove(at: index)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: deleteModel)
                    
                    // Fetch models from API button
                    Button(action: {
                        fetchModels()
                    }) {
                        HStack {
                            if isFetchingModels {
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
                    .disabled(isFetchingModels || provider.apiKey.isEmpty)
                    .buttonStyle(.borderedProminent)
                    
                    // Show fetch error
                    if let error = fetchError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button(action: { showingAddModel = true }) {
                        Label("Manually add model", systemImage: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                } header: {
                    Text("Supported Models")
                } footer: {
                    Text("Tap \"Fetch models from API\" to automatically get the latest available models, or manually add custom models.")
                }
            }
            .navigationTitle(provider.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        connectivityManager.updateAPIProvider(provider)
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
            .sheet(isPresented: $showingAddModel) {
                AddModelView { model in
                    provider.models.append(model)
                }
            }
        }
    }
    
    private func deleteModel(offsets: IndexSet) {
        provider.models.remove(atOffsets: offsets)
    }
    
    private func fetchModels() {
        guard !provider.apiKey.isEmpty else { return }
        
        isFetchingModels = true
        fetchError = nil
        
        Task {
            do {
                let fetchedModels = try await modelFetchService.fetchModels(for: provider)
                await MainActor.run {
                    // Clear existing models and add fetched models
                    provider.models = fetchedModels
                    isFetchingModels = false
                }
            } catch {
                await MainActor.run {
                    fetchError = error.localizedDescription
                    isFetchingModels = false
                }
            }
        }
    }
}

struct AddModelView: View {
    @State private var modelName = ""
    @State private var modelIdentifier = ""
    @Environment(\.dismiss) private var dismiss
    
    let onAdd: (LLMModel) -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Model Name", text: $modelName)
                        .textContentType(.name)
                    TextField("Model Identifier", text: $modelIdentifier)
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
                        let model = LLMModel(name: modelName, identifier: modelIdentifier)
                        onAdd(model)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(modelName.isEmpty || modelIdentifier.isEmpty)
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
