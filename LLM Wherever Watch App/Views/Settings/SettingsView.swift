//
//  SettingsView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    @ObservedObject private var ttsService = TTSService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TTSSettingsView(ttsService: ttsService)
                } header: {
                    Text("Text-to-Speech")
                }
                
                Section {
                    ForEach(connectivityManager.apiProviders) { provider in
                        ProviderRowView(
                            provider: provider,
                            isSelected: connectivityManager.selectedProvider?.id == provider.id,
                            onTap: {
                                connectivityManager.selectProvider(provider)
                            }
                        )
                    }
                } header: {
                    Text("API Providers")
                }
                
                if let selectedProvider = connectivityManager.selectedProvider,
                   !selectedProvider.models.isEmpty {
                    Section {
                        ForEach(selectedProvider.models) { model in
                            ModelRowView(
                                model: model,
                                isSelected: connectivityManager.selectedModel?.id == model.id,
                                onTap: {
                                    connectivityManager.selectModel(model)
                                }
                            )
                        }
                    } header: {
                        Text("Models")
                    }
                }
                
                Section {
                    ConnectionStatusView(
                        isConnected: connectivityManager.isConnected,
                        isSyncing: connectivityManager.isSyncing,
                        hasProviders: !connectivityManager.apiProviders.isEmpty
                    )
                } header: {
                    Text("Connection Status")
                }
            }
            .safeAreaInset(edge: .bottom) {
                Spacer().frame(height: 28)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.caption)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
