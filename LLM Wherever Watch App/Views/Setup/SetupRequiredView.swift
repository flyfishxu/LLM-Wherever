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
                WatchSetupInstructionView(hasProviders: hasAnyProviders)
                
                WatchConnectionStatusView(
                    isConnected: isConnected,
                    isSyncing: isSyncing,
                    hasProviders: hasAnyProviders
                )
            }
        }
        .padding(.horizontal, 12)
    }
    

}

#Preview {
    VStack(spacing: 20) {
        SetupRequiredView(isConnected: false, hasAnyProviders: false, isSyncing: false)
        SetupRequiredView(isConnected: true, hasAnyProviders: false, isSyncing: true)
        SetupRequiredView(isConnected: true, hasAnyProviders: true, isSyncing: false)
    }
} 
