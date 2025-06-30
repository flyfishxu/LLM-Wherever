//
//  InformationSection.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct InformationSection: View {
    let header: String
    let title: String
    let content: String
    let icon: String
    
    var body: some View {
        Section {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text(header)
        }
    }
}
