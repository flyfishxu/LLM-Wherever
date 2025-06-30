//
//  ModelRowView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct ModelRowView: View {
    let model: LLMModel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.effectiveName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(model.identifier)
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
        ModelRowView(
            model: LLMModel(name: "GPT-4", identifier: "gpt-4"),
            isSelected: true,
            onTap: { }
        )
        ModelRowView(
            model: LLMModel(name: "GPT-3.5", identifier: "gpt-3.5-turbo"),
            isSelected: false,
            onTap: { }
        )
    }
} 
