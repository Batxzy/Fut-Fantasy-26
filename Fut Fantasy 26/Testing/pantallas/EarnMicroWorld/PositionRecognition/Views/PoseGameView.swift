//
//  PoseGameView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 07/11/25.
//

import SwiftUI
import Vision
import AVFoundation
import Observation
import CoreML


struct PoseGameView: View {
    // Use the FUSED GameViewModel
    @State private var gameViewModel = GameViewModel()
    
    @Namespace private var gameNamespace
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea() // Use a clear background color
            
            switch gameViewModel.gameState {
            case .start:
                StartView(gameViewModel: gameViewModel, namespace: gameNamespace)
                
            case .playing:
                PlayingView(gameViewModel: gameViewModel, namespace: gameNamespace)
                    .transition(.push(from: .bottom).combined(with: .scale))
            case .end:
                EndView(gameViewModel: gameViewModel)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .statusBar(hidden: true)
        .toolbarVisibility(.hidden, for: .tabBar)
    }
}

// MARK: - StartSubView

struct StartView: View {
    @Bindable var gameViewModel: GameViewModel
    var namespace: Namespace.ID
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Turn your camera on and replicate the pose")
                .font(.title).bold()
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            
            Image(gameViewModel.referencePoseImageName)
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .cornerRadius(20)
                .matchedGeometryEffect(id: "refImage", in: namespace)
            
            Button(action: {
                Task {
                    await gameViewModel.startGame()
                }
            }) {
                Text("Try it")
                    .font(.title2).bold()
                    .foregroundStyle(.black)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 80)
                    .background(Color.green) // Placeholder color
                    .cornerRadius(30)
            }
        }
    }
}

// MARK: - PlayingSubView

struct PlayingView: View {
    @Bindable var gameViewModel: GameViewModel
    var namespace: Namespace.ID
    
    @State private var isImageFocused = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // FUSED: This new CameraPreviewView uses UIKit's AVCaptureVideoPreviewLayer
                // and correctly binds to the videoOrientation.
                CameraPreviewView(
                    session: gameViewModel.cameraViewModel.session,
                    // --- FIX: Use the correct parameter and property name ---
                    videoRotationAngle: $gameViewModel.cameraViewModel.videoRotationAngle
                )
                .ignoresSafeArea()
                .blur(radius: isImageFocused ? 10 : 0)
                
                // FUSED: This new PoseOverlayView uses the drawing logic
                // from your "Old" files (gradients, landmark style).
                PoseOverlayView(
                    pose: gameViewModel.poseViewModel.detectedPose
                )
                .blur(radius: isImageFocused ? 10 : 0)
                
                
                // ✅ Dark overlay BEFORE image (No change)
                if isImageFocused {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
                
                VStack {
                    // FUSED: This button now calls the robust toggleCameraSelection()
                    HStack {
                        Spacer()
                        Button(action: {
                            gameViewModel.cameraViewModel.toggleCameraSelection()
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.system(size: 24))
                                .foregroundStyle(.black)
                                .padding(12)
                                .background(Color.white.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 20)
                        .padding(.top, 20)
                    }
                    .opacity(isImageFocused ? 0 : 1)
                    
                    Spacer()
                    
                    // FUSED: This text now reads from the new ActionPrediction model
                    Text(gameViewModel.poseViewModel.prediction.confidenceString ?? gameViewModel.poseViewModel.prediction.label)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(gameViewModel.poseViewModel.prediction.isModelLabel ? .green : .white)
                        .padding(10)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .opacity(isImageFocused ? 0 : 1)
                        .animation(.easeInOut, value: gameViewModel.poseViewModel.prediction.label)
                    
                    
                    ZStack {
                        // FUSED: This button now calls the fused endGame()
                        Button(action: gameViewModel.endGame) {
                            ZStack {
                                Circle()
                                    .stroke(Color.green, lineWidth: 3) // Placeholder
                                    .frame(width: 70, height: 70)
                                
                                Circle()
                                    .fill(Color.green) // Placeholder
                                    .frame(width: 55, height: 55)
                            }
                        }
                        .opacity(isImageFocused ? 0 : 1)
                        
                        HStack {
                            Spacer()
                            
                            // No change to this UI logic
                            Image(gameViewModel.referencePoseImageName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 120)
                                .cornerRadius(10)
                                .matchedGeometryEffect(id: "refImage", in: namespace)
                                .padding(.leading, 20)
                                .scaleEffect(isImageFocused ? 4 : 1)
                                .offset(
                                    x: isImageFocused ? -(geometry.size.width - 70) / 2 : 0,
                                    y: isImageFocused ? -(geometry.size.height - 100) / 2 : 0
                                )
                                .zIndex(isImageFocused ? 10 : 0)
                                .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
                                    withAnimation(.spring(response: 0.3)) {
                                        isImageFocused = pressing
                                    }
                                }, perform: {})
                        }
                    }
                    .padding(.bottom, 40)
                    .padding(.horizontal, 24)
                }
            }
            .onAppear {
                // FUSED: This now calls the robust orientation update
                gameViewModel.cameraViewModel.updateDeviceOrientation()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                // FUSED: This now calls the robust orientation update
                gameViewModel.cameraViewModel.updateDeviceOrientation()
            }
        }
    }
}

// MARK: - EndSubView

struct EndView: View {
    @Bindable var gameViewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    // FUSED: Reads score from the fused view model
    var isPerfect: Bool {
        gameViewModel.finalScore >= 0.8
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea() // Placeholder
            
            ContentLayer(
                isPerfect: isPerfect,
                score: gameViewModel.finalScore,
                restartAction: gameViewModel.restartGame,
                FrameImage: gameViewModel.finalImage
            )
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Exit") { dismiss() }
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - Content Layer End
private struct ContentLayer: View {
    let isPerfect: Bool
    let score: Double
    let restartAction: () -> Void
    let FrameImage : Image?
    
    var body: some View {
        VStack {
            Spacer()
            
            if isPerfect {
                
                winContent(score: score, FrameImage: FrameImage)
                
            } else {
                // Uses the Card from Cards.swift
                AlmostCard(score: score, restartAction: restartAction)
            }
            
            Spacer()
        }
    }
}


struct winContent : View {
    
    let score : Double
    let FrameImage : Image?
    var body: some View {
        
        VStack(spacing: 24){
            
            if let FrameImage {
                FrameImage
                    .resizable()
                    .scaledToFit()
                    .frame(width: 298)
                    .cornerRadius(16) // Added corner radius
            } else {
                Color.secondary.frame(width: 298, height: 298 * (4/3)) // Placeholder
            }
            
            // Uses the Card from Cards.swift
            WinCard(score: score)
        }
        .padding(24)
    }
}
