//
//  ParameterSliderView.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/1/16.
//

import SwiftUI

struct ParameterSliderView: View {
    let title: String
    let description: String
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
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(.blue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Value display/input
                Group {
                    if isEditingText {
                        TextField("Value", text: $textInput)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                commitTextInput()
                            }
                    } else {
                        Button(action: startTextEditing) {
                            Text(displayFormatter(value))
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(.quaternary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Slider
            HStack {
                Text(displayFormatter(range.lowerBound))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .leading)
                
                Slider(value: $value, in: range, step: step) {
                    Text(title)
                } minimumValueLabel: {
                    EmptyView()
                } maximumValueLabel: {
                    EmptyView()
                }
                .tint(.blue)
                .onChange(of: value) { _, newValue in
                    // Update text input when slider changes
                    if isEditingText {
                        textInput = displayFormatter(newValue)
                    }
                }
                
                Text(displayFormatter(range.upperBound))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
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
            // Reset to current value if invalid
            textInput = displayFormatter(value)
        }
        isEditingText = false
        isTextFieldFocused = false
    }
}

struct IntParameterSliderView: View {
    let title: String
    let description: String
    let systemImage: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    
    @State private var doubleValue: Double = 0
    
    var body: some View {
        ParameterSliderView(
            title: title,
            description: description,
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
    Form {
        Section {
            ParameterSliderView(
                title: "Temperature",
                description: "Controls randomness in responses",
                systemImage: "thermometer",
                value: .constant(0.7),
                range: 0.0...2.0,
                step: 0.1,
                displayFormatter: { String(format: "%.1f", $0) },
                inputValidator: { Double($0) }
            )
            
            IntParameterSliderView(
                title: "Max Tokens",
                description: "Maximum response length",
                systemImage: "text.alignleft",
                value: .constant(2000),
                range: 100...4000,
                step: 100
            )
        } header: {
            Text("AI Parameters")
        }
    }
} 