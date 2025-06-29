//
//  ProvidersView.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct ProvidersView: View {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var mainViewModel = MainViewModel()
    
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
                    if mainViewModel.hasProviders {
                        VStack(spacing: 16) {
                            HStack {
                                Picker("Provider", selection: Binding(
                                    get: { mainViewModel.selectedProviderID },
                                    set: { newValue in
                                        mainViewModel.selectProvider(with: newValue)
                                    }
                                )) {
                                    ForEach(mainViewModel.activeProviders) { provider in
                                        Text(provider.name.truncated(to: 15)).tag(provider.id)
                                    }
                                }
                                .pickerStyle(.automatic)
                                .disabled(mainViewModel.activeProviders.isEmpty)
                            }
                            
                            if let provider = mainViewModel.selectedProvider, !provider.models.isEmpty {
                                HStack {
                                    Picker("Model", selection: Binding(
                                        get: { mainViewModel.selectedModelID },
                                        set: { newValue in
                                            mainViewModel.selectModel(with: newValue, from: provider)
                                        }
                                    )) {
                                        ForEach(provider.models) { model in
                                            Text(model.effectiveName).tag(model.id)
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
                    Text("Watch Default Selection")
                } footer: {
                    Text("Set the default AI provider and model that will be used on Apple Watch.")
                }
                
                Section {
                    ForEach(mainViewModel.apiProviders) { provider in
                        NavigationLink(destination: APIProviderDetailView(provider: provider)) {
                            HStack {
                                Circle()
                                    .fill(provider.isActive ? .green : .gray)
                                    .frame(width: 8, height: 8)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(provider.name.truncated(to: 15))
                                        .font(.headline)
                                    HStack(spacing: 4) {
                                        if mainViewModel.isRefreshing(provider) {
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
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                mainViewModel.deleteProvider(provider)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .contextMenu {
                            Button {
                                mainViewModel.refreshModels(for: provider)
                            } label: {
                                Label("Refresh Models", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .disabled(!mainViewModel.canRefreshModels(for: provider))
                        }
                    }
                    .onDelete { indexSet in
                        let providers = indexSet.map { mainViewModel.apiProviders[$0] }
                        for provider in providers {
                            mainViewModel.deleteProvider(provider)
                        }
                    }
                    
                    Button(action: mainViewModel.showAddProvider) {
                        Label("Add API Provider", systemImage: "plus.circle.fill")
                            .foregroundStyle(.blue)
                    }
                } header: {
                    Text("API Providers (\(mainViewModel.apiProviders.count))")
                } footer: {
                    Text("Configured APIs will sync to Apple Watch. Long press API provider to refresh model list.")
                }
            }
            .navigationTitle("LLM Wherever")
            .sheet(isPresented: $mainViewModel.showingAddProvider) {
                AddAPIProviderView()
            }
        }
    }
}

#Preview {
    ProvidersView()
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
