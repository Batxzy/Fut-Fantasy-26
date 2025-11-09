//
//  CameraPreviewView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 07/11/25.
//

import SwiftUI
import AVKit
import CoreML
import Vision


struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoRotationAngle = 90
        view.layer.addSublayer(previewLayer)
        
        // Store the layer for updates
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = context.coordinator.previewLayer {
            DispatchQueue.main.async {
                previewLayer.frame = uiView.bounds
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

struct PoseOverlayView: View {
    let bodyParts: [HumanBodyPoseObservation.JointName: CGPoint]
    let connections: [BodyConnection]
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Draw connections
                for connection in connections {
                    if let fromPoint = bodyParts[connection.from],
                       let toPoint = bodyParts[connection.to] {
                        let from = CGPoint(x: fromPoint.x * size.width, y: fromPoint.y * size.height)
                        let to = CGPoint(x: toPoint.x * size.width, y: toPoint.y * size.height)
                        var path = Path()
                        path.move(to: from)
                        path.addLine(to: to)
                        context.stroke(path, with: .color(.green), lineWidth: 4)
                    }
                }
                
                // Draw joints
                for (_, point) in bodyParts {
                    let center = CGPoint(x: point.x * size.width, y: point.y * size.height)
                    let rect = CGRect(x: center.x - 6, y: center.y - 6, width: 12, height: 12)
                    context.fill(Circle().path(in: rect), with: .color(.green))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .allowsHitTesting(false)
    }
}
