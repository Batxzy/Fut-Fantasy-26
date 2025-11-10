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
import CoreData
import SwiftData

struct PoseGameView: View {
    @State private var gameViewModel = GameViewModel()
        @State private var questionViewModel: QuestionViewModel?
        let sharedQuestionViewModel: QuestionViewModel?
       @Query private var squads: [Squad]
       @Environment(\.modelContext) private var modelContext
       @Namespace private var gameNamespace
       
        
        private var currentSquad: Squad? {
            squads.first
        }
    
    
       var body: some View {
           ZStack {
               Color.mainBg.ignoresSafeArea()
               
               if let qvm = questionViewModel {
                   switch gameViewModel.gameState {
                   case .start:
                       StartView(gameViewModel: gameViewModel, questionViewModel: qvm, namespace: gameNamespace)
                       
                   case .playing:
                       PlayingView(gameViewModel: gameViewModel, namespace: gameNamespace)
                           .transition(.push(from: .bottom).combined(with: .scale))
                           
                   case .end:
                       EndView(gameViewModel: gameViewModel, namespace: gameNamespace)
                           .transition(.scale.combined(with: .opacity))
                   }
               }
           }
           .statusBar(hidden: true)
           .toolbarVisibility(.hidden, for: .tabBar)
           .onAppear {
               if let squad = currentSquad {
                   let rewardManager = RewardManager(modelContext: modelContext)
                   gameViewModel.configureEconomy(squad: squad, rewardManager: rewardManager)
                   
                   // Use shared instance if provided, otherwise create new one
                   if questionViewModel == nil {
                       questionViewModel = sharedQuestionViewModel ?? QuestionViewModel.create(modelContext: modelContext, squadId: squad.id)
                   }
               }
           }
       }
   }
// MARK: - StartSubView

import SwiftUI

struct StartView: View {
    @Bindable var gameViewModel: GameViewModel
    @Bindable var questionViewModel: QuestionViewModel
    var namespace: Namespace.ID
    @State private var showQuestionView = false
    
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
            
            Button(action: {
                Task {
                    await questionViewModel.loadRandomQuestion()
                    showQuestionView = true
                }
            }) {
                
                    Text("Try Random Question")

                
                .font(.title2)
                .fontWeight(.medium)
                .foregroundStyle(.wpGreenYellow)
                .padding(.vertical, 8)
                .padding(.horizontal,40)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(.wpGreenYellow, lineWidth: 2)
                )
            }
        }
        .navigationDestination(isPresented: $showQuestionView) {
            QuestionDetailview(viewModel: questionViewModel)
        }
    }
}

// MARK: - Prediction Confidence View

struct PredictionConfidenceView: View {
    let messiConfidence: Double
    let noPoseConfidence: Double
    
    private var displayConfidence: Double {
        messiConfidence
    }
    
    private var confidenceColor: Color {
        switch displayConfidence {
        case 0.8...:
            return .green
        case 0.5..<0.8:
            return .yellow
        default:
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Confidence percentage
            Text(String(format: "%.0f%%", displayConfidence * 100))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(confidenceColor)
                .shadow(color: confidenceColor.opacity(0.5), radius: 10)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(height: 4)
                    
                    // Progress
                    Capsule()
                        .fill(confidenceColor)
                        .frame(width: geometry.size.width * displayConfidence, height: 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: displayConfidence)
                }
            }
            .frame(height: 8)
        }
        .frame(width: 200)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.mainBg)
        )
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
                CameraPreviewView(session: gameViewModel.cameraViewModel.session)
                    .ignoresSafeArea()
                    .blur(radius: isImageFocused ? 10 : 0)
                
                PoseOverlayView(
                    bodyParts: gameViewModel.poseViewModel.detectedBodyParts,
                    connections: gameViewModel.poseViewModel.bodyConnections
                )
                .blur(radius: isImageFocused ? 10 : 0)
                
                if isImageFocused {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
                
                VStack {
                    if !isImageFocused {
                        PredictionConfidenceView(
                            messiConfidence: gameViewModel.poseViewModel.messiConfidence,
                            noPoseConfidence: gameViewModel.poseViewModel.noPoseConfidence
                        )
                        .padding(.top, 60)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
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

// MARK: - WinContent
struct WinContent: View {
    let score: Double
    let FrameUIImage: UIImage?
    let referencePoseImageName: String
    var namespace: Namespace.ID
    let onClaim: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            if let uiImage = FrameUIImage {
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
                        .matchedGeometryEffect(id: "refImage", in: namespace)
                }
            } else {
                Color.black
                    .frame(width: 298, height: 400)
                    .cornerRadius(20)
            }
            
            WinCard(score: score, onDismiss: onClaim)
        }
        .padding(24)
    }
}


// MARK: - Content Layer End
private struct ContentLayer: View {
    let isPerfect: Bool
    let score: Double
    let restartAction: () async -> Void
    let FrameUIImage: UIImage?
    let referencePoseImageName: String
    var namespace: Namespace.ID
    let onClaim: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            if isPerfect {
                WinContent(
                    score: score,
                    FrameUIImage: FrameUIImage,
                    referencePoseImageName: referencePoseImageName,
                    namespace: namespace,
                    onClaim: onClaim
                )
            } else {
                AlmostCard(score: score, restartAction: restartAction)
            }
            
