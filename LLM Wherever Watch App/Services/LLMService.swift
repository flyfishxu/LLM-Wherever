//
//  LLMService.swift
//  LLM Wherever Watch App
//
//  Created by 徐义超 on 2025/1/16.
//

import Foundation

class LLMService: ObservableObject {
    static let shared = LLMService()
    
    private init() {}
    
    func sendMessage(
        _ message: String,
        provider: APIProvider,
        model: LLMModel,
        chatHistory: [ChatMessage] = []
    ) async throws -> String {
        
        // Check if provider is active
        guard provider.isActive else {
            throw LLMError.providerDisabled
        }
        
        let url = URL(string: "\(provider.baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
        
        var messages: [[String: String]] = []
        
        // Add chat history
        for chatMessage in chatHistory.suffix(5) { // Limit fewer history messages on watch
            messages.append([
                "role": chatMessage.role.rawValue,
                "content": chatMessage.content
            ])
        }
        
        // Add current message
        messages.append([
            "role": "user",
            "content": message
        ])
        
        let requestBody: [String: Any] = [
            "model": model.identifier,
            "messages": messages,
            "max_tokens": 500, // Limit fewer tokens on watch
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw LLMError.apiError(message)
            }
            throw LLMError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LLMError.invalidResponse
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // New streaming method
    func sendMessageStream(
        _ message: String,
        provider: APIProvider,
        model: LLMModel,
        chatHistory: [ChatMessage] = [],
        onUpdate: @escaping (String) -> Void,
        onComplete: @escaping (String) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        Task {
            do {
                // Check if provider is active
                guard provider.isActive else {
                    await MainActor.run {
                        onError(LLMError.providerDisabled)
                    }
                    return
                }
                let url = URL(string: "\(provider.baseURL)/chat/completions")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(provider.apiKey)", forHTTPHeaderField: "Authorization")
                
                var messages: [[String: String]] = []
                
                // Add chat history
                for chatMessage in chatHistory.suffix(5) {
                    messages.append([
                        "role": chatMessage.role.rawValue,
                        "content": chatMessage.content
                    ])
                }
                
                // Add current message
                messages.append([
                    "role": "user",
                    "content": message
                ])
                
                let requestBody: [String: Any] = [
                    "model": model.identifier,
                    "messages": messages,
                    "max_tokens": 500,
                    "temperature": 0.7,
                    "stream": true
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                
                let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      200...299 ~= httpResponse.statusCode else {
                    throw LLMError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
                }
                
                var completeText = ""
                
                for try await line in asyncBytes.lines {
                    if line.hasPrefix("data: ") {
                        let jsonString = String(line.dropFirst(6))
                        
                        if jsonString == "[DONE]" {
                            break
                        }
                        
                        if let data = jsonString.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let choices = json["choices"] as? [[String: Any]],
                           let firstChoice = choices.first,
                           let delta = firstChoice["delta"] as? [String: Any],
                           let content = delta["content"] as? String {
                            
                            completeText += content
                            await MainActor.run {
                                onUpdate(completeText)
                            }
                        }
                    }
                }
                
                await MainActor.run {
                    onComplete(completeText.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                
            } catch {
                await MainActor.run {
                    onError(error)
                }
            }
        }
    }
}

enum LLMError: LocalizedError {
    case invalidResponse
    case apiError(String)
    case httpError(Int)
    case networkError
    case providerDisabled
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response format"
        case .apiError(let message):
            return "API error: \(message)"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .networkError:
            return "Network connection error"
        case .providerDisabled:
            return "This API provider has been disabled"
        }
    }
} 