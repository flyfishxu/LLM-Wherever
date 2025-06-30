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
    @FocusState private var isTextFieldFocused: Bool
    @State private var scrollID = UUID() // For triggering scroll updates
    @State private var showingSettings = false
    
    let onSendMessage: (String) -> Void
    let onClearError: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Current model indicator
            if let selectedModel = connectivityManager.selectedModel {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                    Text(selectedModel.effectiveName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 8)
                .padding(.bottom, 4)
            }
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(chatMessages) { message in
                            WatchChatBubbleView(message: message)
                            .id(message.id)
                        }
                        
                        inputSection
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
        .navigationBarTitleDisplayMode(.inline)
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
                .padding(.bottom, 6)
                .clipShape(RoundedRectangle(cornerRadius: 24))
        
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
