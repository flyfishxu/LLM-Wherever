//
//  SetupRequiredView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/29.
//

import SwiftUI

struct SetupRequiredView: View {
    let isConnected: Bool
    let hasAnyProviders: Bool
    let isSyncing: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                if !hasAnyProviders {
                    setupInstructionView
                } else {
                    configurationNeededView
                }
                
                connectionStatusView
            }
        }
        .padding(.horizontal, 12)
    }
    
    private var setupInstructionView: some View {
        VStack(spacing: 8) {
            Text("First Time Setup")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.blue)
            
            Text("Please open LLM Wherever app on your iPhone to add API configurations")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("1.")
                        .fontWeight(.medium)
                    Text("Add API Provider")
                }
                HStack {
                    Text("2.")
                        .fontWeight(.medium)
                    Text("Select Default Model")
                }
                HStack {
                    Text("3.")
                        .fontWeight(.medium)
                    Text("Config syncs automatically")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
    
    private var configurationNeededView: some View {
        Text("Please complete API configuration and select default model on iPhone")
            .font(.caption)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
    }
    
    private var connectionStatusView: some View {
        Group {
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
            } else if isSyncing {
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 12, height: 12)
                    Text("Syncing...")
                        .font(.caption2)
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption2)
                    Text("Connected, waiting for config...")
                        .font(.caption2)
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SetupRequiredView(isConnected: false, hasAnyProviders: false, isSyncing: false)
        SetupRequiredView(isConnected: true, hasAnyProviders: false, isSyncing: true)
        SetupRequiredView(isConnected: true, hasAnyProviders: true, isSyncing: false)
    }
} 
