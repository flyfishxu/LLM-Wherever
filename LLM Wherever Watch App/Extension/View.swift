//
//  View.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

extension View {
    @ViewBuilder
    func applyGlassIfAvailable() -> some View {
        if #available(watchOS 26.0, *) {
            self.glassEffect()
        } else {
            self
        }
    }
}
