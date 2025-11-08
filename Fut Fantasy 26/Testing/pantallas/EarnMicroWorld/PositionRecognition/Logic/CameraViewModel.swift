//
//  CameraViewModel.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 07/11/25.
//

import AVFoundation
import SwiftUI

@Observable
class CameraViewModel_1 {
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let videoDataOutputQueue = DispatchQueue(label: "videoDataOutputQueue")
    private let videoDataOutput = AVCaptureVideoDataOutput()
    weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    
    private var isConfigured = false
    
    // --- New properties for iOS 17+ orientation ---
    private var videoDevice: AVCaptureDevice?
    private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    private var rotationObservation: NSKeyValueObservation?
    
    /// The correct rotation angle for the PREVIEW layer.
    var previewRotationAngle: CGFloat = 0.0
    // ---
    
    
    // REMOVED: All old UIDevice orientation logic (start/stop/update)
    
    func checkPermission() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            await setupCamera()
        case .notDetermined:
            if await AVCaptureDevice.requestAccess(for: .video) {
                await setupCamera()
            }
        default:
            print("Camera permission denied")
        }
    }
    
    
    private func setupCamera() async {
        guard !isConfigured else { return }
        
        await withCheckedContinuation { continuation in
            sessionQueue.async {
                guard !self.isConfigured else {
                    continuation.resume()
                    return
                }
                
                self.session.beginConfiguration()
                
                guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                      let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
                    print("Failed to create video input")
                    self.session.commitConfiguration()
                    continuation.resume()
                    return
                }
                
                self.videoDevice = videoDevice // Store the device
                
                if self.session.canAddInput(videoInput) { self.session.addInput(videoInput) }
                
                self.videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                self.videoDataOutput.setSampleBufferDelegate(self.delegate, queue: self.videoDataOutputQueue)
                self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
                
                if self.session.canAddOutput(self.videoDataOutput) { self.session.addOutput(self.videoDataOutput) }
                
                // --- Start iOS 17+ rotation handling ---
                self.rotationCoordinator = AVCaptureDevice.RotationCoordinator(device: videoDevice, previewLayer: nil)
                
                // Set the initial preview rotation
                DispatchQueue.main.async {
                    self.previewRotationAngle = self.rotationCoordinator?.videoRotationAngleForHorizonLevelPreview ?? 0.0
                }
                
                // Observe changes to the PREVIEW angle
                self.rotationObservation = self.rotationCoordinator?.observe(\.videoRotationAngleForHorizonLevelPreview, options: .new) { [weak self] _, change in
                    guard let newAngle = change.newValue else { return }
                    DispatchQueue.main.async {
                        self?.previewRotationAngle = newAngle
                    }
                }
                // --- End rotation handling ---
                
                self.session.commitConfiguration()
                self.isConfigured = true
                self.session.startRunning()
                
                continuation.resume()
            }
        }
    }
    
    func stopSession() {
        // --- Stop KVO observation ---
        rotationObservation?.invalidate()
        rotationObservation = nil
        rotationCoordinator = nil
        videoDevice = nil
        
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                self.isConfigured = false
            }
        }
    }
}