            Spacer()
        }
    }
}

// MARK: - EndSubView
struct EndView: View {
    @Bindable var gameViewModel: GameViewModel
    @Environment(\.dismiss) private var dismiss
    var namespace: Namespace.ID
    
    @Environment(\.displayScale) private var displayScale

    @State private var showShareSheet = false
    @State private var showExportProgress = false
    
    @State private var scoreToDisplay: Double = 0.0
    @State private var uiImageToDisplay: UIImage? = nil
    @State private var referenceImageToDisplay: String = ""
    
    var isPerfect: Bool {
        scoreToDisplay >= 0.8
    }
    
    var body: some View {
        ZStack {
            Color.mainBg.ignoresSafeArea()
            
            ContentLayer(
                isPerfect: isPerfect,
                score: scoreToDisplay,
                restartAction: gameViewModel.restartGame,
                FrameUIImage: uiImageToDisplay,
                referencePoseImageName: referenceImageToDisplay,
                namespace: namespace,
                onClaim: { 
                    gameViewModel.resetToStart()
                    dismiss()
                }
            )
            
            if showExportProgress {
                ExportProgressView(
                    isShowing: $showExportProgress,
                    progress: gameViewModel.exportProgress,
                    isComplete: gameViewModel.isExportComplete
                )
                .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
                    if isPerfect {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                Task {
                                    showExportProgress = true
                                    await gameViewModel.prepareShareImage(scale: displayScale)
                                    showExportProgress = false
                                    showShareSheet = true
                                }
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
        .sheet(isPresented: $showShareSheet) {
            if let imageURL = gameViewModel.shareImageURL {
                ActivityViewController(imageURL: imageURL)
            }
        }
        .onAppear {
            self.scoreToDisplay = gameViewModel.finalScore
            self.uiImageToDisplay = gameViewModel.finalUIImage
            self.referenceImageToDisplay = gameViewModel.referencePoseImageName
        }
    }
}

// MARK: - Activity View Controller (Share Sheet)
struct ActivityViewController: UIViewControllerRepresentable {
    var imageURL: URL
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [imageURL], applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Export Progress View
struct ExportProgressView: View {
    @Binding var isShowing: Bool
    var progress: Double
    var isComplete: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    Text("Ready!")
                        .font(.title2).bold()
                        .foregroundStyle(.white)
                } else {
                    ProgressView(value: progress)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                    Text("Preparing Image...")
                        .font(.title2).bold()
                        .foregroundStyle(.white)
                        .padding(.top, 20)
                }
            }
            .padding(40)
            .background(Color.black.opacity(0.8))
            .cornerRadius(20)
        }
    }
}

/*
#Preview("PoseGameView") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Squad.self, configurations: config)
    
    PoseGameView()
        .modelContainer(container)
}

*/
#Preview("StartView") {
    @Previewable @Namespace var namespace
    @Previewable @State var mockGameViewModel = GameViewModel()
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Squad.self, Question.self, configurations: config)
    let mockQuestionViewModel = QuestionViewModel.create(
        modelContext: container.mainContext,
        squadId: UUID()
    )
    
    StartView(
        gameViewModel: mockGameViewModel,
        questionViewModel: mockQuestionViewModel,
        namespace: namespace
    )
    .modelContainer(container)
}

#Preview("PredictionConfidenceView - High") {
    PredictionConfidenceView(
        messiConfidence: 0.92,
        noPoseConfidence: 0.08
    )
    .padding()
    .background(Color.black)
}

#Preview("PredictionConfidenceView - Medium") {
    PredictionConfidenceView(
        messiConfidence: 0.65,
        noPoseConfidence: 0.35
    )
    .padding()
    .background(Color.black)
}

#Preview("PredictionConfidenceView - Low") {
    PredictionConfidenceView(
        messiConfidence: 0.25,
        noPoseConfidence: 0.75
    )
    .padding()
    .background(Color.black)
}

#Preview("WinContent") {
    @Previewable @Namespace var namespace
    
    WinContent(
        score: 0.85,
        FrameUIImage: nil,
        referencePoseImageName: "defaultPose",
        namespace: namespace,
        onClaim: {}
    )
}

#Preview("EndView - Perfect Score") {
    @Previewable @Namespace var namespace
    @Previewable @State var mockViewModel = GameViewModel()
    
    EndView(gameViewModel: mockViewModel, namespace: namespace)
        .onAppear {
            mockViewModel.finalScore = 0.85
            mockViewModel.finalUIImage = nil
        }
}

#Preview("EndView - Almost") {
    @Previewable @Namespace var namespace
    @Previewable @State var mockViewModel = GameViewModel()
    
    EndView(gameViewModel: mockViewModel, namespace: namespace)
        .onAppear {
            mockViewModel.finalScore = 0.65
            mockViewModel.finalUIImage = nil
        }
}

#Preview("ExportProgressView - Loading") {
    @Previewable @State var isShowing = true
    
    ExportProgressView(
        isShowing: $isShowing,
        progress: 0.6,
        isComplete: false
    )
}

#Preview("ExportProgressView - Complete") {
    @Previewable @State var isShowing = true
    
    ExportProgressView(
        isShowing: $isShowing,
        progress: 1.0,
        isComplete: true
    )
}
