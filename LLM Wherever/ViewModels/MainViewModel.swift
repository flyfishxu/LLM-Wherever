//
//  MainViewModel.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/1/16.
//

import Foundation

@MainActor
class MainViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var showingAddProvider = false
    @Published var refreshingProviders: Set<UUID> = []
    
    // MARK: - Dependencies
    private let connectivityManager: WatchConnectivityManager
    private let modelFetchService: ModelFetchService
    
    // MARK: - Initialization
    init(
        connectivityManager: WatchConnectivityManager = WatchConnectivityManager.shared,
        modelFetchService: ModelFetchService = ModelFetchService.shared
    ) {
        self.connectivityManager = connectivityManager
        self.modelFetchService = modelFetchService
    }
    
    // MARK: - Public Methods
    func showAddProvider() {
        showingAddProvider = true
    }
    
    func hideAddProvider() {
        showingAddProvider = false
    }
    
    func deleteProvider(at offsets: IndexSet) {
        for offset in offsets {
            let provider = connectivityManager.apiProviders[offset]
            connectivityManager.deleteAPIProvider(provider)
        }
    }
    
    func deleteProvider(_ provider: APIProvider) {
        connectivityManager.deleteAPIProvider(provider)
    }
    
    func selectProvider(with id: UUID) {
        if let provider = connectivityManager.apiProviders.first(where: { $0.id == id }) {
            connectivityManager.selectProvider(provider)
        }
    }
    
    func selectModel(with id: UUID, from provider: APIProvider) {
        if let model = provider.models.first(where: { $0.id == id }) {
            connectivityManager.selectModel(model)
        }
    }
    
    func refreshModels(for provider: APIProvider) {
        guard !provider.apiKey.isEmpty else { return }
        guard !refreshingProviders.contains(provider.id) else { return }
        
        refreshingProviders.insert(provider.id)
        
        Task {
            do {
                let fetchedModels = try await modelFetchService.fetchModels(for: provider)
                await MainActor.run {
                    var updatedProvider = provider
                    updatedProvider.models = fetchedModels
                    connectivityManager.updateAPIProvider(updatedProvider)
                    refreshingProviders.remove(provider.id)
                }
            } catch {
                await MainActor.run {
                    refreshingProviders.remove(provider.id)
                    print("Failed to refresh models: \(error)")
                }
            }
        }
    }
}

// MARK: - Computed Properties
extension MainViewModel {
    var apiProviders: [APIProvider] {
        connectivityManager.apiProviders
    }
    
    var selectedProvider: APIProvider? {
        connectivityManager.selectedProvider
    }
    
    var selectedModel: LLMModel? {
        connectivityManager.selectedModel
    }
    
    var activeProviders: [APIProvider] {
        connectivityManager.apiProviders.filter(\.isActive)
    }
    
    var hasProviders: Bool {
        !connectivityManager.apiProviders.isEmpty
    }
    
    var selectedProviderID: UUID {
        connectivityManager.selectedProvider?.id ?? UUID()
    }
    
    var selectedModelID: UUID {
        connectivityManager.selectedModel?.id ?? UUID()
    }
    
    func isRefreshing(_ provider: APIProvider) -> Bool {
        refreshingProviders.contains(provider.id)
    }
    
    func canRefreshModels(for provider: APIProvider) -> Bool {
        !provider.apiKey.isEmpty && !refreshingProviders.contains(provider.id)
    }
} 