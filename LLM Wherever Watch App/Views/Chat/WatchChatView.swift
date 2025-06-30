//
//  WatchChatView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/29.
//

import SwiftUI

struct WatchChatView: View {
    @Binding var chatMessages: [ChatMessage]
    @Binding var inputText: String
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    
    @StateObject private var connectivityManager = WatchConnectivityManager.shared

    @State private var scrollID = UUID() // For triggering scroll updates
    @State private var showingSettings = false
    
    let onSendMessage: (String) -> Void
    let onClearError: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(chatMessages) { message in
                            WatchChatBubbleView(message: message)
                                .id(message.id)
                        }
                        
                        WatchChatInputView(
                            inputText: $inputText,
                            onSendMessage: onSendMessage
                        )
                    }
                    .padding(.horizontal, 6)
                    .padding(.top, 2)
                    .id(scrollID) // Add ID for scroll tracking
                }
                .onChange(of: chatMessages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        if let lastMessage = chatMessages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: chatMessages.last?.content) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        if let lastMessage = chatMessages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isLoading) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        if let lastMessage = chatMessages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                        .font(.system(size: 14))
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                onClearError()
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    

}

#Preview {
    NavigationStack {
        WatchChatView(
            chatMessages: .constant([
                ChatMessage(role: .user, content: "Hello!"),
                ChatMessage(role: .assistant, content: "Hi there! How can I help you?", modelInfo: "GPT-4")
            ]),
            inputText: .constant(""),
            isLoading: .constant(false),
            errorMessage: .constant(nil),
            onSendMessage: { _ in },
            onClearError: { }
        )
    }
} 
