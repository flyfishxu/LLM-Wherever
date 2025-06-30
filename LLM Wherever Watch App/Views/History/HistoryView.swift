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
                        NavigationLink(destination: ChatView(
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
                        
                        // History List
                        ForEach(historyManager.recentHistories) { history in
                            NavigationLink(destination: ChatView(
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
                    .safeAreaInset(edge: .bottom) {
                        Spacer().frame(height: 28)
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
                    EmptyStateView()
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}


#Preview {
    HistoryView()
}
