//
//  GameViewModel.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 07/11/25.
//

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
    
    var finalUIImage: UIImage?
    var finalScore: Double = 0.0
    
    var referencePoseImageName: String = "Messi Celebration Pointing Up"
    
    var exportProgress: Double = 0.0
    var isExportComplete: Bool = false
    var shareImageURL: URL?
    
    init() {
        cameraViewModel.delegate = poseViewModel
    }
    
    func startGame() async {
        print("Starting game...")
        
        do {
            try await poseViewModel.loadModelAsync()
            
            
            await cameraViewModel.checkPermission()
            
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    gameState = .playing
                }
            }
            
        } catch {
            print("❌ FAILED TO START GAME: Could not load Core ML model.")
        }
    }
    
    func endGame() {
        print("Ending game...")
        cameraViewModel.stopSession()
        
        self.finalScore = poseViewModel.messiConfidence
        
        if let buffer = poseViewModel.lastSampleBuffer {
            self.finalUIImage = uiImageFromSampleBuffer(buffer)
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            gameState = .end
        }
    }
    
    func restartGame() async {
        print("Restarting game...")
        
        self.finalUIImage = nil
        self.finalScore = 0.0
        self.shareImageURL = nil
        self.exportProgress = 0.0
        self.isExportComplete = false
        
        poseViewModel.reset()
        
        do {
            try await poseViewModel.loadModelAsync()
            
            await cameraViewModel.checkPermission()
            
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    gameState = .playing
                }
            }
        } catch {
            print("❌ FAILED TO RESTART GAME. Going to StartView.")
            await MainActor.run {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    gameState = .start
                }
            }
        }
    }
    
    func resetToStart() {
        print("Resetting game to start...")
        
        cameraViewModel.stopSession()

        self.finalUIImage = nil
        self.finalScore = 0.0
        self.shareImageURL = nil
        self.exportProgress = 0.0
        self.isExportComplete = false
        
      
        poseViewModel.reset()
        
        DispatchQueue.main.async {
            self.gameState = .start
        }
    }
    
    @MainActor
        func prepareShareImage(scale: CGFloat) async {
            self.exportProgress = 0.0
            self.isExportComplete = false
            self.shareImageURL = nil
            
            await MainActor.run { self.exportProgress = 0.2 }
            
            let viewToRender = ShareImageView(
                frameUIImage: self.finalUIImage,
                referencePoseImageName: self.referencePoseImageName
            )
            
            let renderer = ImageRenderer(content: viewToRender)
            
            renderer.scale = scale
            
            guard let uiImage = renderer.uiImage else {
                print("❌ Failed to render share image")
                return
            }
            
            await MainActor.run { self.exportProgress = 0.6 }
            
            guard let data = uiImage.pngData() else {
                print("❌ Failed to get PNG data from rendered image")
                return
            }
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("png")
            
            do {
                try data.write(to: tempURL)
                self.shareImageURL = tempURL
                await MainActor.run { self.exportProgress = 1.0 }
                try await Task.sleep(nanoseconds: 300_000_000)
                await MainActor.run { self.isExportComplete = true }
                try await Task.sleep(nanoseconds: 500_000_000)
            } catch {
                print("❌ Failed to write image data to temp URL: \(error)")
            }
        }
        
        private func uiImageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
            
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let context = CIContext()
            
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
            
            let uiImage = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
            
            return uiImage
        }
        
        
        private struct ShareImageView: View {
            let frameUIImage: UIImage?
            let referencePoseImageName: String
            @Namespace private var shareNamespace
            
            var body: some View {
                ZStack {
                    Color.mainBg.ignoresSafeArea()
                    
                    VStack {
                        if let uiImage = frameUIImage {
                            ZStack(alignment: .bottomTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 298)
                                    .cornerRadius(20)
                                
                                Image(referencePoseImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 120)
                                    .cornerRadius(10)
                                    .padding(8)
                                    .matchedGeometryEffect(id: "refImage", in: shareNamespace)
                            }
                        } else {
                            Color.black
                                .frame(width: 298, height: 400)
                                .cornerRadius(20)
                        }
                    }
                    .padding(24)
                }
            }
        }
    }
