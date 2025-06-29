//
//  SetupRequiredView.swift
//  LLM Wherever Watch App
//
//  Created by AI Assistant on 2025/6/29.
//

import SwiftUI

struct SetupRequiredView: View {
    let isConnected: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.and.apple.watch")
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text("Setup Required")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Please configure API and select default model on iPhone")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            if !isConnected {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text("iPhone not connected")
                        .font(.caption2)
                }
                .foregroundStyle(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 12)
    }
}

#Preview {
    SetupRequiredView(isConnected: false)
} 