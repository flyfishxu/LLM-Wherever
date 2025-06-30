//
//  LLMService.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
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
    ) async throws -> (content: String, thinkingContent: String?, thinkingDuration: TimeInterval?) {
        
        let startTime = Date()
        
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
        
        // Use model's effective parameters (custom or global defaults)
        let effectiveTemperature = model.effectiveTemperature
        let effectiveMaxTokens = model.effectiveMaxTokens
        
        let requestBody: [String: Any] = [
            "model": model.identifier,
            "messages": messages,
            "max_tokens": min(effectiveMaxTokens, 2000), // Limit max tokens on watch for performance
            "temperature": effectiveTemperature
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let errorMessage = error["message"] as? String {
                throw LLMError.apiError(errorMessage)
            }
            throw LLMError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let responseMessage = firstChoice["message"] as? [String: Any],
              let content = responseMessage["content"] as? String else {
            throw LLMError.invalidResponse
        }
        
        // For non-streaming responses, thinking content is usually not available
        // as it's typically only provided during streaming via reasoning_content
        let endTime = Date()
        _ = endTime.timeIntervalSince(startTime)
        
        return (
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            thinkingContent: nil, // Non-streaming doesn't provide thinking content in new format
            thinkingDuration: nil
        )
    }
    
    // New streaming method with thinking process support
    func sendMessageStream(
        _ message: String,
        provider: APIProvider,
        model: LLMModel,
        chatHistory: [ChatMessage] = [],
        onUpdate: @escaping (String) -> Void,
        onThinkingUpdate: @escaping (String) -> Void, // New callback for real-time thinking updates
        onThinkingComplete: @escaping (String, TimeInterval) -> Void, // Called when thinking ends
        onComplete: @escaping (String) -> Void, // Called when response is complete
        onError: @escaping (Error) -> Void
    ) {
        Task { @MainActor in
            let startTime = Date()
            
            do {
                // Check if provider is active
                guard provider.isActive else {
                    onError(LLMError.providerDisabled)
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
                
                // Use model's effective parameters (custom or global defaults)
                let effectiveTemperature = model.effectiveTemperature
                let effectiveMaxTokens = model.effectiveMaxTokens
                
                let requestBody: [String: Any] = [
                    "model": model.identifier,
                    "messages": messages,
                    "max_tokens": min(effectiveMaxTokens, 2000), // Limit max tokens on watch for performance
                    "temperature": effectiveTemperature,
                    "stream": true
                ]
                
                request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                
                let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      200...299 ~= httpResponse.statusCode else {
                    throw LLMError.httpError((response as? HTTPURLResponse)?.statusCode ?? 0)
                }
                
                var completeContent = ""
                var completeThinking = ""
                var isThinking = false
                var thinkingCompleted = false
                var thinkingEndTime: Date?
                
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
                           let delta = firstChoice["delta"] as? [String: Any] {
                            
                            // Check for reasoning content (thinking)
                            if let reasoningContent = delta["reasoning_content"] as? String, !reasoningContent.isEmpty {
                                isThinking = true
                                completeThinking += reasoningContent
                                
                                // Real-time thinking content update
                                onThinkingUpdate(completeThinking.trimmingCharacters(in: .whitespacesAndNewlines))
                            }
                            
                            // Check for actual content
                            if let content = delta["content"] as? String, !content.isEmpty {
                                // If we were thinking and now have content, thinking is complete
                                if isThinking && !thinkingCompleted {
                                    thinkingCompleted = true
                                    thinkingEndTime = Date()
                                    let thinkingDuration = thinkingEndTime!.timeIntervalSince(startTime)
                                    
                                    onThinkingComplete(completeThinking.trimmingCharacters(in: .whitespacesAndNewlines), thinkingDuration)
                                    
                                    isThinking = false
                                }
                                
                                completeContent += content
                                
                                onUpdate(completeContent)
                            }
                        }
                    }
                }
                
                onComplete(completeContent.trimmingCharacters(in: .whitespacesAndNewlines))
                
            } catch {
                onError(error)
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
