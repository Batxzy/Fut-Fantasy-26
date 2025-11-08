//
//  CameraPreviewView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 07/11/25.
//

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

struct CameraPreviewView_1: UIViewRepresentable {
    let session: AVCaptureSession
    
    // MODIFIED: Use rotationAngle (CGFloat) instead of orientation
    let rotationAngle: CGFloat
    
    // MODIFIED: Removed 'private' to fix the access control errors
    class PreviewView: UIView {
        let previewLayer: AVCaptureVideoPreviewLayer
        
        init(session: AVCaptureSession) {
            self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
            self.previewLayer.videoGravity = .resizeAspectFill
            super.init(frame: .zero)
            self.layer.addSublayer(previewLayer)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer.frame = self.bounds
        }
    }
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView(session: session)
        
        // MODIFIED: Use the new, non-deprecated properties
        if let connection = view.previewLayer.connection, connection.isVideoRotationAngleSupported(rotationAngle) {
            connection.videoRotationAngle = rotationAngle
        }
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        Task {
            if uiView.previewLayer.session != session {
                uiView.previewLayer.session = session
            }
            
            // MODIFIED: Use the new, non-deprecated properties
            if let connection = uiView.previewLayer.connection, connection.isVideoRotationAngleSupported(rotationAngle) {
                connection.videoRotationAngle = rotationAngle
            }
        }
    }
}


struct PoseOverlayView_1: View {
    let bodyParts: [HumanBodyPoseObservation.JointName: CGPoint]
    let connections: [BodyConnection_1]
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for connection in connections {
                    if let fromPoint = bodyParts[connection.from],
                       let toPoint = bodyParts[connection.to] {
                        let from = CGPoint(x: fromPoint.x * size.width, y: fromPoint.y * size.height)
                        let to = CGPoint(x: toPoint.x * size.width, y: fromPoint.y * size.height)
                        var path = Path()
                        path.move(to: from)
                        path.addLine(to: to)
                        context.stroke(path, with: .color(.green), lineWidth: 4)
                    }
                }
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
