//
//  ContentView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var mainViewModel = MainViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    @StateObject private var historyManager = HistoryManager.shared
    
    var body: some View {
        Group {
            if chatViewModel.isSetupRequired {
                NavigationStack {
                    SetupRequiredView(
                        isConnected: connectivityManager.isConnected,
                        hasAnyProviders: !connectivityManager.apiProviders.isEmpty,
                        isSyncing: connectivityManager.isSyncing
                    )
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                mainViewModel.openSettings()
                            } label: {
                                Image(systemName: "gear")
                                    .font(.caption)
                            }
                            .disabled(!mainViewModel.canShowSettings)
                        }
                    }
                    .sheet(isPresented: $mainViewModel.showingSettings) {
                        SettingsView()
                    }
                }
            } else {
                // Main History View with Navigation
                HistoryView()
            }
        }
        .alert("Error", isPresented: .constant(chatViewModel.errorMessage != nil)) {
            Button("OK") {
                chatViewModel.clearError()
            }
        } message: {
            if let errorMessage = chatViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    ContentView()
}
