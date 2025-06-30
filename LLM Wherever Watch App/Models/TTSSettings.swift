//
//  TTSSettings.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import Foundation

struct TTSSettings: Codable, Equatable {
    var autoTTSAfterResponse: Bool = false  // Auto TTS after conversation ends
    var speechRate: Float = 0.5
    var voiceLanguage: String = "en-US"
    
    // Custom CodingKeys to handle the property name change
    enum CodingKeys: String, CodingKey {
        case autoTTSAfterResponse
        case speechRate
        case voiceLanguage
        // Legacy key for backward compatibility
        case isEnabled
    }
    
    // Custom initializer to handle backward compatibility
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode the new property name first, then fall back to the old one
        if container.contains(.autoTTSAfterResponse) {
            autoTTSAfterResponse = try container.decode(Bool.self, forKey: .autoTTSAfterResponse)
        } else if container.contains(.isEnabled) {
            autoTTSAfterResponse = try container.decode(Bool.self, forKey: .isEnabled)
        } else {
            autoTTSAfterResponse = false
        }
        
        speechRate = try container.decodeIfPresent(Float.self, forKey: .speechRate) ?? 0.5
        voiceLanguage = try container.decodeIfPresent(String.self, forKey: .voiceLanguage) ?? "en-US"
    }
    
    // Custom encoder to always use the new property name
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(autoTTSAfterResponse, forKey: .autoTTSAfterResponse)
        try container.encode(speechRate, forKey: .speechRate)
        try container.encode(voiceLanguage, forKey: .voiceLanguage)
    }
    
    // Default initializer
    init(autoTTSAfterResponse: Bool = false, speechRate: Float = 0.5, voiceLanguage: String = "en-US") {
        self.autoTTSAfterResponse = autoTTSAfterResponse
        self.speechRate = speechRate
        self.voiceLanguage = voiceLanguage
    }
    
    // Load settings from UserDefaults
    static func load() -> TTSSettings {
        guard let data = UserDefaults.standard.data(forKey: "TTSSettings"),
              let settings = try? JSONDecoder().decode(TTSSettings.self, from: data) else {
            return TTSSettings()
        }
        return settings
    }
    
    // Save settings to UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "TTSSettings")
        }
    }
} 