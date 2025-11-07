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

struct StickerARViewContainer : UIViewRepresentable {
   
    // Takes the selected collectible from the sheet
    @Binding var selectedCollectible: Collectible?

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
            
        // configuracion del ar kit
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .vertical
        config.isLightEstimationEnabled = true
        
        arView.session.run(config)
        arView.addCoaching()
        
        // Añadir gesture recognizer para tap-to-place
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handleTap)
        )
        arView.addGestureRecognizer(tapGesture)
        
        // Pass the ARView to the coordinator
        context.coordinator.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // Update the coordinator with the currently selected sticker
        context.coordinator.selectedCollectible = selectedCollectible
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        var selectedCollectible: Collectible?
        weak var arView: ARView?
        
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
            
            // Create and place the sticker entity
            if let stickerEntity = createStickerEntity(
                from: uiImage
            ) {
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
            
            // Enable transparency
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
