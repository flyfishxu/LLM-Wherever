//
//  MainTabView.swift
//  LLM Wherever
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var mainViewModel = MainViewModel()
    
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house") {
                ProvidersView()
            }
            
            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                SearchView()
            }
            
            Tab("Settings", systemImage: "gearshape") {
                SettingsTabView()
            }
        }
    }
}

#Preview {
    MainTabView()
}



