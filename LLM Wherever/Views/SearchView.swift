//
//  SearchView.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @State private var searchText = ""
    
    // Get all models from all providers
    var allModels: [(model: LLMModel, provider: APIProvider)] {
        connectivityManager.apiProviders.flatMap { provider in
            provider.models.map { model in
                (model: model, provider: provider)
            }
        }
    }
    
    // Filter models based on search text
    var filteredModels: [(model: LLMModel, provider: APIProvider)] {
        if searchText.isEmpty {
            return allModels
        } else {
            return allModels.filter { item in
                item.model.effectiveName.localizedCaseInsensitiveContains(searchText) ||
                item.model.identifier.localizedCaseInsensitiveContains(searchText) ||
                item.model.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if filteredModels.isEmpty {
                    if searchText.isEmpty {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            Text("Enter a search term to find models")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    } else {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            Text("No models match '\(searchText)'")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    ForEach(filteredModels, id: \.model.id) { item in
                        NavigationLink {
                            if let providerIndex = connectivityManager.apiProviders.firstIndex(where: { $0.id == item.provider.id }),
                               let modelIndex = connectivityManager.apiProviders[providerIndex].models.firstIndex(where: { $0.id == item.model.id }) {
                                ModelConfigurationView(
                                    model: $connectivityManager.apiProviders[providerIndex].models[modelIndex]
                                )
                            }
                        } label: {
                            ModelRowView(
                                model: item.model,
                                providerName: item.provider.name
                            )
                        }
                    }
                }
            }
            .navigationTitle("Search Models")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        }
    }
}

#Preview {
    SearchView()
} 
