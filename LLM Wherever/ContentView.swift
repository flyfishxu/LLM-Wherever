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
                    ForEach(connectivityManager.apiProviders) { provider in
                        NavigationLink(destination: APIProviderDetailView(provider: provider)) {
                            HStack {
                                Circle()
                                    .fill(provider.isActive ? .green : .gray)
                                    .frame(width: 8, height: 8)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(provider.name)
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
                                
                                Spacer()
                                
                                if !provider.apiKey.isEmpty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                        .font(.caption)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
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
