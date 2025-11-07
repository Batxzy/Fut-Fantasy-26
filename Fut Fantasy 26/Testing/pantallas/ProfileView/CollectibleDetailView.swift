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
        
        @State private var scale: CGFloat = 1.0
        @State private var lastScaleValue: CGFloat = 1.0

    var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / self.lastScaleValue
                self.lastScaleValue = value
                self.scale *= delta
            }
            .onEnded { _ in
                self.lastScaleValue = 1.0
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
                    .scaleEffect(scale)
                    .gesture(magnification)
                    .debugOutline()
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
                            .foregroundColor(.black)
                        
                        // --- ADDED DIMENSIONS HERE ---
                        if let uiImage = collectible.uiImage {
                            Text("Width: \(Int(uiImage.size.width))px")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.black)
                            Text("Height: \(Int(uiImage.size.height))px")
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.black)
                        }
                        // --- END OF ADDED DIMENSIONS ---
                        
                        Text("Type: \(collectible.type.rawValue.capitalized)")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.black)
                        
                        Text("Created: \(collectible.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.black)
                        
                        Text("Zoom: \(String(format: "%.2f", scale))x")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.black.opacity(0.7))
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
                            // Only show "View in AR" if it's an image we can place
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
                            with: .color(isEven ? Color(red: 0.9, green: 0.9, blue: 0.9) : .white)
                        )
                    }
                }
            }
        }
    }
}
