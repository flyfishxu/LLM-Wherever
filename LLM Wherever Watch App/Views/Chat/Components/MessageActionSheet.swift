//
//  MessageActionSheet.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct MessageActionSheet: View {
    let message: ChatMessage
    let onDelete: ((UUID) -> Void)?
    let onRegenerate: ((UUID) -> Void)?
    let onSpeak: ((UUID) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        
        // Action buttons
        VStack(spacing: 8) {
            // Delete button
            Button(action: {
                onDelete?(message.id)
                dismiss()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.red)
                        .frame(width: 20)
                    
                    Text("Delete")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.red)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.red.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
            
            // Regenerate button (only for assistant messages)
            if message.role == .assistant {
                Button(action: {
                    onRegenerate?(message.id)
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.blue)
                            .frame(width: 20)
                        
                        Text("Regenerate")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.blue)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                
                // Speak button (only for assistant messages with content)
                if !message.content.isEmpty {
                    Button(action: {
                        onSpeak?(message.id)
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "speaker.wave.2")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.green)
                                .frame(width: 20)
                            
                            Text("Read")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.green)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.green.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

#Preview {
    MessageActionSheet(
        message: ChatMessage(id: UUID(), role: .assistant, content: "This is a test message"),
        onDelete: { _ in },
        onRegenerate: { _ in },
        onSpeak: { _ in }
    )
}
