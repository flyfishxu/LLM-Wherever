//
//  HistoryManager.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import Foundation

@MainActor
class HistoryManager: ObservableObject {
    // MARK: - Singleton
    static let shared = HistoryManager()
    
    // MARK: - Published Properties
    @Published var chatHistories: [ChatHistory] = []
    
    // MARK: - Constants
    private let userDefaults = UserDefaults.standard
    private let historyKey = "ChatHistories"
    private let maxHistoryCount = 50 // Limit history count for performance
    
    // MARK: - Initialization
    private init() {
        loadHistories()
    }
    
    // MARK: - Public Methods
    
    /// Save a new chat history or update existing one
    func saveChatHistory(_ history: ChatHistory) {
        // Check if history already exists
        if let index = chatHistories.firstIndex(where: { $0.id == history.id }) {
            // Update existing history
            var updatedHistory = history
            updatedHistory.lastUpdatedAt = Date()
            chatHistories[index] = updatedHistory
        } else {
            // Add new history
            var newHistory = history
            newHistory.lastUpdatedAt = Date()
            chatHistories.insert(newHistory, at: 0) // Insert at beginning for most recent first
            
            // Limit history count
            if chatHistories.count > maxHistoryCount {
                chatHistories.removeLast(chatHistories.count - maxHistoryCount)
            }
        }
        
        saveHistories()
    }
    
    /// Delete a chat history
    func deleteChatHistory(_ history: ChatHistory) {
        chatHistories.removeAll { $0.id == history.id }
        saveHistories()
    }
    
    /// Delete all chat histories
    func deleteAllHistories() {
        chatHistories.removeAll()
        saveHistories()
    }
    
    /// Get chat history by ID
    func getChatHistory(by id: UUID) -> ChatHistory? {
        return chatHistories.first { $0.id == id }
    }
    
    /// Create a new chat history from current chat messages
    func createHistoryFromMessages(
        _ messages: [ChatMessage],
        providerID: UUID?,
        modelID: UUID?,
        providerName: String?,
        modelName: String?
    ) -> ChatHistory {
        let history = ChatHistory(
            title: "", // Will be auto-generated
            messages: messages,
            providerID: providerID,
            modelID: modelID,
            providerName: providerName,
            modelName: modelName
        )
        
        saveChatHistory(history)
        return history
    }
    
    /// Update chat history with new messages
    func updateHistoryMessages(_ historyID: UUID, messages: [ChatMessage]) {
        guard let index = chatHistories.firstIndex(where: { $0.id == historyID }) else { return }
        
        chatHistories[index].messages = messages
        chatHistories[index].lastUpdatedAt = Date()
        
        saveHistories()
    }
    
    // MARK: - Private Methods
    
    private func loadHistories() {
        guard let data = userDefaults.data(forKey: historyKey),
              let histories = try? JSONDecoder().decode([ChatHistory].self, from: data) else {
            chatHistories = []
            return
        }
        
        // Sort by last updated date (most recent first)
        chatHistories = histories.sorted { $0.lastUpdatedAt > $1.lastUpdatedAt }
    }
    
    private func saveHistories() {
        guard let data = try? JSONEncoder().encode(chatHistories) else { return }
        userDefaults.set(data, forKey: historyKey)
    }
}

// MARK: - Computed Properties
extension HistoryManager {
    var hasHistories: Bool {
        !chatHistories.isEmpty
    }
    
    var recentHistories: [ChatHistory] {
        Array(chatHistories.prefix(10)) // Show most recent 10 histories
    }
} 