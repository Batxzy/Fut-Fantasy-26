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
    var cameraViewModel = CameraViewModel_1()
    var poseViewModel = PoseEstimationViewModel_1()
    
    var gameState: GameState = .start
    
    var finalImage: Image?
    var finalScore: Double = 0.0
    
    var referencePoseImageName: String = "Messi Celebration Pointing Up"
    
    init() {
        cameraViewModel.delegate = poseViewModel
    }
    
    func startGame() async {
        print("Starting game...")
        
        do {
            try await poseViewModel.loadModelAsync()
            
            
            poseViewModel.messiConfidence = 0.0
            poseViewModel.noPoseConfidence = 0.0
            
            await cameraViewModel.checkPermission()
            
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    gameState = .playing
                }
            }
            
        } catch {
            // Handle the error, e.g., show an alert to the user
            print("❌ FAILED TO START GAME: Could not load Core ML model.")
        }
    }
    
    func endGame() {
        print("Ending game...")
        cameraViewModel.stopSession()
        
        self.finalScore = poseViewModel.messiConfidence
        
        if let buffer = poseViewModel.lastSampleBuffer {
            self.finalImage = imageFromSampleBuffer(buffer)
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            gameState = .end
        }
    }
    
    func restartGame() {
        print("Restarting game...")
        self.finalImage = nil
        self.finalScore = 0.0
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            gameState = .start
        }
    }
    
    private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> Image? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        let context = CIContext()
        
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
        
        return Image(uiImage: uiImage)
    }
}
