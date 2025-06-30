//
//  ChatViewModel.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import Foundation
import WatchKit

@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var chatMessages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var streamingMessageId: UUID?
    @Published var currentHistoryID: UUID? // Track current chat history
    
    // MARK: - Dependencies
    private let llmService: LLMService
    private let connectivityManager: WatchConnectivityManager
    private let historyManager: HistoryManager
    private let ttsService: TTSService
    
    // MARK: - Initialization
    init(
        llmService: LLMService? = nil,
        connectivityManager: WatchConnectivityManager? = nil,
        historyManager: HistoryManager? = nil,
        ttsService: TTSService? = nil
    ) {
        self.llmService = llmService ?? LLMService.shared
        self.connectivityManager = connectivityManager ?? WatchConnectivityManager.shared
        self.historyManager = historyManager ?? HistoryManager.shared
        self.ttsService = ttsService ?? TTSService.shared
        
        // Listen for provider and model changes
        setupObservers()
    }
    
    // MARK: - Public Methods
    func initializeChatWithSystemPrompt() {
        // Only add system prompt if chat is empty
        guard chatMessages.isEmpty,
              let _ = connectivityManager.selectedProvider,
              let model = connectivityManager.selectedModel else { return }
        
        // Use model's effective system prompt (custom or global default)
        let effectiveSystemPrompt = model.effectiveSystemPrompt
        let modelDisplayName = model.effectiveName
        
        let systemMessage = ChatMessage(
            role: .assistant,
            content: effectiveSystemPrompt,
            modelInfo: "\(modelDisplayName) - System"
        )
        chatMessages.append(systemMessage)
    }
    
    func resetChatWithNewSystemPrompt() {
        chatMessages.removeAll()
        initializeChatWithSystemPrompt()
    }
    
    func sendTextMessage(_ text: String) {
        let messageText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        
        sendMessage(messageText)
        inputText = "" // 清空输入框
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - History Management
    
    /// Start a new chat (clear current messages and history reference)
    func startNewChat() {
        // Stop any ongoing TTS
        ttsService.stop()
        
        currentHistoryID = nil
        chatMessages.removeAll()
        initializeChatWithSystemPrompt()
    }
    
    /// Load chat from history
    func loadChatFromHistory(_ history: ChatHistory) {
        // Stop any ongoing TTS
        ttsService.stop()
        
        currentHistoryID = history.id
        chatMessages = history.messages
        
        // Try to set the provider and model from history if they exist
        if let providerID = history.providerID,
           let provider = connectivityManager.apiProviders.first(where: { $0.id == providerID }) {
            connectivityManager.setSelectedProvider(provider)
            
            if let modelID = history.modelID,
               let model = provider.models.first(where: { $0.id == modelID }) {
                connectivityManager.setSelectedModel(model)
            }
        }
    }
    
    /// Save current chat to history
    func saveCurrentChatToHistory() {
        guard !chatMessages.isEmpty,
              let provider = connectivityManager.selectedProvider,
              let model = connectivityManager.selectedModel else { return }
        
        if let historyID = currentHistoryID {
            // Update existing history
            historyManager.updateHistoryMessages(historyID, messages: chatMessages)
        } else {
            // Create new history
            let history = historyManager.createHistoryFromMessages(
                chatMessages,
                providerID: provider.id,
                modelID: model.id,
                providerName: provider.name,
                modelName: model.effectiveName
            )
            currentHistoryID = history.id
        }
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        // 这里可以添加对connectivityManager的观察
        // 由于SwiftUI的特性，直接在View中使用onChange会更简单
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
        let assistantMessage = ChatMessage(role: .assistant, content: "", modelInfo: model.effectiveName)
        chatMessages.append(assistantMessage)
        streamingMessageId = assistantMessage.id
        
        // Use stream transmission
        llmService.sendMessageStream(
            cleanedText,
            provider: provider,
            model: model,
            chatHistory: Array(chatMessages.dropLast(2).suffix(5)) // Exclude just added user message and empty AI message
        ) { [weak self] partialContent in
            Task { @MainActor in
                self?.updateStreamingMessage(content: partialContent)
            }
        } onThinkingUpdate: { [weak self] thinkingContent in
            Task { @MainActor in
                self?.updateStreamingMessage(thinkingContent: thinkingContent)
            }
        } onThinkingComplete: { [weak self] thinkingContent, thinkingDuration in
            Task { @MainActor in
                self?.updateStreamingMessage(
                    thinkingContent: thinkingContent,
                    thinkingDuration: thinkingDuration
                )
            }
        } onComplete: { [weak self] finalContent in
            Task { @MainActor in
                self?.completeStreamingMessage(content: finalContent)
            }
        } onError: { [weak self] error in
            Task { @MainActor in
                self?.handleStreamingError(error)
            }
        }
    }
    
    private func updateStreamingMessage(
        content: String? = nil,
        thinkingContent: String? = nil,
        thinkingDuration: TimeInterval? = nil
    ) {
        guard let messageId = streamingMessageId,
              let index = chatMessages.firstIndex(where: { $0.id == messageId }) else { return }
        
        var updatedMessage = chatMessages[index]
        
        if let content = content {
            updatedMessage.content = content
        }
        
        if let thinkingContent = thinkingContent {
            updatedMessage.thinkingContent = thinkingContent
        }
        
        if let thinkingDuration = thinkingDuration {
            updatedMessage.thinkingDuration = thinkingDuration
        }
        
        chatMessages[index] = updatedMessage
    }
    
    private func completeStreamingMessage(content: String) {
        guard let messageId = streamingMessageId,
              let index = chatMessages.firstIndex(where: { $0.id == messageId }) else { return }
        
        var updatedMessage = chatMessages[index]
        updatedMessage.content = content
        chatMessages[index] = updatedMessage
        
        isLoading = false
        streamingMessageId = nil
        WKInterfaceDevice.current().play(.success)
        
        // Auto-save to history after message completion
        saveCurrentChatToHistory()
        
        // Play TTS for assistant messages
        if updatedMessage.role == .assistant && !content.isEmpty {
            ttsService.speak(content)
        }
    }
    
    private func handleStreamingError(_ error: Error) {
        // Stop any ongoing TTS
        ttsService.stop()
        
        // Remove failed message
        if let messageId = streamingMessageId,
           let index = chatMessages.firstIndex(where: { $0.id == messageId }) {
            chatMessages.remove(at: index)
        }
        
        isLoading = false
        streamingMessageId = nil
        errorMessage = error.localizedDescription
        WKInterfaceDevice.current().play(.failure)
    }
}

// MARK: - Computed Properties
extension ChatViewModel {
    var canSendMessage: Bool {
        !isLoading && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isSetupRequired: Bool {
        connectivityManager.apiProviders.isEmpty ||
        connectivityManager.selectedProvider == nil ||
        connectivityManager.selectedModel == nil
    }
} 