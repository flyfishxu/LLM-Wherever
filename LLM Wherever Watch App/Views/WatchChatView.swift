//
//  WatchChatView.swift
//  LLM Wherever Watch App
//
//  Created by AI Assistant on 2025/6/29.
//

import SwiftUI

struct WatchChatView: View {
    @Binding var chatMessages: [ChatMessage]
    @Binding var inputText: String
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    
    @FocusState private var isTextFieldFocused: Bool
    
    let onSendMessage: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(chatMessages) { message in
                            WatchChatBubbleView(message: message)
                        }
                        
                        if isLoading {
                            loadingView
                        }
                        
                        inputSection
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 2)
                }
                .onChange(of: chatMessages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        if let lastMessage = chatMessages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var loadingView: some View {
        HStack(spacing: 4) {
            ProgressView()
                .controlSize(.mini)
            Text("AI thinking")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var inputSection: some View {
        VStack(spacing: 12) {
            // Separator line
            Rectangle()
                .fill(.gray.opacity(0.3))
                .frame(height: 0.5)
                .padding(.horizontal, 20)
                .padding(.top, 8)
            
            // Input field
            TextField("Enter message", text: $inputText)
                .font(.caption)
                .focused($isTextFieldFocused)
                .onSubmit {
                    onSendMessage(inputText)
                    inputText = ""
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            
            Spacer()
                .frame(height: 4)
        }
    }
}

#Preview {
    WatchChatView(
        chatMessages: .constant([
            ChatMessage(role: .user, content: "Hello!"),
            ChatMessage(role: .assistant, content: "Hi there! How can I help you?", modelInfo: "GPT-4")
        ]),
        inputText: .constant(""),
        isLoading: .constant(false),
        errorMessage: .constant(nil),
        onSendMessage: { _ in }
    )
} 