//
//  WatchEmptyStateView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct WatchEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionButton: AnyView?
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        actionButton: AnyView? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionButton = actionButton
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(.blue.gradient)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionButton = actionButton {
                actionButton
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {
    WatchEmptyStateView(
        icon: "message.circle",
        title: "No Conversations",
        subtitle: "Start chatting to see history"
    )
} 