//
//  ContentView.swift
//  LLM Wherever
//
//  Created by 徐义超 on 2025/6/29.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var modelFetchService = ModelFetchService.shared
    @State private var showingAddProvider = false
    @State private var refreshingProviders: Set<UUID> = []
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "applewatch")
                            .foregroundStyle(.blue)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text("LLM Wherever")
                                .font(.headline)
                            Text("Use Large Language Models on Apple Watch")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("App Introduction")
                }
                
                Section {
                    if !connectivityManager.apiProviders.isEmpty {
                        VStack(spacing: 16) {
                            HStack {
                                Picker("Provider", selection: Binding(
                                    get: { connectivityManager.selectedProvider?.id ?? UUID() },
                                    set: { newValue in
                                        if let provider = connectivityManager.apiProviders.first(where: { $0.id == newValue }) {
                                            connectivityManager.selectProvider(provider)
                                        }
                                    }
                                )) {
                                    ForEach(connectivityManager.apiProviders.filter(\.isActive)) { provider in
                                        Text(provider.name.truncated(to: 15)).tag(provider.id)
                                    }
                                }
                                .pickerStyle(.automatic)
                                .disabled(connectivityManager.apiProviders.filter(\.isActive).isEmpty)
                            }
                            
                            if let provider = connectivityManager.selectedProvider, !provider.models.isEmpty {
                                HStack {
                                    Picker("Model", selection: Binding(
                                        get: { connectivityManager.selectedModel?.id ?? UUID() },
                                        set: { newValue in
                                            if let model = provider.models.first(where: { $0.id == newValue }) {
                                                connectivityManager.selectModel(model)
                                            }
                                        }
                                    )) {
                                        ForEach(provider.models) { model in
                                            Text(model.name).tag(model.id)
                                        }
                                    }
                                    .pickerStyle(.automatic)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } else {
                        Text("No API providers configured")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    }
                } header: {
                    Text("Default Settings")
                } footer: {
                    Text("Set the default AI provider and model that will be used on Apple Watch. These settings will sync automatically.")
                }
                
                Section {
                    ForEach(connectivityManager.apiProviders) { provider in
                        NavigationLink(destination: APIProviderDetailView(provider: provider)) {
                            HStack {
                                Circle()
                                    .fill(provider.isActive ? .green : .gray)
                                    .frame(width: 8, height: 8)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(provider.name.truncated(to: 15))
                                        .font(.headline)
                                    HStack(spacing: 4) {
                                        if refreshingProviders.contains(provider.id) {
                                            ProgressView()
                                                .controlSize(.mini)
                                            Text("Refreshing...")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        } else {
                                            Text("\(provider.models.count) models")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                connectivityManager.deleteAPIProvider(provider)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                refreshModels(for: provider)
                            } label: {
                                Label("Refresh Models", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .disabled(provider.apiKey.isEmpty)
                        }
                    }
                    .onDelete(perform: deleteProvider)
                    
                    Button(action: { showingAddProvider = true }) {
                        Label("Add API Provider", systemImage: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                } header: {
                    Text("API Configuration")
                } footer: {
                    Text("Configured APIs will sync to Apple Watch. Long press API provider to refresh model list.")
                }
            }
            .navigationTitle("LLM Wherever")
            .sheet(isPresented: $showingAddProvider) {
                AddAPIProviderView()
            }
        }
    }
    
    private func deleteProvider(offsets: IndexSet) {
        for offset in offsets {
            let provider = connectivityManager.apiProviders[offset]
            connectivityManager.deleteAPIProvider(provider)
        }
    }
    
    private func refreshModels(for provider: APIProvider) {
        guard !provider.apiKey.isEmpty else { return }
        
        refreshingProviders.insert(provider.id)
        
        Task {
            do {
                let fetchedModels = try await modelFetchService.fetchModels(for: provider)
                await MainActor.run {
                    // Update model list
                    var updatedProvider = provider
                    updatedProvider.models = fetchedModels
                    connectivityManager.updateAPIProvider(updatedProvider)
                    refreshingProviders.remove(provider.id)
                }
            } catch {
                await MainActor.run {
                    refreshingProviders.remove(provider.id)
                    // Error handling can be added here, but simplified for now
                    print("Failed to refresh models: \(error)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

extension String {
    func truncated(to length: Int) -> String {
        if self.count <= length {
            return self
        } else {
            return String(self.prefix(length)) + "..."
        }
    }
}
