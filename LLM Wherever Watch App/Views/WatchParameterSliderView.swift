//
//  WatchParameterSliderView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/1/16.
//

import SwiftUI

struct WatchParameterSliderView: View {
    let title: String
    let systemImage: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let displayFormatter: (Double) -> String
    let inputValidator: (String) -> Double?
    
    @State private var isEditingText = false
    @State private var textInput = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(.blue)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Value display/input
                if isEditingText {
                    TextField("Value", text: $textInput)
                        .frame(width: 60)
                        .font(.caption)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            commitTextInput()
                        }
                } else {
                    Button(action: startTextEditing) {
                        Text(displayFormatter(value))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Slider with compact range labels
            VStack(spacing: 4) {
                Slider(value: $value, in: range, step: step) {
                    Text(title)
                }
                .tint(.blue)
                .onChange(of: value) { _, newValue in
                    if isEditingText {
                        textInput = displayFormatter(newValue)
                    }
                }
                
                HStack {
                    Text(displayFormatter(range.lowerBound))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(displayFormatter(range.upperBound))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onChange(of: isTextFieldFocused) { _, focused in
            if !focused && isEditingText {
                commitTextInput()
            }
        }
    }
    
    private func startTextEditing() {
        isEditingText = true
        textInput = displayFormatter(value)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTextFieldFocused = true
        }
    }
    
    private func commitTextInput() {
        if let newValue = inputValidator(textInput),
           range.contains(newValue) {
            value = newValue
        } else {
            textInput = displayFormatter(value)
        }
        isEditingText = false
        isTextFieldFocused = false
    }
}

struct WatchIntParameterSliderView: View {
    let title: String
    let systemImage: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    
    @State private var doubleValue: Double = 0
    
    var body: some View {
        WatchParameterSliderView(
            title: title,
            systemImage: systemImage,
            value: $doubleValue,
            range: Double(range.lowerBound)...Double(range.upperBound),
            step: Double(step),
            displayFormatter: { Int($0).formatted() },
            inputValidator: { text in
                guard let intValue = Int(text) else { return nil }
                return Double(intValue)
            }
        )
        .onAppear {
            doubleValue = Double(value)
        }
        .onChange(of: doubleValue) { _, newValue in
            value = Int(newValue)
        }
        .onChange(of: value) { _, newValue in
            doubleValue = Double(newValue)
        }
    }
}

#Preview {
    NavigationStack {
        List {
            Section {
                WatchParameterSliderView(
                    title: "Temperature",
                    systemImage: "thermometer",
                    value: .constant(0.7),
                    range: 0.0...2.0,
                    step: 0.1,
                    displayFormatter: { String(format: "%.1f", $0) },
                    inputValidator: { Double($0) }
                )
                
                WatchIntParameterSliderView(
                    title: "Max Tokens",
                    systemImage: "text.alignleft",
                    value: .constant(2000),
                    range: 100...4000,
                    step: 100
                )
            } header: {
                Text("AI Parameters")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
} 
