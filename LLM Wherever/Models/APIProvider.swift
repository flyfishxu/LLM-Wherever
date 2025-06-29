//
//  APIProvider.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import Foundation

struct APIProvider: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var baseURL: String
    var apiKey: String
    var models: [LLMModel]
    var isActive: Bool = true
}

// MARK: - Global Default Settings
struct DefaultModelSettings: Codable {
    var systemPrompt: String = "You are a helpful AI assistant."
    var temperature: Double = 0.7
    var maxTokens: Int = 2000
    
    static var shared: DefaultModelSettings {
        guard let data = UserDefaults.standard.data(forKey: "DefaultModelSettings"),
              let settings = try? JSONDecoder().decode(DefaultModelSettings.self, from: data) else {
            return DefaultModelSettings()
        }
        return settings
    }
}

// MARK: - Static provider templates (for reference only)
extension APIProvider {
    // These static instances are kept for backward compatibility but not used as defaults
    static let openAI = APIProvider(
        name: "OpenAI",
        baseURL: "https://api.openai.com/v1",
        apiKey: "",
        models: [
            LLMModel(name: "GPT-4", identifier: "gpt-4"),
            LLMModel(name: "GPT-4o", identifier: "gpt-4o"),
            LLMModel(name: "GPT-3.5 Turbo", identifier: "gpt-3.5-turbo")
        ]
    )
    
    static let claude = APIProvider(
        name: "Claude",
        baseURL: "https://api.anthropic.com/v1",
        apiKey: "",
        models: [
            LLMModel(name: "Claude 3.5 Sonnet", identifier: "claude-3-5-sonnet-20241022"),
            LLMModel(name: "Claude 3 Opus", identifier: "claude-3-opus-20240229"),
            LLMModel(name: "Claude 3 Haiku", identifier: "claude-3-haiku-20240307")
        ]
    )
    
    static let siliconFlow = APIProvider(
        name: "SiliconFlow",
        baseURL: "https://api.siliconflow.cn/v1",
        apiKey: "",
        models: [
            LLMModel(name: "Qwen2.5-7B-Instruct", identifier: "Qwen/Qwen2.5-7B-Instruct"),
            LLMModel(name: "Qwen2.5-72B-Instruct", identifier: "Qwen/Qwen2.5-72B-Instruct"),
            LLMModel(name: "DeepSeek-V2.5", identifier: "deepseek-ai/DeepSeek-V2.5")
        ]
    )
}

struct LLMModel: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var identifier: String
    var customName: String? // Optional custom display name
    var systemPrompt: String? // Optional custom system prompt
    var temperature: Double? // Optional custom temperature
    var maxTokens: Int? // Optional custom max tokens
    var useCustomSettings: Bool = false // Whether to use custom settings or provider defaults
    
    // Computed properties for getting effective values
    var effectiveName: String {
        customName?.isEmpty == false ? customName! : name
    }
    
    var effectiveSystemPrompt: String {
        if useCustomSettings, let systemPrompt = systemPrompt, !systemPrompt.isEmpty {
            return systemPrompt
        }
        return DefaultModelSettings.shared.systemPrompt
    }
    
    var effectiveTemperature: Double {
        if useCustomSettings, let temperature = temperature {
            return temperature
        }
        return DefaultModelSettings.shared.temperature
    }
    
    var effectiveMaxTokens: Int {
        if useCustomSettings, let maxTokens = maxTokens {
            return maxTokens
        }
        return DefaultModelSettings.shared.maxTokens
    }
    
    // Initialize with default values
    init(name: String, identifier: String) {
        self.name = name
        self.identifier = identifier
        let defaults = DefaultModelSettings.shared
        self.systemPrompt = defaults.systemPrompt
        self.temperature = defaults.temperature
        self.maxTokens = defaults.maxTokens
    }
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
} 