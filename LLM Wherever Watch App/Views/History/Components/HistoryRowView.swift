//
//  HistoryRowView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct HistoryRowView: View {
    let history: ChatHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(history.displayTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(formatDate(history.lastUpdatedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !history.previewText.isEmpty {
                Text(history.previewText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Message count with icon
            HStack(spacing: 3) {
                Image(systemName: "message.fill")
                    .font(.system(size: 10))
                Text("\(history.messageCount)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
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
    List {
        HistoryRowView(
            history: ChatHistory(
                id: UUID(),
                title: "Sample Chat",
                messages: [],
                createdAt: Date(),
                lastUpdatedAt: Date(),
                providerID: UUID(),
                modelID: UUID(),
                providerName: "OpenAI",
                modelName: "GPT-4"
            )
        )
    }
} 
