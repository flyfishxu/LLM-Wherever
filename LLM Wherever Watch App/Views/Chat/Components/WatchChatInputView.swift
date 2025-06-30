//
//  WatchChatInputView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct WatchChatInputView: View {
    @Binding var inputText: String
    @FocusState private var isTextFieldFocused: Bool
    let onSendMessage: (String) -> Void
    
    var body: some View {
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
                    if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSendMessage(inputText)
                        inputText = ""
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 6)
                .clipShape(RoundedRectangle(cornerRadius: 24))
        }
    }
}

#Preview {
    WatchChatInputView(
        inputText: .constant(""),
        onSendMessage: { _ in }
    )
} 