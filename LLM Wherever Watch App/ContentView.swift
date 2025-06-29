//
//  ContentView.swift
//  LLM Wherever Watch App
//
//  Created by 徐义超 on 2025/6/29.
//

import SwiftUI
import WatchKit

struct ContentView: View {
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var llmService = LLMService.shared
    @State private var chatMessages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var showingSettings = false
    @State private var errorMessage: String?

    @State private var streamingMessageId: UUID?
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if connectivityManager.apiProviders.isEmpty {
                    setupRequiredView
                } else if connectivityManager.selectedProvider == nil || connectivityManager.selectedModel == nil {
                    modelSelectionView
                } else {
                    chatView
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
    
    private var setupRequiredView: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone.and.apple.watch")
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text("Setup Required")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Please configure API on iPhone")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            if !connectivityManager.isConnected {
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
    
    private var modelSelectionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text("Select Model")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if connectivityManager.apiProviders.count == 1,
               let provider = connectivityManager.apiProviders.first {
                Button {
                    connectivityManager.selectProvider(provider)
                } label: {
                    VStack(spacing: 2) {
                        Text(provider.name)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("\(provider.models.count) models")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else if connectivityManager.apiProviders.count > 1 {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(connectivityManager.apiProviders) { provider in
                            Button {
                                connectivityManager.selectProvider(provider)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(provider.name)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Text("\(provider.models.count) models")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(maxHeight: 120)
            }
        }
        .padding(.horizontal, 12)
    }
    
    private var chatView: some View {
        VStack(spacing: 0) {
            // Chat messages list and input button
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(chatMessages) { message in
                            WatchChatBubbleView(message: message)
                        }
                        
                        if isLoading {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .controlSize(.mini)
                                Text("AI thinking")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // Input button as part of the list
                        VStack(spacing: 12) {
                            // Separator line
                            Rectangle()
                                .fill(.gray.opacity(0.3))
                                .frame(height: 0.5)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                            
                            // Input field
                            TextField("Enter message", text: $inputText)
                                .font(.caption)
                                .focused($isTextFieldFocused)
                                .onSubmit {
                                    sendTextMessage(inputText)
                                    inputText = ""
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                            
                            Spacer()
                                .frame(height: 4)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 2)
                }
                .onChange(of: chatMessages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        if let lastMessage = chatMessages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
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
    
    private func sendTextMessage(_ text: String) {
        let messageText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        
        sendMessage(messageText)
    }
    
    private func sendMessage(_ messageText: String) {
        guard let provider = connectivityManager.selectedProvider,
              let model = connectivityManager.selectedModel else { return }
        
        let cleanedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedText.isEmpty else { return }
        
        // Send haptic feedback
        WKInterfaceDevice.current().play(.click)
        
        let userMessage = ChatMessage(role: .user, content: cleanedText)
        chatMessages.append(userMessage)
        isLoading = true
        
        // Create AI message for stream update
        let assistantMessage = ChatMessage(role: .assistant, content: "", modelInfo: model.name)
        chatMessages.append(assistantMessage)
        streamingMessageId = assistantMessage.id
        
        // Use stream transmission
        llmService.sendMessageStream(
            cleanedText,
            provider: provider,
            model: model,
            chatHistory: Array(chatMessages.dropLast(2).suffix(5)) // Exclude just added user message and empty AI message
        ) { partialContent in
            // Real-time update
            if let messageId = self.streamingMessageId,
               let index = self.chatMessages.firstIndex(where: { $0.id == messageId }) {
                var updatedMessage = self.chatMessages[index]
                updatedMessage.content = partialContent
                self.chatMessages[index] = updatedMessage
            }
        } onComplete: { finalContent in
            // Complete
            if let messageId = self.streamingMessageId,
               let index = self.chatMessages.firstIndex(where: { $0.id == messageId }) {
                var updatedMessage = self.chatMessages[index]
                updatedMessage.content = finalContent
                self.chatMessages[index] = updatedMessage
            }
            self.isLoading = false
            self.streamingMessageId = nil
            WKInterfaceDevice.current().play(.success)
        } onError: { error in
            // Error handling
            if let messageId = self.streamingMessageId,
               let index = self.chatMessages.firstIndex(where: { $0.id == messageId }) {
                // Remove failed message
                self.chatMessages.remove(at: index)
            }
            self.isLoading = false
            self.streamingMessageId = nil
            self.errorMessage = error.localizedDescription
            WKInterfaceDevice.current().play(.failure)
        }
    }
}

struct WatchChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            if message.role == .user {
                Spacer(minLength: 20)
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 1) {
                // Only show model information for AI messages
                if message.role == .assistant, let modelInfo = message.modelInfo {
                    Text(modelInfo)
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 2)
                        .padding(.bottom, 1)
                }
                
                Text(message.content)
                    .font(.caption)
                    .multilineTextAlignment(message.role == .user ? .trailing : .leading)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(message.role == .user ? .blue : .gray.opacity(0.15))
                    )
                    .foregroundStyle(message.role == .user ? .white : .primary)
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 2)
            }
            
            if message.role == .assistant {
                Spacer(minLength: 20)
            }
        }
    }
}

#Preview {
    ContentView()
}
