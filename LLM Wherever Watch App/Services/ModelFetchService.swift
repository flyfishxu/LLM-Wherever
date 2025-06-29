//
//  ModelFetchService.swift
//  LLM Wherever Watch App
//
//  Created by 徐义超 on 2025/1/16.
//

import Foundation

class ModelFetchService: ObservableObject {
    static let shared = ModelFetchService()
    
    private init() {}
    
    func fetchModels(for provider: APIProvider) async throws -> [LLMModel] {
        let url = URL(string: "\(provider.baseURL)/models")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ModelFetchError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw ModelFetchError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ModelFetchError.invalidResponse
        }
        
        return try parseModelsResponse(json, providerName: provider.name)
    }
    
    private func parseModelsResponse(_ json: [String: Any], providerName: String) throws -> [LLMModel] {
        var models: [LLMModel] = []
        
        if let data = json["data"] as? [[String: Any]] {
            // OpenAI format
            for modelInfo in data {
                if let id = modelInfo["id"] as? String,
                   let object = modelInfo["object"] as? String,
                   object == "model" {
                    
                    // Filter common chat models
                    if isValidChatModel(id) {
                        let displayName = formatModelName(id)
                        models.append(LLMModel(name: displayName, identifier: id))
                    }
                }
            }
        } else if let modelList = json["models"] as? [String] {
            // Custom format: simple model ID list
            for modelId in modelList {
                if isValidChatModel(modelId) {
                    let displayName = formatModelName(modelId)
                    models.append(LLMModel(name: displayName, identifier: modelId))
                }
            }
        } else {
            // If parsing fails, return default models
            return getDefaultModels(for: providerName)
        }
        
        return models.isEmpty ? getDefaultModels(for: providerName) : models
    }
    
    private func isValidChatModel(_ modelId: String) -> Bool {
        let chatModelPrefixes = [
            "gpt-3.5", "gpt-4", "gpt-4o",
            "claude-3", "claude-2",
            "llama", "mistral", "mixtral",
            "qwen", "baichuan", "chatglm",
            "gemini", "palm"
        ]
        
        let lowercaseId = modelId.lowercased()
        return chatModelPrefixes.contains { lowercaseId.contains($0) }
    }
    
    private func formatModelName(_ modelId: String) -> String {
        // Convert model ID to more friendly display name
        let modelName = modelId
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
        
        return modelName.split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
    
    private func getDefaultModels(for providerName: String) -> [LLMModel] {
        switch providerName.lowercased() {
        case "openai":
            return [
                LLMModel(name: "GPT-4", identifier: "gpt-4"),
                LLMModel(name: "GPT-3.5 Turbo", identifier: "gpt-3.5-turbo")
            ]
        case "anthropic":
            return [
                LLMModel(name: "Claude 3.5 Sonnet", identifier: "claude-3-5-sonnet-20241022"),
                LLMModel(name: "Claude 3 Haiku", identifier: "claude-3-haiku-20240307")
            ]
        default:
            return [
                LLMModel(name: "Default Model", identifier: "default")
            ]
        }
    }
}

enum ModelFetchError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case networkError
    case noModelsFound
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Unable to parse API response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .networkError:
            return "Network connection error"
        case .noModelsFound:
            return "No available models found"
        }
    }
} 