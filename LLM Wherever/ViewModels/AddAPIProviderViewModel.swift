//
//  AddAPIProviderViewModel.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/1/16.
//

import Foundation

@MainActor
class AddAPIProviderViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedTemplate: ProviderTemplate?
    @Published var customName = ""
    @Published var customBaseURL = ""
    @Published var apiKey = ""
    @Published var systemPrompt = "Hello, how can I help you"
    @Published var isCustomProvider = false
    @Published var fetchedModels: [LLMModel] = []
    @Published var isFetchingModels = false
    @Published var fetchError: String?
    @Published var hasFetchedModels = false
    
    // MARK: - Dependencies
    private let connectivityManager: WatchConnectivityManager
    private let modelFetchService: ModelFetchService
    private var autoFetchTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(
        connectivityManager: WatchConnectivityManager = WatchConnectivityManager.shared,
        modelFetchService: ModelFetchService = ModelFetchService.shared
    ) {
        self.connectivityManager = connectivityManager
        self.modelFetchService = modelFetchService
        
        setupAPIKeyObserver()
    }
    
    deinit {
        autoFetchTask?.cancel()
    }
    
    // MARK: - Public Methods
    func selectTemplate(_ template: ProviderTemplate) {
        selectedTemplate = template
        isCustomProvider = template == .custom
        
        if template != .custom {
            customName = template.displayName
            customBaseURL = template.baseURL
        } else {
            customName = ""
            customBaseURL = ""
        }
        
        // Reset fetch status when template changes
        resetFetchStatus()
    }
    
    func updateAPIKey(_ newValue: String) {
        apiKey = newValue
        
        // Reset fetch status when API Key changes
        resetFetchStatus()
        
        // Cancel previous auto-fetch task
        autoFetchTask?.cancel()
        
        // Auto-fetch models after 1.5 seconds if conditions are met
        if shouldAutoFetch() {
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
    
    func fetchModels() {
        guard canFetchModels else { return }
        
        isFetchingModels = true
        fetchError = nil
        
        let provider = createCurrentProvider()
        
        Task {
            do {
                let models = try await modelFetchService.fetchModels(for: provider)
                await MainActor.run {
                    fetchedModels = models
                    isFetchingModels = false
                    hasFetchedModels = true
                }
            } catch {
                await MainActor.run {
                    fetchError = error.localizedDescription
                    isFetchingModels = false
                }
            }
        }
    }
    
    func addProvider() {
        guard canAddProvider else { return }
        
        let models = hasFetchedModels ? fetchedModels : (selectedTemplate?.defaultModels ?? [])
        
        let newProvider = APIProvider(
            name: customName,
            baseURL: customBaseURL,
            apiKey: apiKey,
            models: models,
            isActive: true,
            systemPrompt: systemPrompt
        )
        
        connectivityManager.addAPIProvider(newProvider)
    }
    
    func clearFetchError() {
        fetchError = nil
    }
    
    // MARK: - Private Methods
    private func setupAPIKeyObserver() {
        // This would be handled by SwiftUI's onChange in the View
    }
    
    private func resetFetchStatus() {
        hasFetchedModels = false
        fetchedModels = []
        fetchError = nil
    }
    
    private func shouldAutoFetch() -> Bool {
        return apiKey.count > 10 && !customName.isEmpty && !customBaseURL.isEmpty
    }
    
    private func createCurrentProvider() -> APIProvider {
        return APIProvider(
            name: customName,
            baseURL: customBaseURL,
            apiKey: apiKey,
            models: [],
            isActive: true,
            systemPrompt: systemPrompt
        )
    }
}

// MARK: - Computed Properties
extension AddAPIProviderViewModel {
    var canFetchModels: Bool {
        !apiKey.isEmpty && !customName.isEmpty && !customBaseURL.isEmpty && !isFetchingModels
    }
    
    var canAddProvider: Bool {
        !customName.isEmpty && !customBaseURL.isEmpty && !apiKey.isEmpty
    }
    
    var showFetchButton: Bool {
        !apiKey.isEmpty && !customName.isEmpty && !customBaseURL.isEmpty
    }
    
    var fetchButtonIcon: String {
        if isFetchingModels {
            return "arrow.triangle.2.circlepath"
        } else if hasFetchedModels {
            return "checkmark.circle.fill"
        } else {
            return "arrow.triangle.2.circlepath"
        }
    }
    
    var fetchButtonColor: String {
        if hasFetchedModels {
            return "green"
        } else {
            return "blue"
        }
    }
    
    var fetchButtonText: String {
        if isFetchingModels {
            return "Fetching models..."
        } else if hasFetchedModels {
            return "Re-fetch models"
        } else {
            return "Fetch available models"
        }
    }
}

// MARK: - ProviderTemplate
extension AddAPIProviderViewModel {
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
} 