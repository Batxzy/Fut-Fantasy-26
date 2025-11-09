//
//  CameraManager.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 08/11/25.
//


import AVFoundation
import CoreImage

class CameraManager: NSObject {
    
    private let captureSession = AVCaptureSession()
    private var deviceInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let systemPreferredCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    
    private var sessionQueue = DispatchQueue(label: "video.preview.session")
    
    weak var delegate: AVCaptureVideoDataOutputSampleBufferDelegate?
    
    private var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            var isAuthorized = status == .authorized
            
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            
            return isAuthorized
        }
    }
    
    override init() {
        super.init()
    }
    
    func configure(with delegate: AVCaptureVideoDataOutputSampleBufferDelegate) async {
        self.delegate = delegate
        await configureSession()
    }
    
    private func configureSession() async {
        guard await isAuthorized,
              let systemPreferredCamera,
              let deviceInput = try? AVCaptureDeviceInput(device: systemPreferredCamera)
        else { 
            print("❌ Camera configuration failed: authorization or device unavailable")
            return 
        }
        
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            sessionQueue.async {
                self.captureSession.beginConfiguration()
                
                defer {
                    self.captureSession.commitConfiguration()
                    continuation.resume()
                }
                
                let videoOutput = AVCaptureVideoDataOutput()
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
                videoOutput.alwaysDiscardsLateVideoFrames = true
                videoOutput.setSampleBufferDelegate(self.delegate, queue: self.sessionQueue)
                
                guard self.captureSession.canAddInput(deviceInput) else {
                    print("❌ Cannot add video input")
                    return
                }
                
                guard self.captureSession.canAddOutput(videoOutput) else {
                    print("❌ Cannot add video output")
                    return
                }
                
                self.captureSession.addInput(deviceInput)
                self.captureSession.addOutput(videoOutput)
                self.deviceInput = deviceInput
                self.videoOutput = videoOutput
                
                // Portrait orientation for the camera stream
                videoOutput.connection(with: .video)?.videoRotationAngle = 90
            }
        }
    }
    
    func startSession() async {
        guard await isAuthorized else { 
            print("❌ Cannot start session: not authorized")
            return 
        }
        
        sessionQueue.async {
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                print("✅ Camera session started")
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                print("🛑 Camera session stopped")
            }
        }
    }
    
    var session: AVCaptureSession {
        return captureSession
    }
}