//
//  ModelRowView.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct ModelRowView: View {
    let model: LLMModel
    let providerName: String?
    
    init(model: LLMModel, providerName: String? = nil) {
        self.model = model
        self.providerName = providerName
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.effectiveName)
                    .font(.headline)
                
                Text(model.identifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Show provider name if provided
                if let providerName = providerName {
                    Text("from \(providerName)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                
                // Show configuration status
                HStack {
                    if model.useCustomSettings {
                        Text("Custom Settings")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }
}

#Preview {
    List {
        ModelRowView(
            model: LLMModel(name: "GPT-4", identifier: "gpt-4"),
            providerName: "OpenAI"
        )
        
        ModelRowView(
            model: LLMModel(name: "Claude-3", identifier: "claude-3-sonnet-20240229")
        )
    }
} 
