//
//  TTSSettings.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import Foundation

struct TTSSettings: Codable, Equatable {
    var isEnabled: Bool = false
    var speechRate: Float = 0.5
    var voiceLanguage: String = "en-US"
    
    static let shared: TTSSettings = {
        guard let data = UserDefaults.standard.data(forKey: "TTSSettings"),
              let settings = try? JSONDecoder().decode(TTSSettings.self, from: data) else {
            return TTSSettings()
        }
        return settings
    }()
    
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "TTSSettings")
        }
    }
} 