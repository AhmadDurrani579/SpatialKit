import SwiftUI
import ARKit
import RealityKit
import SpatialKit

struct SpatialARViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session = SpatialSession.shared.arSession ?? ARSession()
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}