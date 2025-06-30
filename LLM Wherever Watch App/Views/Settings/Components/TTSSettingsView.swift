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
            Toggle("Auto TTS after Response", isOn: $ttsService.autoTTSAfterResponse)
            
            // Show TTS controls only when actively speaking
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
