//
//  APIProvider.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/1/16.
//

import Foundation

struct APIProvider: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var baseURL: String
    var apiKey: String
    var models: [LLMModel]
    var isActive: Bool = true
    var systemPrompt: String = "Hello, how can I help you"
    var temperature: Double = 0.7
    var maxTokens: Int = 2000
}

extension APIProvider {
    static let openAI = APIProvider(
        name: "OpenAI",
        baseURL: "https://api.openai.com/v1",
        apiKey: "",
        models: [
            LLMModel(name: "GPT-4", identifier: "gpt-4"),
            LLMModel(name: "GPT-3.5 Turbo", identifier: "gpt-3.5-turbo")
        ],
        systemPrompt: "Hello, how can I help you",
        temperature: 0.7,
        maxTokens: 2000
    )
    
    static let anthropic = APIProvider(
        name: "Anthropic",
        baseURL: "https://api.anthropic.com/v1",
        apiKey: "",
        models: [
            LLMModel(name: "Claude 3.5 Sonnet", identifier: "claude-3-5-sonnet-20241022"),
            LLMModel(name: "Claude 3 Haiku", identifier: "claude-3-haiku-20240307")
        ],
        systemPrompt: "Hello, how can I help you",
        temperature: 0.7,
        maxTokens: 2000
    )
}

struct LLMModel: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var identifier: String
}

enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
}

struct ChatMessage: Identifiable, Codable, Equatable {
    var id = UUID()
    var role: MessageRole
    var content: String
    var timestamp = Date()
    var modelInfo: String? // Store model info, only AI messages have this
    
    // Thinking process related fields
    var thinkingContent: String? // The thinking process content
    var thinkingDuration: TimeInterval? // How long the thinking took in seconds
    var isThinkingCollapsed: Bool = true // Whether thinking section is collapsed
} 