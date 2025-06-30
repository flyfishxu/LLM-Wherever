//
//  HistoryView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var historyManager = HistoryManager.shared
    @StateObject private var connectivityManager = WatchConnectivityManager.shared
    @StateObject private var chatViewModel = ChatViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if historyManager.hasHistories {
                    List {
                        // New Chat Navigation Link
                        NavigationLink(destination: WatchChatView(
                            chatMessages: $chatViewModel.chatMessages,
                            inputText: $chatViewModel.inputText,
                            isLoading: $chatViewModel.isLoading,
                            errorMessage: $chatViewModel.errorMessage,
                            onSendMessage: chatViewModel.sendTextMessage,
                            onClearError: chatViewModel.clearError
                        ).onAppear {
                            chatViewModel.startNewChat()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.message.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("New Chat")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 2)
                        }
                        .listRowBackground(Color.blue.opacity(0.1))
                        
                        // History List
                        ForEach(historyManager.recentHistories) { history in
                            NavigationLink(destination: WatchChatView(
                                chatMessages: $chatViewModel.chatMessages,
                                inputText: $chatViewModel.inputText,
                                isLoading: $chatViewModel.isLoading,
                                errorMessage: $chatViewModel.errorMessage,
                                onSendMessage: chatViewModel.sendTextMessage,
                                onClearError: chatViewModel.clearError
                            ).onAppear {
                                chatViewModel.loadChatFromHistory(history)
                            }) {
                                HistoryRowView(history: history)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    historyManager.deleteChatHistory(history)
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
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
                } else {
                    // Empty State
                    emptyStateView
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private var emptyStateView: some View {
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
                    NavigationLink(destination: WatchChatView(
                        chatMessages: $chatViewModel.chatMessages,
                        inputText: $chatViewModel.inputText,
                        isLoading: $chatViewModel.isLoading,
                        errorMessage: $chatViewModel.errorMessage,
                        onSendMessage: chatViewModel.sendTextMessage,
                        onClearError: chatViewModel.clearError
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
                    NavigationLink(destination: WatchChatView(
                        chatMessages: $chatViewModel.chatMessages,
                        inputText: $chatViewModel.inputText,
                        isLoading: $chatViewModel.isLoading,
                        errorMessage: $chatViewModel.errorMessage,
                        onSendMessage: chatViewModel.sendTextMessage,
                        onClearError: chatViewModel.clearError
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

struct HistoryRowView: View {
    let history: ChatHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(history.displayTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(formatDate(history.lastUpdatedAt))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            if !history.previewText.isEmpty {
                Text(history.previewText)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Message count with icon
            HStack(spacing: 3) {
                Image(systemName: "message.fill")
                    .font(.system(size: 8))
                Text("\(history.messageCount)")
                    .font(.system(size: 10, weight: .medium))
                Spacer()
            }
            .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let now = Date()
        let calendar = Calendar.current
        
        if calendar.isDate(date, inSameDayAs: now) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
                  calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        } else if let weekAgo = calendar.date(byAdding: .day, value: -7, to: now),
                  date >= weekAgo {
            let formatter = DateFormatter()
            formatter.dateFormat = "E"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d"
            return formatter.string(from: date)
        }
    }
}

#Preview {
    HistoryView()
} 
