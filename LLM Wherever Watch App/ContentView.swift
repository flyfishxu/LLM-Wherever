//
//  ContentView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/29.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var mainViewModel = MainViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if chatViewModel.isSetupRequired {
                    SetupRequiredView(
                        isConnected: connectivityManager.isConnected,
                        hasAnyProviders: !connectivityManager.apiProviders.isEmpty,
                        isSyncing: connectivityManager.isSyncing
                    )
                } else {
                    WatchChatView(
                        chatMessages: $chatViewModel.chatMessages,
                        inputText: $chatViewModel.inputText,
                        isLoading: $chatViewModel.isLoading,
                        errorMessage: $chatViewModel.errorMessage,
                        onSendMessage: chatViewModel.sendTextMessage,
                        onClearError: chatViewModel.clearError
                    )
                    .onAppear {
                        chatViewModel.initializeChatWithSystemPrompt()
                    }
                    .onChange(of: connectivityManager.selectedProvider?.id) { _, _ in
                        chatViewModel.resetChatWithNewSystemPrompt()
                    }
                    .onChange(of: connectivityManager.selectedModel?.id) { _, _ in
                        chatViewModel.resetChatWithNewSystemPrompt()
                    }
                }
            }
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
