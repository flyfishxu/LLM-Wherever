//
//  ConnectionStatusView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct ConnectionStatusView: View {
    let isConnected: Bool
    let isSyncing: Bool
    let hasProviders: Bool
    
    var body: some View {
        Group {
            if !isConnected {
                statusBadge(
                    icon: "exclamationmark.triangle.fill",
                    text: "iPhone not connected",
                    color: .orange
                )
            } else if isSyncing {
                statusBadge(
                    icon: nil,
                    text: "Syncing...",
                    color: .blue,
                    showProgress: true
                )
            } else if hasProviders {
                statusBadge(
                    icon: "checkmark.circle.fill",
                    text: "Connected",
                    color: .green
                )
            } else {
                statusBadge(
                    icon: "checkmark.circle.fill",
                    text: "Waiting for config...",
                    color: .green
                )
            }
        }
    }
    
    private func statusBadge(
        icon: String?,
        text: String,
        color: Color,
        showProgress: Bool = false
    ) -> some View {
        HStack(spacing: 4) {
            if showProgress {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 12, height: 12)
            } else if let icon = icon {
                Image(systemName: icon)
                    .font(.caption2)
            }
            
            Text(text)
                .font(.caption2)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
    }
}

#Preview {
    VStack(spacing: 10) {
        ConnectionStatusView(isConnected: false, isSyncing: false, hasProviders: false)
        ConnectionStatusView(isConnected: true, isSyncing: true, hasProviders: false)
        ConnectionStatusView(isConnected: true, isSyncing: false, hasProviders: true)
        ConnectionStatusView(isConnected: true, isSyncing: false, hasProviders: false)
    }
}
