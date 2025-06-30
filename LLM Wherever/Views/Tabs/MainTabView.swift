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
        if #available(iOS 18.0, *) {
            TabView {
                Tab("Home", systemImage: "house") {
                    ProvidersView()
                }
                
                Tab("Settings", systemImage: "gearshape") {
                    SettingsTabView()
                }
                
                Tab("Search", systemImage: "magnifyingglass", role: .search) {
                    SearchView()
                }
            }
        } else {
            TabView {
                ProvidersView()
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                
                SettingsTabView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
                
                SearchView()
                    .tabItem {
                        Image(systemName: "magnifyingglass")
                        Text("Search")
                    }
            }
        }
    }
}

#Preview {
    MainTabView()
}



