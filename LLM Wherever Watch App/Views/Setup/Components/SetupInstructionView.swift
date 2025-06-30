//
//  SetupInstructionView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct SetupInstructionView: View {
    let hasProviders: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            if !hasProviders {
                Text("First Time Setup")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                
                Text("Please open LLM Wherever app on your iPhone to add API configurations")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    instructionStep(number: "1.", text: "Add API Provider")
                    instructionStep(number: "2.", text: "Select Default Model")
                    instructionStep(number: "3.", text: "Config syncs automatically")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            } else {
                Text("Please complete API configuration and select default model on iPhone")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func instructionStep(number: String, text: String) -> some View {
        HStack {
            Text(number)
                .fontWeight(.medium)
            Text(text)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SetupInstructionView(hasProviders: false)
        SetupInstructionView(hasProviders: true)
    }
    .padding()
} 
