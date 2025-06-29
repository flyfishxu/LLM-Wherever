//
//  MainViewModel.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import Foundation

@MainActor
class MainViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var showingSettings = false
    
    // MARK: - Dependencies
    private let connectivityManager: WatchConnectivityManager
    
    // MARK: - Initialization
    init(connectivityManager: WatchConnectivityManager = WatchConnectivityManager.shared) {
        self.connectivityManager = connectivityManager
    }
    
    // MARK: - Public Methods
    func toggleSettings() {
        showingSettings.toggle()
    }
    
    func openSettings() {
        showingSettings = true
    }
    
    func closeSettings() {
        showingSettings = false
    }
}

// MARK: - Computed Properties
extension MainViewModel {
    var canShowSettings: Bool {
        !connectivityManager.apiProviders.isEmpty
    }
    
    var isSetupRequired: Bool {
        connectivityManager.apiProviders.isEmpty ||
        connectivityManager.selectedProvider == nil ||
        connectivityManager.selectedModel == nil
    }
} 