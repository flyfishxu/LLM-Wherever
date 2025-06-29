//
//  WatchChatBubbleView.swift
//  LLM Wherever Watch App
//
//  Created by AI Assistant on 2025/6/29.
//

import SwiftUI

struct WatchChatBubbleView: View {
    let message: ChatMessage
    let isLoading: Bool // Add loading state
    @State private var isThinkingCollapsed: Bool = true
    
    init(message: ChatMessage, isLoading: Bool = false) {
        self.message = message
        self.isLoading = isLoading
    }
    
    var isSystemMessage: Bool {
        message.role == .assistant && message.modelInfo?.contains("System") == true
    }
    
    var backgroundColor: Color {
        if message.role == .user {
            return .blue
        } else if isSystemMessage {
            return .green.opacity(0.2)
        } else {
            return .gray.opacity(0.15)
        }
    }
    
    var textColor: Color {
        if message.role == .user {
            return .white
        } else {
            return .primary
        }
    }
    
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
                
                // Main message bubble with thinking process inside
                VStack(alignment: .leading, spacing: 0) {
                    // Show loading/thinking state for AI messages that are loading
                    if message.role == .assistant && isLoading && message.content.isEmpty {
                        loadingThinkingSection
                            .padding(.bottom, 0)
                    }
                    // Thinking process section for AI messages (inside the bubble)
                    else if message.role == .assistant, let thinkingContent = message.thinkingContent {
                        thinkingSection(content: thinkingContent)
                            .padding(.bottom, message.content.isEmpty ? 0 : 6)
                    }
                    
                    // Main content
                    if !message.content.isEmpty {
                        Text(message.content)
                            .font(.caption)
                            .multilineTextAlignment(message.role == .user ? .trailing : .leading)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(backgroundColor)
                )
                .foregroundStyle(textColor)
                
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
    
    @ViewBuilder
    private func thinkingSection(content: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isThinkingCollapsed.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 12))
                        .foregroundStyle(.orange)
                    
                    if isThinkingCollapsed {
                        Text(thinkingDurationText)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Details")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.up")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.orange.opacity(0.15))
                )
            }
            .buttonStyle(.plain)
            
            if !isThinkingCollapsed {
                Text(content)
                    .font(.system(size: 10))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(.orange.opacity(0.08))
                    )
            }
        }
    }
    
    private var thinkingDurationText: String {
        if let duration = message.thinkingDuration {
            if duration < 1 {
                return "Thought for <1s"
            } else {
                return String(format: "Thought for %.0fs", duration)
            }
        }
        return "Thinking..."
    }
    
    @ViewBuilder
    private var loadingThinkingSection: some View {
        HStack() {
            // Animated thinking icon
            Image(systemName: "brain.head.profile")
                .font(.system(size: 12))
                .foregroundStyle(.orange)
                .symbolEffect(.pulse, options: .repeating)
            
            VStack(alignment: .leading, spacing: 1) {
                Text("Thinking...")
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)
                
                Text("Analyzing your request")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            ProgressView()
                .frame(width: 12, height: 12)
                .controlSize(.mini)
                .tint(.orange)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(.orange.opacity(0.15))
        )
    }
}

#Preview {
    VStack(spacing: 8) {
        WatchChatBubbleView(message: ChatMessage(role: .user, content: "Hello, this is a test message!"))
        
        WatchChatBubbleView(message: ChatMessage(
            role: .assistant,
            content: "Hi there! How can I help you?",
            modelInfo: "GPT-4",
            thinkingContent: "The user is greeting me. I should respond politely and offer assistance. This is a simple greeting that doesn't require complex reasoning.",
            thinkingDuration: 2.3
        ))
        
        // Loading state example
        WatchChatBubbleView(
            message: ChatMessage(role: .assistant, content: "", modelInfo: "GPT-4"),
            isLoading: true
        )
    }
} 
