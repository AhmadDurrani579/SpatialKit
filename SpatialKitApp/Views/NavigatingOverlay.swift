//
//  NavigationView.swift
//  SpatialKit
//
//  Created by Ahmad on 09/04/2026.
//

import SwiftUI
import SpatialKit

struct NavigatingOverlay: View {
    
    @ObservedObject var sdk: SpatialKitSDK
    @Binding var appState: MainView.AppState
    
    var body: some View {
        VStack(spacing: 0) {
            
            VStack(spacing: 0) {
                // top labels — still visible during navigation
                DetectionLabels(sdk: sdk) { _ in }
                    .padding(.top, 54)
                
                Spacer()
                
                // compass arrow
                CompassArrow(
                    bearing:  sdk.navigationManager.bearingDegrees,
                    label:    sdk.navigationManager.targetLabel,
                    distance: sdk.navigationManager.distanceToTarget
                )
                
                Spacer()
                
                // stop button
                Button {
                    sdk.navigationManager.stop()
                    withAnimation {
                        appState = .scanning
                    }
                } label: {
                    Text("Stop")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(24)
                }
                .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // input bar still accessible during navigation
            InputBar(
                question:     .constant(""),
                isListening:  .constant(false),
                isAsking:     .constant(false),
                useTextInput: false,
                onMicTap:     { },
                onSubmit:     { _ in }
            )
        }
    }
}
