//
//  CollectibleDetailARView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 06/11/25.
//


import SwiftUI

struct CollectibleDetailARView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(CollectibleManager.self) private var collectibleManager
    @State private var showDebug = true
    
    var body: some View {
        ZStack {
            // This container will read from the Environment Manager
            CollectibleDetailARContainer()
                .ignoresSafeArea()
            
            VStack {
                HStack {
                    // Debug toggle
                    Button {
                        showDebug.toggle()
                    } label: {
                        Image(systemName: showDebug ? "eye.fill" : "eye.slash.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    
                    Spacer()
                    
                    // Dismiss button
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                }
                .padding()
                
                if showDebug {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🐛 Debug Info")
                            .font(.headline)
                        
                        if let collectible = collectibleManager.selectedCollectibleForDetail {
                            Text("Selected: \(collectible.name)")
                            if let img = collectible.uiImage {
                                Text("Size: \(Int(img.size.width))x\(Int(img.size.height))")
                            }
                        } else {
                            Text("No collectible selected")
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding()
                }
                
                Spacer()
            }
        }
    }
}