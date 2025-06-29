//
//  ContentView.swift
//  LLM Wherever Watch App
//
//  Created by 徐义超 on 2025/6/29.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject internal var connectivityManager = WatchConnectivityManager.shared
    @StateObject internal var llmService = LLMService.shared
    @State internal var chatMessages: [ChatMessage] = []
    @State internal var inputText = ""
    @State internal var isLoading = false
    @State private var showingSettings = false
    @State internal var errorMessage: String?

    @State internal var streamingMessageId: UUID?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if connectivityManager.apiProviders.isEmpty {
                    SetupRequiredView(isConnected: connectivityManager.isConnected)
                } else if connectivityManager.selectedProvider == nil || connectivityManager.selectedModel == nil {
                    ModelSelectionView(
                        apiProviders: connectivityManager.apiProviders,
                        onProviderSelected: { provider in
                            connectivityManager.selectProvider(provider)
                        }
                    )
                } else {
                    WatchChatView(
                        chatMessages: $chatMessages,
                        inputText: $inputText,
                        isLoading: $isLoading,
                        errorMessage: $errorMessage,
                        onSendMessage: sendTextMessage
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.caption)
                    }
                    .disabled(connectivityManager.apiProviders.isEmpty)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    ContentView()
}
