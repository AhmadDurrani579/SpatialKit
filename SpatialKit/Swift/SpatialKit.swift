//
//  SpatialKit.swift
//  SpatialKit
//
//  Created by Ahmad on 02/04/2026.
//

import Foundation
import ARKit
import Combine

public class SpatialKit: NSObject, ObservableObject {
    
    // MARK: - Public
    public static let shared = SpatialKit()
    
    @Published public var currentPose: [String: Any] = [:]
    @Published public var isRunning: Bool = false
    
    // MARK: - Private
    private let bridge = SpatialKitBridge()
    public var arSession: ARSession?
    
    // MARK: - Init
    private override init() {
        super.init()
    }
    
    // MARK: - Public API
    public func start() {
        guard !isRunning else { return }
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection        = [.horizontal, .vertical]
        config.environmentTexturing  = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        arSession = ARSession()
        arSession?.delegate = self
        arSession?.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        isRunning = true
        print("[SpatialSession] started")
    }
    
    public func stop() {
        arSession?.pause()
        bridge.reset()
        isRunning = false
        print("[SpatialSession] stopped")
    }
}

// MARK: - ARSessionDelegate
extension SpatialKit: ARSessionDelegate {
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        bridge.processARFrame(frame)
        currentPose = bridge.currentPose()
    }
    
    public func session(_ session: ARSession,
                        didFailWithError error: Error) {
        print("[SpatialSession] error: \(error.localizedDescription)")
    }
    
    public func sessionWasInterrupted(_ session: ARSession) {
        print("[SpatialSession] interrupted")
    }
    
    public func sessionInterruptionEnded(_ session: ARSession) {
        start()
    }
}
