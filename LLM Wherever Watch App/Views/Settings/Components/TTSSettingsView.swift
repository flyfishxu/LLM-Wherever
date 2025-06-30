//
//  TTSSettingsView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct TTSSettingsView: View {
    @ObservedObject var ttsService: TTSService
    
    var body: some View {
        Group {
            Toggle("Enable Speech", isOn: $ttsService.isEnabled)
                .onChange(of: ttsService.isEnabled) {
                    // Only sync if this is a user change, not from iPhone
                    if !ttsService.isUpdatingFromiPhone {
                        WatchConnectivityManager.shared.syncTTSToPhone()
                    }
                }
            
            if ttsService.isEnabled {
                NavigationLink(destination: SpeedAdjustmentView(speechRate: $ttsService.speechRate)) {
                    HStack {
                        Text("Speed")
                            .font(.caption)
                        Spacer()
                        Text(String(format: "%.1fx", ttsService.speechRate))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                NavigationLink(destination: VoiceLanguagePickerView(selectedLanguage: $ttsService.voiceLanguage)) {
                    HStack {
                        Text("Language")
                            .font(.caption)
                        Spacer()
                        Text(ttsService.displayNameForLanguage(ttsService.voiceLanguage))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if ttsService.isSpeaking {
                    VStack(spacing: 4) {
                        HStack(spacing: 8) {
                            if ttsService.isPaused {
                                Button("Resume") {
                                    ttsService.resume()
                                }
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .buttonStyle(BorderedButtonStyle())
                            } else {
                                Button("Pause") {
                                    ttsService.pause()
                                }
                                .font(.caption2)
                                .foregroundColor(.orange)
                                .buttonStyle(BorderedButtonStyle())
                            }
                            
                            Button("Stop") {
                                ttsService.stop()
                            }
                            .font(.caption2)
                            .foregroundColor(.red)
                            .buttonStyle(BorderedButtonStyle())
                        }
                    }
                }
            }
        }
    }
}

struct SpeedAdjustmentView: View {
    @Binding var speechRate: Float
    @Environment(\.dismiss) private var dismiss
    @State private var internalRate: Double = 0.5
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Speech Speed")
                .font(.headline)
            
            Text(String(format: "%.1fx", speechRate))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            Text("Turn the Digital Crown")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .digitalCrownRotation(
            $internalRate,
            from: 0.3,
            through: 0.8,
            by: 0.1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .onAppear {
            internalRate = Double(speechRate)
        }
        .onChange(of: internalRate) {
            speechRate = Float(internalRate)
            // 只在用户操作时同步到iPhone，避免无限循环
            if !TTSService.shared.isUpdatingFromiPhone {
                WatchConnectivityManager.shared.syncTTSToPhone()
            }
        }
        .navigationTitle("Speed")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct VoiceLanguagePickerView: View {
    @Binding var selectedLanguage: String
    @Environment(\.dismiss) private var dismiss
    
    private let ttsService = TTSService.shared
    
    var body: some View {
        List {
            ForEach(ttsService.availableLanguages, id: \.self) { language in
                Button {
                    selectedLanguage = language
                    // 只在用户选择时同步到iPhone，避免无限循环
                    if !TTSService.shared.isUpdatingFromiPhone {
                        WatchConnectivityManager.shared.syncTTSToPhone()
                    }
                    dismiss()
                } label: {
                    HStack {
                        Text(ttsService.displayNameForLanguage(language))
                            .font(.caption)
                        Spacer()
                        if selectedLanguage == language {
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        List {
            Section {
                TTSSettingsView(ttsService: TTSService.shared)
            } header: {
                Text("Text-to-Speech")
            }
        }
    }
}
