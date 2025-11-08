//
//  CameraViewModel.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 07/11/25.
//

//
//  CameraViewModel.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 07/11/25.
//

import SwiftUI
import AVFoundation
import Observation

// --- FIX 2: Moved AVCaptureDevice extension here to resolve compiler error ---
// By placing it here, the compiler will see it before it's used.
// MARK: - From AVCaptureDevice+FrameRate.swift
extension AVCaptureDevice {
    func configureFrameRate(_ frameRate: Double) -> Bool {
        do { try lockForConfiguration() } catch {
            print("`AVCaptureDevice` wasn't unable to lock: \(error)")
            return false
        }

        defer { unlockForConfiguration() }

        let sortedRanges = activeFormat.videoSupportedFrameRateRanges.sorted {
            $0.maxFrameRate > $1.maxFrameRate
        }
        
        guard let range = sortedRanges.first else {
            print("⚠️ No frame rate ranges available")
            return false
        }

        guard frameRate >= range.minFrameRate else {
            print("⚠️ Requested frame rate \(frameRate) is below minimum \(range.minFrameRate)")
            return false
        }

        let duration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
        let inRange = frameRate <= range.maxFrameRate
        
        activeVideoMinFrameDuration = inRange ? duration : range.minFrameDuration
        activeVideoMaxFrameDuration = inRange ? duration : range.maxFrameDuration // Use exact rate if possible

        print("✅ Configured frame rate to: \(frameRate) fps")
        return true
    }
}

// --- NEW FIX: Moved AVCaptureVideoDataOutput extension here ---
// MARK: - From AVCaptureVideoDataOutput+PixelFormat.swift
extension AVCaptureVideoDataOutput {
    static func withPixelFormatType(_ pixelFormatType: OSType) -> AVCaptureVideoDataOutput {
        let videoDataOutput = AVCaptureVideoDataOutput()
        let validPixelTypes = videoDataOutput.availableVideoPixelFormatTypes

        guard validPixelTypes.contains(pixelFormatType) else {
            fatalError("`AVCaptureVideoDataOutput` doesn't support pixel format type: \(pixelFormatType)")
        }

        let pixelTypeKey = String(kCVPixelBufferPixelFormatTypeKey)
        videoDataOutput.videoSettings = [pixelTypeKey: pixelFormatType]
        return videoDataOutput
    }
}


@Observable
class CameraViewModel: NSObject {
    
    // MARK: - Public Properties
    
    /// The capture session (published for the UIKit PreviewView)
    let session = AVCaptureSession()
    
    /// --- DEPRECATION FIX ---
    /// The current rotation angle (published for the UIKit PreviewView)
    var videoRotationAngle: Double = 90.0 // Default to portrait
    
    /// Delegate to send sample buffers to (will be the PoseEstimationViewModel)
    weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    
    var isUsingFrontCamera: Bool {
        cameraPosition == .front
    }

    // MARK: - Private Properties
    
    private let sessionQueue = DispatchQueue(label: "com.posegame.sessionQueue")
    private let videoDataOutputQueue = DispatchQueue(label: "com.posegame.videoDataOutputQueue")
    
    private var videoDataOutput = AVCaptureVideoDataOutput()
    private var videoInput: AVCaptureDeviceInput?
    
    // --- ✅ FIX 1: Set default camera to .back ---
    private var cameraPosition = AVCaptureDevice.Position.back
    private var isConfigured = false
    
    // From your old file, to set model's desired frame rate
    private let modelFrameRate = 30.0
    
    // MARK: - Public API
    
