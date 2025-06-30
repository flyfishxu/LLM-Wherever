//
//  EmptyStateView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct EmptyStateView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Spacer()
                
                Image(systemName: "message.circle")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue.gradient)
                
                VStack(spacing: 4) {
                    Text("No Conversations")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Start chatting to see history")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                if #available(watchOS 26.0, *) {
                    NavigationLink(destination: ChatView(
                        chatMessages: $chatViewModel.chatMessages,
                        inputText: $chatViewModel.inputText,
                        isLoading: $chatViewModel.isLoading,
                        errorMessage: $chatViewModel.errorMessage,
                        onSendMessage: chatViewModel.sendTextMessage,
                        onClearError: chatViewModel.clearError,
                        onDeleteMessage: chatViewModel.deleteMessage(withId:),
                        onRegenerateMessage: chatViewModel.regenerateResponse(forMessageId:)
                    ).onAppear {
                        chatViewModel.startNewChat()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .medium))
                            Text("Start Chat")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .glassEffect()
                } else {
                    NavigationLink(destination: ChatView(
                        chatMessages: $chatViewModel.chatMessages,
                        inputText: $chatViewModel.inputText,
                        isLoading: $chatViewModel.isLoading,
                        errorMessage: $chatViewModel.errorMessage,
                        onSendMessage: chatViewModel.sendTextMessage,
                        onClearError: chatViewModel.clearError,
                        onDeleteMessage: chatViewModel.deleteMessage(withId:),
                        onRegenerateMessage: chatViewModel.regenerateResponse(forMessageId:)
                    ).onAppear {
                        chatViewModel.startNewChat()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .medium))
                            Text("Start Chat")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(.blue.gradient)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    EmptyStateView()
}
