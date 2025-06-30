//
//  TTSService.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import Foundation
import AVFoundation

@MainActor
class TTSService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = TTSService()
    
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    @Published var isPaused = false
    
    // TTS Settings
    @Published var settings: TTSSettings
    
    // Track if settings have been modified
    @Published var hasUnsavedChanges = false
    
    private var isUpdatingFromWatch = false
    
    // Convenience computed properties
    var autoTTSAfterResponse: Bool {
        get { settings.autoTTSAfterResponse }
        set { 
            settings.autoTTSAfterResponse = newValue
            hasUnsavedChanges = true
        }
    }
    
    var speechRate: Float {
        get { settings.speechRate }
        set { 
            settings.speechRate = newValue
            hasUnsavedChanges = true
        }
    }
    
    var voiceLanguage: String {
        get { settings.voiceLanguage }
        set { 
            settings.voiceLanguage = newValue
            hasUnsavedChanges = true
        }
    }
    
    private override init() {
        // Load user settings
        self.settings = TTSSettings.load()
        
        super.init()
        synthesizer.delegate = self
        
        // Configure audio session for iPhone
        configureAudioSession()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.allowBluetoothHFP, .allowBluetoothA2DP])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    /// Speak the provided text if auto TTS is enabled
    func speak(_ text: String) {
        guard autoTTSAfterResponse && !text.isEmpty else { return }
        
        // Stop any current speech
        stop()
        
        // Clean text for better TTS (remove markdown, special characters, etc.)
        let cleanedText = cleanTextForTTS(text)
        
        let utterance = AVSpeechUtterance(string: cleanedText)
        utterance.rate = speechRate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        // Try to use preferred language voice
        if let voice = AVSpeechSynthesisVoice(language: voiceLanguage) {
            utterance.voice = voice
        } else {
            // Fallback to default voice
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        }
        
        synthesizer.speak(utterance)
    }
    
    /// Pause current speech
    func pause() {
        guard isSpeaking else { return }
        synthesizer.pauseSpeaking(at: .immediate)
    }
    
    /// Resume paused speech
    func resume() {
        guard isPaused else { return }
        synthesizer.continueSpeaking()
    }
    
    /// Stop current speech
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    /// Update settings from external source (e.g., Watch sync)
    func updateSettings(_ newSettings: TTSSettings) {
        isUpdatingFromWatch = true
        settings = newSettings
        hasUnsavedChanges = false
        isUpdatingFromWatch = false
    }
    
    /// Save settings and sync to watch
    func saveSettings() {
        settings.save()
        hasUnsavedChanges = false
        // Sync to watch immediately after saving
        WatchConnectivityManager.shared.syncTTSToWatch(settings)
    }
    
    /// Clean text for better TTS output
    private func cleanTextForTTS(_ text: String) -> String {
        var cleanedText = text
        
        // Remove markdown formatting
        cleanedText = cleanedText.replacingOccurrences(of: "**", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "*", with: "")
        cleanedText = cleanedText.replacingOccurrences(of: "`", with: "")
        
        // Remove code blocks
        cleanedText = cleanedText.replacingOccurrences(of: "```[\\s\\S]*?```", with: "[code block]", options: .regularExpression)
        
        // Remove inline code
        cleanedText = cleanedText.replacingOccurrences(of: "`[^`]*`", with: "[code]", options: .regularExpression)
        
        // Replace common symbols with readable text
        cleanedText = cleanedText.replacingOccurrences(of: "\n", with: ". ")
        cleanedText = cleanedText.replacingOccurrences(of: "  ", with: " ")
        
        // Limit length for performance (max 1000 characters for iPhone)
        if cleanedText.count > 1000 {
            cleanedText = String(cleanedText.prefix(1000)) + "..."
        }
        
        return cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = true
            isPaused = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPaused = true
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isPaused = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
            isPaused = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
            isPaused = false
        }
    }
}

// MARK: - Available Voices
extension TTSService {
    var availableLanguages: [String] {
        ["zh-CN", "en-US", "ja-JP", "ko-KR", "fr-FR", "de-DE", "es-ES"]
    }
    
    func displayNameForLanguage(_ language: String) -> String {
        switch language {
        case "zh-CN": return "Chinese"
        case "en-US": return "English"
        case "ja-JP": return "Japanese"
        case "ko-KR": return "Korean"
        case "fr-FR": return "French"
        case "de-DE": return "German"
        case "es-ES": return "Spanish"
        default: return language
        }
    }
} 