    func startSession() async {
        // Check permissions first
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // Already authorized, configure session
            configureSession()
        case .notDetermined:
            // Request access
            if await AVCaptureDevice.requestAccess(for: .video) {
                // Access granted
                configureSession()
            } else {
                // Access denied
                print("❌ Camera permission denied")
            }
        default:
            // Denied or restricted
            print("❌ Camera permission denied or restricted")
        }
    }
    
    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
                self.isConfigured = false
                print("🛑 Camera session stopped.")
            }
        }
    }
    
    /// FUSED: From your "Old" VideoCapture.swift
    func toggleCameraSelection() {
        cameraPosition = (cameraPosition == .back) ? .front : .back
        
        // Re-configure the session with the new camera
        configureSession()
    }
    
    /// FUSED: From your "Old" VideoCapture.swift
    func updateDeviceOrientation() {
        let currentPhysicalOrientation = UIDevice.current.orientation
        
        let newRotationAngle: Double
        
        // --- DEPRECATION FIX ---
        // Map UIDeviceOrientation to videoRotationAngle
        switch currentPhysicalOrientation {
        case .portrait:
            newRotationAngle = 90.0
        case .portraitUpsideDown:
            newRotationAngle = 270.0
        case .landscapeLeft:
            newRotationAngle = 180.0 // Device is left, sensor is 180
        case .landscapeRight:
            newRotationAngle = 0.0   // Device is right, sensor is 0
        default:
            newRotationAngle = self.videoRotationAngle // Keep current
        }
        
        if self.videoRotationAngle != newRotationAngle {
            self.videoRotationAngle = newRotationAngle
            print("🔄 Device rotation updated to: \(newRotationAngle) degrees")
            
            // --- DEPRECATION FIX ---
            // Manually update the running connection's angle
            sessionQueue.async {
                if let connection = self.videoDataOutput.connection(with: .video) {
                    // --- FIX 1: Call function with the angle ---
                    let cgAngle = CGFloat(newRotationAngle)
                    if connection.isVideoRotationAngleSupported(cgAngle) {
                        connection.videoRotationAngle = cgAngle
                    }
                }
            }
        }
    }

    // MARK: - Private Session Configuration
    
    private func configureSession() {
        sessionQueue.async {
            // --- ✅ FIX 2: REMOVED the `guard !self.isConfigured` block ---
            // This allows the function to re-run when toggling the camera.
            
            self.session.beginConfiguration()
            
            // 1. Remove old inputs/outputs
            if let currentInput = self.videoInput {
                self.session.removeInput(currentInput)
            }
            if self.session.outputs.contains(self.videoDataOutput) {
                self.session.removeOutput(self.videoDataOutput)
            }

            // 2. Configure Input (Fused from AVCaptureDeviceInput+Camera.swift)
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.cameraPosition),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                print("❌ Failed to create video input for \(self.cameraPosition) camera")
                self.session.commitConfiguration()
                return
            }
            
            // FUSED: Configure frame rate (from AVCaptureDevice+FrameRate.swift)
            if !camera.configureFrameRate(self.modelFrameRate) {
                print("⚠️ Failed to set frame rate to \(self.modelFrameRate)")
            }
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
                self.videoInput = input
            } else {
                print("❌ Could not add video input to session")
                self.session.commitConfiguration()
                return
            }

            // 3. Configure Output (Fused from AVCaptureVideoDataOutput+PixelFormat.swift)
            // --- This line will now compile correctly ---
            self.videoDataOutput = AVCaptureVideoDataOutput.withPixelFormatType(kCVPixelFormatType_32BGRA)
            self.videoDataOutput.setSampleBufferDelegate(self.delegate, queue: self.videoDataOutputQueue)
            self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
            
            if self.session.canAddOutput(self.videoDataOutput) {
                self.session.addOutput(self.videoDataOutput)
            } else {
                print("❌ Could not add video output to session")
                self.session.commitConfiguration()
                return
            }
            
            // 4. Configure Connection Properties
            if let connection = self.videoDataOutput.connection(with: .video) {
                
                // --- DEPRECATION FIX ---
                // --- FIX 2: Call function with the angle ---
                let cgAngle = CGFloat(self.videoRotationAngle)
                if connection.isVideoRotationAngleSupported(cgAngle) {
                    // Set initial orientation
                    connection.videoRotationAngle = cgAngle
                } else {
                    print("⚠️ Video rotation angle is not supported on this connection.")
                }
                
                if connection.isVideoMirroringSupported {
                    // FUSED: Handle mirroring for front camera
                    connection.isVideoMirrored = (self.cameraPosition == .front)
                }
                
                // You can also enable stabilization if needed
                // if connection.isVideoStabilizationSupported {
                //    connection.preferredVideoStabilizationMode = .auto
                // }
            }
            
            self.session.commitConfiguration()
            self.isConfigured = true // We still set this, but we don't guard against it
            
            // 5. Start running
            if !self.session.isRunning {
                self.session.startRunning()
                print("✅ Camera session started.")
            }
        }
    }
}
