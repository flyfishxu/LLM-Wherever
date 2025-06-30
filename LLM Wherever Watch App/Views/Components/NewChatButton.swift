//
//  NewChatButton.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct NewChatButton: View {
    let style: ButtonStyle
    let action: () -> Void
    
    enum ButtonStyle {
        case listRow
        case emptyState
    }
    
    var body: some View {
        Button(action: action) {
            switch style {
            case .listRow:
                HStack(spacing: 8) {
                    Image(systemName: "plus.message.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("New Chat")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 2)
                
            case .emptyState:
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
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 20) {
        NewChatButton(style: .listRow) { }
        NewChatButton(style: .emptyState) { }
    }
} 
