//
//  CameraPreviewView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 07/11/25.
//


import SwiftUI
import AVKit
import Vision

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    // --- DEPRECATION FIX ---
    @Binding var videoRotationAngle: Double
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear // Ensure it's clear
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        
        // --- DEPRECATION FIX ---
        // --- FIX 1: Convert Double to CGFloat ---
        previewLayer.connection?.videoRotationAngle = CGFloat(videoRotationAngle)
        
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the layer's frame when the view's bounds change
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
            
            // --- DEPRECATION FIX ---
            // Update rotation angle
            // --- FIX 1: Convert Double to CGFloat ---
            let newRotation = CGFloat(videoRotationAngle)
            if previewLayer.connection?.videoRotationAngle != newRotation {
                previewLayer.connection?.videoRotationAngle = newRotation
            }
        }
    }
}

// MARK: - Pose Overlay

struct PoseOverlayView: View {
    let pose: Pose?
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                guard let pose = pose else { return }
                
                // Create the transform to scale normalized points to view size
                let transform = CGAffineTransform(scaleX: size.width, y: size.height)
                
                // FUSED: Draw connections using "Old" gradient logic
                for connection in pose.connections {
                    connection.drawToContext(context, applying: transform)
                }
                
                // FUSED: Draw landmarks using "Old" styling logic
                for landmark in pose.landmarks {
                    landmark.drawToContext(context, applying: transform)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .allowsHitTesting(false)
    }
}
