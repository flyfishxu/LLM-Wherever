//
//  WatchChatBubbleView.swift
//  LLM Wherever Watch App
//
//  Created by AI Assistant on 2025/6/29.
//

import SwiftUI

struct WatchChatBubbleView: View {
    let message: ChatMessage
    
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
                
                Text(message.content)
                    .font(.caption)
                    .multilineTextAlignment(message.role == .user ? .trailing : .leading)
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
}

#Preview {
    WatchChatBubbleView(message: ChatMessage(role: .user, content: "Hello, this is a test message!"))
} 