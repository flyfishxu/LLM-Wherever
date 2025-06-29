//
//  APIProviderDetailViewModel.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import Foundation

@MainActor
class APIProviderDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var provider: APIProvider
    @Published var showingAddModel = false
    @Published var isFetchingModels = false
    @Published var fetchError: String?
    
    // MARK: - Dependencies
    private let connectivityManager: WatchConnectivityManager
    private let modelFetchService: ModelFetchService
    
    // MARK: - Initialization
    init(
        provider: APIProvider,
        connectivityManager: WatchConnectivityManager = WatchConnectivityManager.shared,
        modelFetchService: ModelFetchService = ModelFetchService.shared
    ) {
        self.provider = provider
        self.connectivityManager = connectivityManager
        self.modelFetchService = modelFetchService
    }
    
    // MARK: - Public Methods
    func saveProvider() {
        connectivityManager.updateAPIProvider(provider)
    }
    
    func showAddModel() {
        showingAddModel = true
    }
    
    func hideAddModel() {
        showingAddModel = false
    }
    
    func addModel(_ model: LLMModel) {
        provider.models.append(model)
    }
    
    func deleteModel(at offsets: IndexSet) {
        provider.models.remove(atOffsets: offsets)
    }
    
    func deleteModel(_ model: LLMModel) {
        if let index = provider.models.firstIndex(where: { $0.id == model.id }) {
            provider.models.remove(at: index)
        }
    }
    
    func fetchModels() {
        guard canFetchModels else { return }
        
        isFetchingModels = true
        fetchError = nil
        
        Task {
            do {
                let fetchedModels = try await modelFetchService.fetchModels(for: provider)
                await MainActor.run {
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
    
    func clearFetchError() {
        fetchError = nil
    }
    
    func updateProvider(_ updatedProvider: APIProvider) {
        provider = updatedProvider
    }
}

// MARK: - Computed Properties
extension APIProviderDetailViewModel {
    var canFetchModels: Bool {
        !isFetchingModels && !provider.apiKey.isEmpty
    }
    
    var fetchButtonText: String {
        isFetchingModels ? "Fetching models..." : "Fetch models from API"
    }
    
    var hasFetchError: Bool {
        fetchError != nil
    }
    
    var fetchErrorMessage: String {
        fetchError ?? ""
    }
}

// MARK: - AddModelViewModel
@MainActor
class AddModelViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var modelName = ""
    @Published var modelIdentifier = ""
    
    // MARK: - Public Methods
    func createModel() -> LLMModel? {
        guard canCreateModel else { return nil }
        
        return LLMModel(
            name: modelName.trimmingCharacters(in: .whitespacesAndNewlines),
            identifier: modelIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
    
    func reset() {
        modelName = ""
        modelIdentifier = ""
    }
}

// MARK: - Computed Properties
extension AddModelViewModel {
    var canCreateModel: Bool {
        !modelName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !modelIdentifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
} 