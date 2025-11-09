//
//  StickerARViewContainer.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 06/11/25.
//


import SwiftUI
import RealityKit
import ARKit
import SwiftData


struct StickerARViewContainer: UIViewRepresentable {
    @Binding var selectedCollectible: Collectible?
    @Binding var showPlanes: Bool
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .vertical
        config.isLightEstimationEnabled = true
        
        arView.session.delegate = context.coordinator
        arView.session.run(config)
        arView.addCoaching()
        
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handleTap)
        )
        arView.addGestureRecognizer(tapGesture)
        
        context.coordinator.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.selectedCollectible = selectedCollectible
        context.coordinator.updatePlaneVisibility(showPlanes)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        var selectedCollectible: Collectible?
        weak var arView: ARView?
        var planeAnchors: [UUID: AnchorEntity] = [:]
        var showPlanes: Bool = false
        
        // ARSessionDelegate methods
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
                addPlaneVisualization(for: planeAnchor)
            }
        }
        
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
                updatePlaneVisualization(for: planeAnchor)
            }
        }
        
        func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
            for anchor in anchors {
                guard let planeAnchor = anchor as? ARPlaneAnchor else { continue }
                removePlaneVisualization(for: planeAnchor)
            }
        }
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView,
                  let collectible = selectedCollectible else {
                print("⚠️ No collectible selected")
                return
            }
            
            guard let uiImage = collectible.uiImage else {
                print("⚠️ Selected item has no placeable image data.")
                return
            }
            
            let tapLocation = recognizer.location(in: arView)
            
            let results = arView.raycast(
                from: tapLocation,
                allowing: .estimatedPlane,
                alignment: .vertical
            )
            
            guard let firstResult = results.first else {
                print("⚠️ No vertical surface detected")
                return
            }
            
            if let stickerEntity = createStickerEntity(from: uiImage) {
                let anchor = AnchorEntity(world: firstResult.worldTransform)
                stickerEntity.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                stickerEntity.transform.rotation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
                anchor.addChild(stickerEntity)
                arView.scene.addAnchor(anchor)
                print("✅ Collectible placed on wall!")
            }
        }
        
        private func addPlaneVisualization(for planeAnchor: ARPlaneAnchor) {
            guard let arView = arView else { return }
            
            let anchor = AnchorEntity(anchor: planeAnchor)
            
            let mesh = MeshResource.generatePlane(
                width: planeAnchor.planeExtent.width,
                depth: planeAnchor.planeExtent.height
            )
            
            var material = SimpleMaterial()
            material.color = .init(
                tint: UIColor(Color.wpMint).withAlphaComponent(0.3),
                texture: nil
            )
            
            let planeEntity = ModelEntity(mesh: mesh, materials: [material])
            planeEntity.position = [planeAnchor.center.x, 0, planeAnchor.center.z]
            
            anchor.addChild(planeEntity)
            anchor.isEnabled = showPlanes
            arView.scene.addAnchor(anchor)
            
            planeAnchors[planeAnchor.identifier] = anchor
        }
        
        private func updatePlaneVisualization(for planeAnchor: ARPlaneAnchor) {
            guard let anchor = planeAnchors[planeAnchor.identifier],
                  let planeEntity = anchor.children.first as? ModelEntity else { return }
            
            let mesh = MeshResource.generatePlane(
                width: planeAnchor.planeExtent.width,
                depth: planeAnchor.planeExtent.height
            )
            
            planeEntity.model?.mesh = mesh
            planeEntity.position = [planeAnchor.center.x, 0, planeAnchor.center.z]
        }
        
        private func removePlaneVisualization(for planeAnchor: ARPlaneAnchor) {
            guard let anchor = planeAnchors[planeAnchor.identifier] else { return }
            arView?.scene.removeAnchor(anchor)
            planeAnchors.removeValue(forKey: planeAnchor.identifier)
        }
        
        func updatePlaneVisibility(_ show: Bool) {
            showPlanes = show
            for anchor in planeAnchors.values {
                anchor.isEnabled = show
            }
        }
        
        private func createStickerEntity(from image: UIImage) -> ModelEntity? {
            guard let cgImage = image.cgImage else {
                print("❌ Failed to get CGImage")
                return nil
            }
            
            guard let texture = try? TextureResource(
                image: cgImage,
                options: .init(semantic: .color)
            ) else {
                print("❌ Failed to create texture")
                return nil
            }
            
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: .white, texture: .init(texture))
            material.metallic = .init(floatLiteral: 0.0)
            material.roughness = .init(floatLiteral: 1.0)
            material.emissiveColor = .init(texture: .init(texture))
            material.emissiveIntensity = 0.6
            material.blending = .transparent(opacity: 1.0)
            material.opacityThreshold = 0.0
            
            let width: Float = 0.3
            let aspectRatio = Float(image.size.height / image.size.width)
            let height = width * aspectRatio
            
            let planeMesh = MeshResource.generatePlane(width: width, height: height)
            let modelEntity = ModelEntity(mesh: planeMesh, materials: [material])
            
            return modelEntity
        }
    }
}
