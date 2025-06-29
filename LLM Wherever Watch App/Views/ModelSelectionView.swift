//
//  ModelSelectionView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/29.
//

import SwiftUI

struct ModelSelectionView: View {
    let apiProviders: [APIProvider]
    let onProviderSelected: (APIProvider) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text("Select Model")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if apiProviders.count == 1, let provider = apiProviders.first {
                singleProviderView(provider)
            } else if apiProviders.count > 1 {
                multipleProvidersView
            }
        }
        .padding(.horizontal, 12)
    }
    
    private func singleProviderView(_ provider: APIProvider) -> some View {
        Button {
            onProviderSelected(provider)
        } label: {
            VStack(spacing: 2) {
                Text(provider.name)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(provider.models.count) models")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
    }
    
    private var multipleProvidersView: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(apiProviders) { provider in
                    Button {
                        onProviderSelected(provider)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(provider.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text("\(provider.models.count) models")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxHeight: 120)
    }
}

#Preview {
    ModelSelectionView(
        apiProviders: [
            APIProvider(name: "OpenAI", baseURL: "", apiKey: "", models: [
                LLMModel(name: "GPT-4", identifier: "gpt-4")
            ])
        ],
        onProviderSelected: { _ in }
    )
} 