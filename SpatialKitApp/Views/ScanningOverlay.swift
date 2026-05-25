//
//  ScanningView.swift
//  SpatialKit
//
//  Created by Ahmad on 09/04/2026.
//


import SwiftUI
import SpatialKit

struct ScanningOverlay: View {
    
    @ObservedObject var sdk: SpatialKitSDK
    @Binding var appState: MainView.AppState
    
    @State private var question:     String = ""
    @State private var isListening:  Bool   = false
    @State private var isAsking:     Bool   = false
    @State private var useTextInput: Bool   = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            ZStack(alignment: .top) {
                Color.clear
                
                VStack(spacing: 8) {
                    // top row — labels + scan ring
                    HStack(alignment: .top) {
                        DetectionLabels(sdk: sdk) { obj in
                            guard let arView = sdk.arView else { return }
                            sdk.navigationManager.navigate(to: obj, in: arView)
                        }
                        Spacer()
                        ScanRing(sdk: sdk)
                            .padding(.trailing, 16)
                    }
                    .padding(.top, 54)
                    
                    // scanning status
                    if sdk.sceneGraph.allObjects().isEmpty {
                        Text("scanning environment...")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                            .padding(.leading, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // input bar
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
    
    private func handleMic() {
        // toggle text/voice
        if !isListening {
            useTextInput = false
            // start voice
        } else {
            stopListening()
        }
    }
    
    private func ask(_ text: String) {
        guard !text.isEmpty && !isAsking else { return }
        isAsking = true
        withAnimation {
            appState = .agent
        }
        // trigger agent
        Task {
            let _ = await sdk.ask(text)
            await MainActor.run { isAsking = false }
        }
    }
    
    private func stopListening() {
        isListening = false
    }
}
