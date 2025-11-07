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

// MARK: - PlayingSubView

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

// MARK: - EndSubView

struct EndView: View {
    @Bindable var gameViewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    
    var isPerfect: Bool {
        gameViewModel.finalScore >= 0.8
    }
    
    var body: some View {
        ZStack {
            Color.mainBg.ignoresSafeArea()
            
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
            } else {
                Color.black.ignoresSafeArea()
            }

                


            WinCard(score: score)
        }
        .padding(24)
    }
}



#Preview {
    winContent(
        score: 0.85,
        FrameImage: Image(systemName: "person.fill")
    )
}

#Preview {
    @Previewable @State var mockViewModel = GameViewModel()
    
    EndView(gameViewModel: mockViewModel)
        .onAppear {
            mockViewModel.finalScore = 0.85
            mockViewModel.finalImage = Image(systemName: "person.fill")
        }
}
