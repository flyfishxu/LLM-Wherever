//
//  ProviderRowView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct ProviderRowView: View {
    let provider: APIProvider
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text("\(provider.models.count) models")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    List {
        ProviderRowView(
            provider: APIProvider(name: "OpenAI", baseURL: "", apiKey: "", models: []),
            isSelected: true,
            onTap: { }
        )
        ProviderRowView(
            provider: APIProvider(name: "Anthropic", baseURL: "", apiKey: "", models: []),
            isSelected: false,
            onTap: { }
        )
    }
} 
