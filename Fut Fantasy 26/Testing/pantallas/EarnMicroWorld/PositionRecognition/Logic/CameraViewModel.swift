//
//  CameraViewModel.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 07/11/25.
//
import AVFoundation
import SwiftUI

@Observable
class CameraViewModel {
    
    private let cameraManager = CameraManager()
    weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    
    var session: AVCaptureSession {
        cameraManager.session
    }
    
    func setupCamera() async {
        guard let delegate = delegate else {
            print("⚠️ No delegate set for camera")
            return
        }
        
        await cameraManager.configure(with: delegate)
        await cameraManager.startSession()
    }
    
    func stopSession() {
        cameraManager.stopSession()
    }
}
