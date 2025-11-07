//
//  CollectibleDetailARContainer.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 06/11/25.
//


//
//  CollectibleDetailARContainer.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 06/11/25.
//

import SwiftUI
import RealityKit
import ARKit

struct CollectibleDetailARContainer : UIViewRepresentable {
   
    @Environment(CollectibleManager.self) var collectibleManager

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
            
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .vertical
        config.isLightEstimationEnabled = true
        
        arView.session.run(config)
        arView.addCoaching()
        
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handleTap)
        )
        arView.addGestureRecognizer(tapGesture)
        
        context.coordinator.collectibleManager = collectibleManager
        context.coordinator.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.collectibleManager = collectibleManager
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var collectibleManager: CollectibleManager?
        weak var arView: ARView?
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView,
                  let collectibleManager = collectibleManager,
                  let collectible = collectibleManager.selectedCollectibleForDetail,
                  let image = collectible.uiImage else {
                print("⚠️ No collectible selected or image data is missing.")
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
            
            if let stickerEntity = createStickerEntity(from: image) {
                let anchor = AnchorEntity(world: firstResult.worldTransform)
                
                stickerEntity.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                stickerEntity.transform.rotation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
                            
                anchor.addChild(stickerEntity)
                arView.scene.addAnchor(anchor)
                
                print("✅ Collectible placed on wall!")
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

extension ARView {
    
    func addCoaching() {
        let coachingOverlay = ARCoachingOverlayView()
    
        coachingOverlay.goal = .verticalPlane
        coachingOverlay.session = self.session
        
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        self.addSubview(coachingOverlay)
        
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            coachingOverlay.topAnchor.constraint(equalTo: self.topAnchor),
            coachingOverlay.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            coachingOverlay.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            coachingOverlay.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
}
