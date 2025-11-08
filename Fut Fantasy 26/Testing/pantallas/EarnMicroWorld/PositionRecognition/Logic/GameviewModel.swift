//
//  GameViewModel.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 07/11/25.
//

import SwiftUI
import Vision
import AVFoundation
import Observation
import CoreML


enum GameState {
    case start
    case playing
    case end
}

@Observable
class GameViewModel {
    // FUSED: Use the new robust ViewModels
    var cameraViewModel = CameraViewModel()
    var poseViewModel = PoseEstimationViewModel()
    
    var gameState: GameState = .start
    
    var finalImage: Image?
    var finalScore: Double = 0.0
    
    var referencePoseImageName: String = "Messi Celebration Pointing Up" // No change
    
    init() {
        // FUSED: Wire up the camera output to the pose processor
        cameraViewModel.delegate = poseViewModel
    }
    
    @MainActor
    func startGame() async {
        print("Starting game...")
        
        do {
            // 1. Load the ML Model
            try await poseViewModel.loadModelAsync()
            
            // 2. Reset scores
            poseViewModel.resetPrediction()
            
            // 3. Start the camera session
            // This now handles permissions internally
            await cameraViewModel.startSession()
            
            // 4. Update UI state
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                gameState = .playing
            }
            
        } catch {
            // Handle the error, e.g., show an alert to the user
            print("❌ FAILED TO START GAME: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func endGame() {
        print("Ending game...")
        
        // 1. Stop the camera
        cameraViewModel.stopSession()
        
        // 2. Get the final score from the pose view model
        // We check if it's a model label before assigning
        if poseViewModel.prediction.isModelLabel {
            self.finalScore = poseViewModel.prediction.confidence
        } else {
            self.finalScore = 0.0 // Or handle as "No Pose", etc.
        }
        
        // 3. Get the last captured image
        if let buffer = poseViewModel.lastSampleBuffer {
            self.finalImage = imageFromSampleBuffer(buffer)
        }
        
        // 4. Update UI state
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            gameState = .end
        }
    }
    
    @MainActor
    func restartGame() {
        print("Restarting game...")
        self.finalImage = nil
        self.finalScore = 0.0
        
        // Reset the pose processor's prediction
        poseViewModel.resetPrediction()
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            gameState = .start
        }
    }
    
    // This helper function remains the same
    private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> Image? {
        // --- FIX 2: Corrected truncated line ---
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        // --- DEPRECATION FIX ---
        // Correctly handle image rotation from camera's rotation angle
        let rotationAngle = cameraViewModel.videoRotationAngle
        let uiOrientation: UIImage.Orientation
        
        switch rotationAngle {
        case 90.0:
            uiOrientation = .right
        case 270.0:
            uiOrientation = .left
        case 0.0:
            uiOrientation = .up
        case 180.0:
            uiOrientation = .down
        default:
            uiOrientation = .right // Default to portrait
        }

        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        // Apply the correct orientation
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: uiOrientation)
        
        // FUSED: Handle mirroring for front camera
        if cameraViewModel.isUsingFrontCamera {
            // Flip the image horizontally
            UIGraphicsBeginImageContextWithOptions(uiImage.size, false, uiImage.scale)
            let context = UIGraphicsGetCurrentContext()!
            context.translateBy(x: uiImage.size.width, y: 0)
            context.scaleBy(x: -1.0, y: 1.0)
            uiImage.draw(in: CGRect(origin: .zero, size: uiImage.size))
            let flippedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return Image(uiImage: flippedImage ?? uiImage)
        }
        
        return Image(uiImage: uiImage)
    }
}
