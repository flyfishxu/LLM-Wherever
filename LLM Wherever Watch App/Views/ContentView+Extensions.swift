//
//  ContentView+Extensions.swift
//  LLM Wherever Watch App
//
//  Created by AI Assistant on 2025/6/29.
//

import SwiftUI
import WatchKit

// MARK: - Message Handling
extension ContentView {
    func initializeChatWithSystemPrompt() {
        // Only add system prompt if chat is empty
        guard chatMessages.isEmpty,
              let provider = connectivityManager.selectedProvider else { return }
        
        let modelName = connectivityManager.selectedModel?.name ?? "AI Assistant"
        let systemMessage = ChatMessage(
            role: .assistant, 
            content: provider.systemPrompt,
            modelInfo: "\(modelName) - System"
        )
        chatMessages.append(systemMessage)
    }
    
    func resetChatWithNewSystemPrompt() {
        // Clear existing chat messages
        chatMessages.removeAll()
        // Initialize with new system prompt
        initializeChatWithSystemPrompt()
    }
    
    func sendTextMessage(_ text: String) {
        let messageText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        
        sendMessage(messageText)
    }
    
    func sendMessage(_ messageText: String) {
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
            // Real-time update during streaming
            if let messageId = self.streamingMessageId,
               let index = self.chatMessages.firstIndex(where: { $0.id == messageId }) {
                var updatedMessage = self.chatMessages[index]
                updatedMessage.content = partialContent
                self.chatMessages[index] = updatedMessage
            }
        } onThinkingComplete: { thinkingContent, thinkingDuration in
            // Called when thinking ends (first token received)
            if let messageId = self.streamingMessageId,
               let index = self.chatMessages.firstIndex(where: { $0.id == messageId }) {
                var updatedMessage = self.chatMessages[index]
                updatedMessage.thinkingContent = thinkingContent
                updatedMessage.thinkingDuration = thinkingDuration
                self.chatMessages[index] = updatedMessage
            }
        } onComplete: { finalContent in
            // Complete response
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