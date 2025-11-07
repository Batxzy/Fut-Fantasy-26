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
    @State private var gameViewModel = GameViewModel()
    
    @Namespace private var gameNamespace
    
    var body: some View {
        ZStack {
            Color.mainBg.ignoresSafeArea()
            
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

// MARK: - 5. Game State Subviews


struct StartView: View {
    @Bindable var gameViewModel: GameViewModel
    var namespace: Namespace.ID
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Turn your camera on and replicate the pose")
                .font(.title).bold()
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            
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
                    .background(Color.wpGreenYellow)
                    .cornerRadius(30)
            }
        }
    }
}


struct PlayingView: View {
    @Bindable var gameViewModel: GameViewModel
    var namespace: Namespace.ID
    
    @State private var isImageFocused = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreviewView_1(
                    session: gameViewModel.cameraViewModel.session,
                    rotation: 90.0
                )
                .ignoresSafeArea()
                .blur(radius: isImageFocused ? 10 : 0)
                
                PoseOverlayView_1(
                    bodyParts: gameViewModel.poseViewModel.detectedBodyParts,
                    connections: gameViewModel.poseViewModel.bodyConnections
                )
                .blur(radius: isImageFocused ? 10 : 0)
                
                
                // ✅ Dark overlay BEFORE image
                if isImageFocused {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
                
                VStack {
                    Spacer()
                    ZStack {
                        Button(action: gameViewModel.endGame) {
                            ZStack {
                                Circle()
                                    .stroke(.wpGreenYellow, lineWidth: 3)
                                    .frame(width: 70, height: 70)
                                
                                Circle()
                                    .fill(.wpGreenYellow)
                                    .frame(width: 55, height: 55)
                            }
                        }
                        .opacity(isImageFocused ? 0 : 1)
                        
                        HStack {
                            Spacer()
                            
                            
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
        }
    }
}

struct EndView: View {
    @Bindable var gameViewModel: GameViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    var isPerfect: Bool {
        gameViewModel.finalScore >= 0.8
    }
    
    var body: some View {
        ZStack {
            if let finalImage = gameViewModel.finalImage {
                finalImage
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }
            
            Color.black.opacity(0.2).ignoresSafeArea()
            
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    if isPerfect {
                        Text("PERFECT!")
                            .font(.largeTitle).bold()
                        Text(String(format: "%.0f%% similarity", gameViewModel.finalScore * 100))
                            .font(.title2)
                        Text("+1000 ⭐️")
                            .font(.title).bold()
                            .foregroundStyle(.yellow)
                        
                        Button(action: { /* Add save logic */ }) {
                            Text("Claim")
                                .font(.title2).bold()
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(15)
                        }
                        
                    } else {
                        Text("ALMOST!")
                            .font(.largeTitle).bold()
                        Text(String(format: "%.0f%% similarity, try again!", gameViewModel.finalScore * 100))
                            .font(.title3)
                            .padding(.bottom, 10)
                        
                        Button(action: gameViewModel.restartGame) {
                            Image(systemName: "arrow.clockwise")
                                .font(.largeTitle)
                                .foregroundStyle(.white)
                                .padding(20)
                                .background(Color.white.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                }
                .foregroundStyle(.white)
                .padding(30)
                .frame(maxWidth: .infinity)
                .toolbar(.hidden, for: .tabBar)
                .background(Color.blue.opacity(0.9))
                .cornerRadius(30)
                .padding(20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Exit") {
                    dismiss()
                }
            }
        }
    }
}



// MARK: - 7. Preview
#Preview {
    PoseGameView()
}
