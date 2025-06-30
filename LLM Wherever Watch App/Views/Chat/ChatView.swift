//
//  ChatView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/29.
//

import SwiftUI

struct ChatView: View {
    @Binding var chatMessages: [ChatMessage]
    @Binding var inputText: String
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var ttsService = TTSService.shared

    @State private var scrollID = UUID() // For triggering scroll updates
    @State private var showingSettings = false
    
    let onSendMessage: (String) -> Void
    let onClearError: () -> Void
    let onDeleteMessage: ((UUID) -> Void)?
    let onRegenerateMessage: ((UUID) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(chatMessages) { message in
                            ChatBubbleView(
                                message: message,
                                onDelete: onDeleteMessage,
                                onRegenerate: onRegenerateMessage
                            )
                            .id(message.id)
                        }
                        
                        ChatInputView(
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
            ToolbarItem(placement: .topBarLeading) {
                if ttsService.isSpeaking {
                    Button {
                        if ttsService.isPaused {
                            ttsService.resume()
                        } else {
                            ttsService.pause()
                        }
                    } label: {
                        Image(systemName: ttsService.isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    if ttsService.isSpeaking {
                        Button {
                            ttsService.stop()
                        } label: {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                        }
                    }
                    
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.system(size: 14))
                    }
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
        ChatView(
            chatMessages: .constant([
                ChatMessage(role: .user, content: "Can you show me a code example with Markdown formatting?"),
                
                ChatMessage(
                    role: .assistant,
                    content: """
                    Sure! Here's a **Swift** code example:
                    
                    ```swift
                    func greetUser(name: String) {
                        print("Hello, \\(name)!")
                    }
                    ```
                    
                    This function takes a `name` parameter and prints a greeting.
                    
                    You can also use *italic* and **bold** text for emphasis.
                    
                    Here's an ordered list:
                    1. Create the function
                    2. Add parameters
                    3. Implement logic
                    
                    And an unordered list:
                    - Supports **bold text**
                    - Supports `inline code`
                    - Supports *italic text*
                    """,
                    modelInfo: "GPT-4",
                    thinkingContent: "The user wants to see a Markdown code example. I should demonstrate various Markdown elements including code blocks, bold, italic, lists, etc. to showcase the rendering capabilities.",
                    thinkingDuration: 1.5
                ),
                
                ChatMessage(role: .user, content: "What other Markdown features are supported?"),
                
                ChatMessage(
                    role: .assistant,
                    content: """
                    ## Supported Markdown Features
                    
                    This chat interface now supports the following Markdown features:
                    
                    ### Text Formatting
                    - **Bold text**
                    - *Italic text*  
                    - `Inline code`
                    
                    ### Code Blocks
                    ```python
                    def hello_world():
                        print("Hello, World!")
                    ```
                    
                    ### Lists
                    1. Ordered list item 1
                    2. Ordered list item 2
                    
                    - Unordered list item A
                    - Unordered list item B
                    
                    Perfect for technical discussions! 🚀
                    """,
                    modelInfo: "Claude-3.5"
                )
            ]),
            inputText: .constant(""),
            isLoading: .constant(false),
            errorMessage: .constant(nil),
            onSendMessage: { _ in },
            onClearError: { },
            onDeleteMessage: nil,
            onRegenerateMessage: nil
        )
    }
} 
