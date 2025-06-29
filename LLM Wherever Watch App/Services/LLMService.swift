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
    ) async throws -> (content: String, thinkingContent: String?, thinkingDuration: TimeInterval?) {
        
        let startTime = Date()
        let userMessage = message // Store original message
        
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
        
        // Calculate thinking duration and generate thinking content
        let endTime = Date()
        let thinkingDuration = endTime.timeIntervalSince(startTime)
        let thinkingContent = generateThinkingContent(for: userMessage, model: model, duration: thinkingDuration)
        
        return (
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            thinkingContent: thinkingContent,
            thinkingDuration: thinkingDuration
        )
    }
    
    // New streaming method with thinking process support
    func sendMessageStream(
        _ message: String,
        provider: APIProvider,
        model: LLMModel,
        chatHistory: [ChatMessage] = [],
        onUpdate: @escaping (String) -> Void,
        onThinkingComplete: @escaping (String, TimeInterval) -> Void, // Called when thinking ends
        onComplete: @escaping (String) -> Void, // Called when response is complete
        onError: @escaping (Error) -> Void
    ) {
        Task {
            let startTime = Date()
            
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
                var firstTokenReceived = false
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
                           let delta = firstChoice["delta"] as? [String: Any],
                           let content = delta["content"] as? String {
                            
                            // Mark when first token is received (thinking ends)
                            if !firstTokenReceived {
                                firstTokenReceived = true
                                thinkingEndTime = Date()
                                
                                // Generate thinking content immediately when thinking ends
                                let thinkingDuration = thinkingEndTime!.timeIntervalSince(startTime)
                                let thinkingContent = generateThinkingContent(for: message, model: model, duration: thinkingDuration)
                                
                                await MainActor.run {
                                    onThinkingComplete(thinkingContent, thinkingDuration)
                                }
                            }
                            
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
    
    // Generate simulated thinking content based on user message
    private func generateThinkingContent(for message: String, model: LLMModel, duration: TimeInterval) -> String {
        let messageLength = message.count
        let isQuestion = message.contains("?") || message.lowercased().contains("what") || 
                        message.lowercased().contains("how") || message.lowercased().contains("why") ||
                        message.lowercased().contains("when") || message.lowercased().contains("where")
        
        var thoughts: [String] = []
        
        // Analyze the input
        if messageLength < 20 {
            thoughts.append("Processing a short user input...")
        } else if messageLength > 100 {
            thoughts.append("Analyzing a detailed user message...")
        } else {
            thoughts.append("Understanding the user's request...")
        }
        
        // Add thinking based on message type
        if isQuestion {
            thoughts.append("This appears to be a question requiring a thoughtful response.")
            thoughts.append("Considering the best way to provide helpful information.")
        } else {
            thoughts.append("Analyzing the user's statement and determining appropriate response.")
        }
        
        // Add model-specific thoughts
        if model.name.contains("GPT") {
            thoughts.append("Drawing upon training knowledge to formulate response.")
        } else if model.name.contains("Claude") {
            thoughts.append("Carefully considering the nuances of the request.")
        }
        
        // Add duration-based thoughts
        if duration > 2.0 {
            thoughts.append("Taking time to ensure accuracy and relevance.")
        } else if duration > 1.0 {
            thoughts.append("Quickly processing and preparing response.")
        }
        
        thoughts.append("Finalizing response structure and content.")
        
        return thoughts.joined(separator: "\n\n")
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