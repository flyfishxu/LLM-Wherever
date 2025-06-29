//
//  AddAPIProviderView.swift
//  LLM Wherever
//
//  Created by 徐义超 on 2025/1/16.
//

import SwiftUI

struct AddAPIProviderView: View {
    @State private var selectedTemplate: ProviderTemplate?
    @State private var customName = ""
    @State private var customBaseURL = ""
    @State private var apiKey = ""
    @State private var systemPrompt = "Hello, how can I help you"
    @State private var isCustomProvider = false
    @State private var fetchedModels: [LLMModel] = []
    @State private var isFetchingModels = false
    @State private var fetchError: String?
    @State private var hasFetchedModels = false
    @State private var autoFetchTask: Task<Void, Never>?
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var modelFetchService = ModelFetchService.shared
    
    enum ProviderTemplate: String, CaseIterable, Identifiable {
        case openai = "OpenAI"
        case anthropic = "Anthropic"
        case custom = "Custom"
        
        var id: String { rawValue }
        
        var displayName: String { rawValue }
        
        var icon: String {
            switch self {
            case .openai: return "brain.head.profile"
            case .anthropic: return "sparkles"
            case .custom: return "gearshape"
            }
        }
        
        var baseURL: String {
            switch self {
            case .openai: return "https://api.openai.com/v1"
            case .anthropic: return "https://api.anthropic.com/v1"
            case .custom: return ""
            }
        }
        
        var defaultModels: [LLMModel] {
            switch self {
            case .openai:
                return [
                    LLMModel(name: "GPT-4", identifier: "gpt-4"),
                    LLMModel(name: "GPT-3.5 Turbo", identifier: "gpt-3.5-turbo")
                ]
            case .anthropic:
                return [
                    LLMModel(name: "Claude 3.5 Sonnet", identifier: "claude-3-5-sonnet-20241022"),
                    LLMModel(name: "Claude 3 Haiku", identifier: "claude-3-haiku-20240307")
                ]
            case .custom:
                return []
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(ProviderTemplate.allCases) { template in
                        Button(action: {
                            selectedTemplate = template
                            isCustomProvider = template == .custom
                            if template != .custom {
                                customName = template.displayName
                                customBaseURL = template.baseURL
                            } else {
                                customName = ""
                                customBaseURL = ""
                            }
                        }) {
                            HStack {
                                Image(systemName: template.icon)
                                    .foregroundStyle(.blue)
                                    .frame(width: 24)
                                
                                Text(template.displayName)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if selectedTemplate == template {
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
                
                if selectedTemplate != nil {
                    Section {
                        if isCustomProvider {
                            TextField("Name", text: $customName)
                            TextField("Base URL", text: $customBaseURL)
                                .keyboardType(.URL)
                                .textContentType(.URL)
                        } else {
                            HStack {
                                Text("Name")
                                Spacer()
                                Text(customName)
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Text("Base URL")
                                Spacer()
                                Text(customBaseURL)
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                        
                        HStack {
                            SecureField("API Key", text: $apiKey)
                                .textContentType(.password)
                                .onChange(of: apiKey) { _, newValue in
                                    // Reset fetch status when API Key changes
                                    hasFetchedModels = false
                                    fetchedModels = []
                                    fetchError = nil
                                    
                                    // Cancel previous auto-fetch task
                                    autoFetchTask?.cancel()
                                    
                                    // Auto-fetch models after 1.5 seconds if API Key length is reasonable and other fields are filled
                                    if newValue.count > 10 && !customName.isEmpty && !customBaseURL.isEmpty {
                                        autoFetchTask = Task {
                                            try? await Task.sleep(for: .seconds(1.5))
                                            if !Task.isCancelled && !isFetchingModels && !hasFetchedModels {
                                                await MainActor.run {
                                                    fetchModels()
                                                }
                                            }
                                        }
                                    }
                                }
                            
                            // Fetch models button - right next to API Key input field
                            if !apiKey.isEmpty && !customName.isEmpty && !customBaseURL.isEmpty {
                                Button(action: {
                                    fetchModels()
                                }) {
                                    Group {
                                        if isFetchingModels {
                                            ProgressView()
                                                .controlSize(.small)
                                        } else if hasFetchedModels {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                        } else {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                                .disabled(isFetchingModels)
                                .buttonStyle(.bordered)
                                .help(isFetchingModels ? "Fetching models..." : 
                                     hasFetchedModels ? "Re-fetch models" : "Fetch available models")
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("System Prompt")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("Enter system prompt...", text: $systemPrompt, axis: .vertical)
                                .lineLimit(3...6)
                        }
                        
                        // Fetch status and action buttons
                        if !apiKey.isEmpty && !customName.isEmpty && !customBaseURL.isEmpty {
                            VStack(spacing: 8) {
                                // Main action button - more prominent
                                Button(action: {
                                    fetchModels()
                                }) {
                                    HStack {
                                        if isFetchingModels {
                                            ProgressView()
                                                .controlSize(.small)
                                            Text("Fetching models...")
                                        } else if hasFetchedModels {
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
                                .disabled(isFetchingModels)
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            }
                        }
                        
                        // Display fetch results
                        if hasFetchedModels {
                            if fetchedModels.isEmpty {
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
                                        Text("Found \(fetchedModels.count) models")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Spacer()
                                    }
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ForEach(fetchedModels.prefix(6)) { model in
                                                Text(model.name)
                                                    .font(.caption2)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(.blue.opacity(0.1))
                                                    .foregroundStyle(.blue)
                                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                            }
                                            
                                            if fetchedModels.count > 6 {
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
                        if let error = fetchError {
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
                        if selectedTemplate == .custom {
                            Text("Enter the configuration information for your custom API provider. The API Key will be stored securely. The system prompt will be shown as the first message when starting a conversation on Apple Watch.")
                        } else {
                            Text("Enter your API Key and customize the system prompt. Tap the button to test connection and automatically fetch available models. The system prompt will be shown as the first message when starting a conversation on Apple Watch.")
                        }
                    }
                }
            }
            .navigationTitle("Add API Provider")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProvider()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var canSave: Bool {
        !customName.isEmpty && !customBaseURL.isEmpty && !apiKey.isEmpty
    }
    
    private func saveProvider() {
        var models = fetchedModels
        
        // If no models were fetched, use default models for preset providers
        if models.isEmpty && selectedTemplate != .custom {
            models = selectedTemplate?.defaultModels ?? []
        }
        
        let provider = APIProvider(
            name: customName,
            baseURL: customBaseURL,
            apiKey: apiKey,
            models: models,
            isActive: true,
            systemPrompt: systemPrompt
        )
        
        connectivityManager.addAPIProvider(provider)
        dismiss()
    }
    
    private func fetchModels() {
        guard !apiKey.isEmpty && !customBaseURL.isEmpty else { return }
        
        isFetchingModels = true
        fetchError = nil
        
        let tempProvider = APIProvider(
            name: customName.isEmpty ? "Temp" : customName,
            baseURL: customBaseURL,
            apiKey: apiKey,
            models: [],
            isActive: false
        )
        
        Task {
            do {
                let models = try await modelFetchService.fetchModels(for: tempProvider)
                await MainActor.run {
                    fetchedModels = models
                    hasFetchedModels = true
                    isFetchingModels = false
                }
            } catch {
                await MainActor.run {
                    fetchError = error.localizedDescription
                    hasFetchedModels = true
                    isFetchingModels = false
                }
            }
        }
    }
}

#Preview {
    AddAPIProviderView()
} 