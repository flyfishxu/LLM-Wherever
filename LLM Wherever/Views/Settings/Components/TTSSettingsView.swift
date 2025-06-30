//
//  TTSSettingsView.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct TTSSettingsView: View {
    @ObservedObject var ttsService: TTSService
    @State private var showingLanguagePicker = false
    
    var body: some View {
        Section {
            Toggle("Auto TTS after Response", isOn: Binding(
                get: { ttsService.autoTTSAfterResponse },
                set: { ttsService.autoTTSAfterResponse = $0 }
            ))
            
            VStack(alignment: .leading, spacing: 16) {
                // Speech Rate
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Speech Rate")
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.1f", ttsService.speechRate))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(value: Binding(
                        get: { ttsService.speechRate },
                        set: { ttsService.speechRate = $0 }
                    ), in: 0.3...0.8, step: 0.1)
                    
                    HStack {
                        Text("Slow")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Fast")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Voice Language
                HStack {
                    Text("Voice Language")
                        .font(.subheadline)
                    Spacer()
                    Button {
                        showingLanguagePicker = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(ttsService.displayNameForLanguage(ttsService.voiceLanguage))
                                .foregroundColor(.primary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // TTS Controls (when speaking)
                if ttsService.isSpeaking {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Currently Speaking")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        HStack(spacing: 16) {
                            if ttsService.isPaused {
                                Button("Resume") {
                                    ttsService.resume()
                                }
                                .buttonStyle(.bordered)
                            } else {
                                Button("Pause") {
                                    ttsService.pause()
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            Button("Stop") {
                                ttsService.stop()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Test TTS
                Button("Test Voice") {
                    let testText = ttsService.voiceLanguage.starts(with: "zh") ? 
                        "你好，这是语音测试。" : 
                        "Hello, this is a voice test."
                    ttsService.speak(testText)
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
            }
        } header: {
            Text("Text-to-Speech")
        } footer: {
            if ttsService.autoTTSAfterResponse {
                Text("AI responses will be automatically read aloud after conversation ends. This setting syncs with your Apple Watch.")
            } else {
                Text("Enable to automatically hear AI responses read aloud after conversation ends. This setting syncs with your Apple Watch.")
            }
        }
        .sheet(isPresented: $showingLanguagePicker) {
            VoiceLanguagePickerView(selectedLanguage: Binding(
                get: { ttsService.voiceLanguage },
                set: { ttsService.voiceLanguage = $0 }
            ))
        }
    }
}

struct VoiceLanguagePickerView: View {
    @Binding var selectedLanguage: String
    @Environment(\.dismiss) private var dismiss
    
    private let ttsService = TTSService.shared
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(ttsService.availableLanguages, id: \.self) { language in
                    Button {
                        selectedLanguage = language
                        dismiss()
                    } label: {
                        HStack {
                            Text(ttsService.displayNameForLanguage(language))
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedLanguage == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Voice Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            TTSSettingsView(ttsService: TTSService.shared)
        }
    }
} 