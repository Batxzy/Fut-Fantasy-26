//
//  CollectibleDetailView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 06/11/25.
//

import SwiftUI
import SwiftData

struct CollectibleDetailView: View {
    let collectible: Collectible
    
    @Environment(CollectibleManager.self) private var collectibleManager
    @State private var showARMode = false
    
    // Gesture states for zoom (pinch) and rotation
    @GestureState private var gestureScale: CGFloat = 1.0
    @GestureState private var gestureRotation: Angle = .zero
    
    // Accumulated animated scale and rotation
    @State private var animScale: CGFloat = 1.0
    @State private var animRotation: Angle = .zero
    
    // Current scale and rotation
    private var currentScale: CGFloat {
        gestureScale * animScale
    }
    private var currentRotation: Angle {
        gestureRotation + animRotation
    }
    
    // Animation to return to normal
    private let spring = Animation.spring(.smooth)
    
    // Gestures
    private var pinch: some Gesture {
        MagnificationGesture()
            .updating($gestureScale) { value, state, _ in
                state = value
            }
            .onEnded { final in
                animScale = final
                // Smoothly return to normal scale
                withAnimation(spring) { animScale = 1.0 }
            }
    }
    
    private var rotate: some Gesture {
        RotationGesture()
            .updating($gestureRotation) { value, state, _ in
                state = value
            }
            .onEnded { final in
                animRotation = final
                // Smoothly return to normal rotation
                withAnimation(spring) { animRotation = .zero }
            }
    }

    var body: some View {
        ZStack {
            // Background
            TransparencyCheckerboard()
                .ignoresSafeArea()
            
            // Image
            if let image = collectible.displayImage {
                image
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(currentScale)
                    .rotationEffect(currentRotation)
                    .highPriorityGesture(
                        pinch.simultaneously(with: rotate),
                        including: .gesture
                    )
            } else {
                ContentUnavailableView("Image Not Found", systemImage: "photo.fill")
            }
            
            // Metadata Overlay
            VStack {
                Spacer()
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(collectible.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if let uiImage = collectible.uiImage {
                            Text("Width: \(Int(uiImage.size.width))px")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                            Text("Height: \(Int(uiImage.size.height))px")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        Text("Type: \(collectible.type.rawValue.capitalized)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("Created: \(collectible.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("Zoom: \(String(format: "%.2f", currentScale))x")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                    .background(.ultraThinMaterial.opacity(0.8))
                    .cornerRadius(12)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    if collectible.uiImage != nil {
                        Button {
                            collectibleManager.selectedCollectibleForDetail = collectible
                            showARMode = true
                        } label: {
                            Label("View in AR", systemImage: "arkit")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .fullScreenCover(isPresented: $showARMode) {
            CollectibleDetailARView()
        }
        .navigationTitle("Collectible Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Checkerboard Background

struct TransparencyCheckerboard: View {
    private let squareSize: CGFloat = 20
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let rows = Int(ceil(size.height / squareSize))
                let cols = Int(ceil(size.width / squareSize))
                
                for row in 0..<rows {
                    for col in 0..<cols {
                        let isEven = (row + col) % 2 == 0
                        let rect = CGRect(
                            x: CGFloat(col) * squareSize,
                            y: CGFloat(row) * squareSize,
                            width: squareSize,
                            height: squareSize
                        )
                        context.fill(
                            Path(rect),
                            with: .color(isEven ? Color(red: 0.15, green: 0.15, blue: 0.15) : .black)
                        )
                    }
                }
            }
        }
    }
}
