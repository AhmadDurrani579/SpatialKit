//
//  AgentView.swift
//  SpatialKit
//
//  Created by Ahmad on 09/04/2026.
//


import SwiftUI
import SpatialKit

struct AgentView: View {
    
    @ObservedObject var sdk: SpatialKitSDK
    @Binding var appState: MainView.AppState
    
    @State private var chatHistory: [(q: String, a: String)] = []
    @State private var question:    String = ""
    @State private var isListening: Bool   = false
    @State private var isAsking:    Bool   = false
    @State private var useTextInput: Bool  = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            VStack(spacing: 0) {
                // detection labels
                DetectionLabels(sdk: sdk) { obj in
                    guard let arView = sdk.arView else { return }
                    sdk.navigationManager.navigate(to: obj, in: arView)
                }
                .padding(.top, 54)
                
                Spacer()
                
                // chat history
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(chatHistory.enumerated()),
                                id: \.offset) { _, chat in
                            
                            // user message
                            HStack {
                                Spacer()
                                Text(chat.q)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(16)
                                    .padding(.leading, 60)
                            }
                            
                            // agent response
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(chat.a)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(Color(white: 0.12))
                                        .cornerRadius(16)
                                        .padding(.trailing, 60)
                                    Spacer()
                                }
                                
                                // navigate button
                                if let nav = extractNav(from: chat.a) {
                                    let dist = sdk.sceneGraph.allObjects()
                                        .first { $0.label.lowercased() == nav }?
                                        .distance ?? 0
                                    
                                    Button {
                                        triggerNav(nav)
                                    } label: {
                                        HStack {
                                            Text("Navigate to \(nav)")
                                                .font(.system(size: 13,
                                                              weight: .medium))
                                            Spacer()
                                            Text("\(Int(dist))m →")
                                                .font(.system(size: 12))
                                        }
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Color.green.opacity(0.12))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.green.opacity(0.4),
                                                        lineWidth: 1)
                                        )
                                        .cornerRadius(12)
                                    }
                                    .padding(.trailing, 60)
                                }
                            }
                        }
                        
                        if isAsking {
                            HStack {
                                Text("thinking...")
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.4))
                                    .padding(12)
                                    .background(Color(white: 0.12))
                                    .cornerRadius(16)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            InputBar(
                question:     $question,
                isListening:  $isListening,
                isAsking:     $isAsking,
                useTextInput: useTextInput,
                onMicTap:     { handleMic() },
                onSubmit:     { ask($0) }
            )
        }
        .ignoresSafeArea(.keyboard)
    }
    
    private func ask(_ text: String) {
        guard !text.isEmpty && !isAsking else { return }
        isAsking = true
        
        Task {
            let response = await sdk.ask(text)
            await MainActor.run {
                chatHistory.append((q: text, a: response))
                if chatHistory.count > 3 { chatHistory.removeFirst() }
                isAsking = false
            }
        }
    }
    
    private func handleMic() {
        useTextInput.toggle()
    }
    
    private func extractNav(from text: String) -> String? {
        guard let range = text.range(of: #"\[NAVIGATE:(.+?)\]"#,
                                      options: .regularExpression)
        else { return nil }
        return String(text[range])
            .replacingOccurrences(of: "[NAVIGATE:", with: "")
            .replacingOccurrences(of: "]", with: "")
            .trimmingCharacters(in: .whitespaces)
            .lowercased()
    }
    
    private func triggerNav(_ label: String) {
        let all = sdk.sceneGraph.allObjects()
        if let match = all.first(where: {
            $0.label.lowercased().contains(label)
        }), let arView = sdk.arView {
            sdk.navigationManager.navigate(to: match, in: arView)
        }
    }
}
