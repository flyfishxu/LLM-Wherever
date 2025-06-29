//
//  SettingsView.swift
//  LLM Wherever Watch App
//
//  Created by FlyfishXu on 2025/6/30.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var connectivityManager = WatchConnectivityManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(connectivityManager.apiProviders) { provider in
                        Button {
                            connectivityManager.selectProvider(provider)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(provider.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Text("\(provider.models.count) models")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if connectivityManager.selectedProvider?.id == provider.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                        .font(.caption)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("API Providers")
                }
                
                if let selectedProvider = connectivityManager.selectedProvider,
                   !selectedProvider.models.isEmpty {
                    Section {
                        ForEach(selectedProvider.models) { model in
                            Button {
                                connectivityManager.selectModel(model)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(model.effectiveName)
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        Text(model.identifier)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if connectivityManager.selectedModel?.id == model.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                            .font(.caption)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text("Models")
                    }
                }
                
                
                Section {
                    HStack {
                        Image(systemName: connectivityManager.isConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(connectivityManager.isConnected ? .green : .red)
                        Text("iPhone Connection")
                        Spacer()
                        Text(connectivityManager.isConnected ? "Connected" : "Disconnected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Connection Status")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.caption)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
} 