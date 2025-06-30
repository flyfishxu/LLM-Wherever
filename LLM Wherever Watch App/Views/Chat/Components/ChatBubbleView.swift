//
//  ChatBubbleView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/29.
//

import SwiftUI
import MarkdownUI

struct ChatBubbleView: View {
    let message: ChatMessage
    @State private var isThinkingCollapsed: Bool = true
    
    init(message: ChatMessage) {
        self.message = message
    }
    
    var isSystemMessage: Bool {
        message.role == .assistant && message.modelInfo?.contains("System") == true
    }
    
    // Smart detection of streaming state based on message content
    var isStreaming: Bool {
        // If there's thinking content but no thinking duration, it's still streaming thinking
        // If there's thinking content and no regular content, it's still in thinking phase
        if let thinkingContent = message.thinkingContent, !thinkingContent.isEmpty {
            return message.thinkingDuration == nil || message.content.isEmpty
        }
        return false
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
                    // Thinking process section for AI messages (show thinking content when available)
                    if message.role == .assistant, let thinkingContent = message.thinkingContent, !thinkingContent.isEmpty {
                        thinkingSection(content: thinkingContent, isStreaming: isStreaming)
                            .padding(.bottom, message.content.isEmpty ? 0 : 6)
                    }
                    
                    // Main content with Markdown support for assistant messages
                    if !message.content.isEmpty {
                        if message.role == .assistant {
                            // Use Markdown for AI responses to support formatted text
                            Markdown(message.content)
                        } else {
                            // Use plain text for user messages
                            Text(message.content)
                                .font(.caption)
                                .multilineTextAlignment(.trailing)
                        }
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
    private func thinkingSection(content: String, isStreaming: Bool) -> some View {
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
                        .symbolEffect(.pulse, options: isStreaming ? .repeating : .default)
                    
                    if isThinkingCollapsed {
                        Text(isStreaming ? "Thinking..." : thinkingDurationText)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        if isStreaming {
                            ProgressView()
                                .frame(width: 10, height: 10)
                                .controlSize(.mini)
                                .tint(.orange)
                        } else {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(isStreaming ? "Thinking..." : "Details")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        if isStreaming {
                            ProgressView()
                                .frame(width: 10, height: 10)
                                .controlSize(.mini)
                                .tint(.orange)
                        } else {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
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
                VStack(alignment: .leading, spacing: 0) {
                    Text(content.isEmpty ? "" : content)
                        .font(.system(size: 10))
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 3)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(.orange.opacity(0.08))
                        )
                    
                    // Show streaming indicator at the end if still streaming
                    if isStreaming && !content.isEmpty {
                        HStack {
                            Spacer()
                            HStack(spacing: 2) {
                                Text("●")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.orange)
                                    .symbolEffect(.pulse, options: .repeating)
                                Text("●")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.orange)
                                    .symbolEffect(.pulse.byLayer, options: .repeating)
                                Text("●")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.orange)
                                    .symbolEffect(.pulse, options: .repeating)
                            }
                        }
                        .padding(.horizontal, 3)
                        .padding(.top, 2)
                    }
                }
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
}

#Preview {
    VStack(spacing: 8) {
        ChatBubbleView(message: ChatMessage(role: .user, content: "Hello!"))
        
        ChatBubbleView(message: ChatMessage(
            role: .assistant,
            content: "Hi there! This supports **bold**, *italic*, and `code` formatting.",
            modelInfo: "GPT-4"
        ))
        
        ChatBubbleView(message: ChatMessage(
            role: .assistant,
            content: "",
            modelInfo: "GPT-4",
            thinkingContent: "The user is asking about something...",
            thinkingDuration: nil  // Still thinking
        ))
    }
} 
