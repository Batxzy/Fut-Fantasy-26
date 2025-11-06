//
//  StickerEditorView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 06/11/25.
//


import SwiftUI
import SwiftData

struct StickerEditorView: View {
    // --- Environment ---
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(CollectibleManager.self) private var collectibleManager
    @Environment(EffectsPipeline.self) private var pipeline
    
    // --- Data ---
    @Query private var squads: [Squad]
    var squad: Squad? { squads.first }
    
    // --- Input ---
    let sourceImage: UIImage // The image from the PhotosPicker
    
    // --- State ---
    @State private var isSaving = false
    @State private var saveError: String?
    
    var body: some View {
        @Bindable var pipeline = pipeline

        VStack(spacing: 0) {
            // Image display area
            Group {
                if pipeline.isProcessing || isSaving {
                    ProgressView().frame(height: 350)
                } else if let outputImage = pipeline.outputImage {
                    Image(uiImage: outputImage).resizable().scaledToFit()
                } else {
                    // Show the source image while the first effect is processing
                    Image(uiImage: sourceImage).resizable().scaledToFit().opacity(0.5)
                }
            }
            .frame(maxWidth: .infinity, idealHeight: 350)
            .padding()

            // Controls for the current effect
            Form {
                Section("Effect Controls") {
                    effectControls(for: pipeline)
                }
                if let saveError {
                    Section {
                        Text("Error: \(saveError)").foregroundStyle(.red)
                    }
                }
            }
            
            // Horizontal list of available effects
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(EffectsPipeline.Effect.allCases) { effect in
                        Button(action: { Task { await pipeline.changeEffect(to: effect) } }) {
                            Text(effect.rawValue)
                                .padding(.horizontal, 16).padding(.vertical, 8)
                                .background(pipeline.currentEffect == effect ? Color.accentColor : Color.secondary.opacity(0.2))
                                .foregroundColor(pipeline.currentEffect == effect ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }.padding()
            }.background(.thinMaterial)
        }
        .navigationTitle("Create Sticker").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveSticker()
                }
                .disabled(pipeline.outputImage == nil || isSaving || squad == nil)
            }
        }
        .onAppear {
            // Load the source image into the pipeline
            pipeline.inputImage = sourceImage
            Task {
                await pipeline.processImage()
            }
        }
        .onDisappear {
            // Clear the pipeline when this view is dismissed
            pipeline.reset()
        }
    }
    
    private func saveSticker() {
        guard let imageToSave = pipeline.outputImage, let squad = squad else { return }
        
        isSaving = true
        saveError = nil
        
        Task {
            do {
                try collectibleManager.saveSticker(image: imageToSave, squad: squad)
                isSaving = false
                dismiss() // Go back to the gallery
            } catch {
                saveError = error.localizedDescription
                isSaving = false
                print("❌ Failed to save sticker: \(error)")
            }
        }
    }

    // --- All the Effect Control functions ---
    
    @ViewBuilder
    private func effectControls(for pipeline: EffectsPipeline) -> some View {
        @Bindable var pipeline = pipeline
        
        switch pipeline.currentEffect {
        case .JFA, .Countours:
            VStack {
                Text("Outline Thickness: \(Int(pipeline.outlineThickness))")
                Slider(value: $pipeline.outlineThickness, in: 1...100) { isEditing in
                    if !isEditing { Task { await pipeline.processImage() } }
                }
            }
            ColorPicker("Outline Color", selection: $pipeline.outlineColor)
                .onChange(of: pipeline.outlineColor) { Task { await pipeline.processImage() } }
        
        case .CircleBg:
            Toggle("Outline on Top", isOn: $pipeline.useThreeLayerEffect).onChange(of: pipeline.useThreeLayerEffect) { Task { await pipeline.processImage() } }
            VStack {
                Text("Circle Radius: \(String(format: "%.2f", pipeline.circleRadiusMultiplier))")
                Slider(value: $pipeline.circleRadiusMultiplier, in: 0.5...5.0) { isEditing in
                    if !isEditing { Task { await pipeline.processImage() } }
                }
            }
            shapeControls(for: pipeline)
            
        case .rectangleBg:
            Toggle("Outline on Top", isOn: $pipeline.useThreeLayerEffect).onChange(of: pipeline.useThreeLayerEffect) { Task { await pipeline.processImage() } }
            VStack {
                Text("Corner Radius: \(Int(pipeline.cornerRadius))")
                Slider(value: $pipeline.cornerRadius, in: 1...20) { isEditing in
                    if !isEditing { Task { await pipeline.processImage() } }
                }
            }
            shapeControls(for: pipeline)
            
        default:
            Text("No specific controls for this effect.").foregroundColor(.secondary)
        }
    }

    private func shapeControls(for pipeline: EffectsPipeline) -> some View {
        @Bindable var pipeline = pipeline
        return Group {
            VStack {
                Text("Outline Width: \(Int(pipeline.shapeOutlineWidth))")
                Slider(value: $pipeline.shapeOutlineWidth, in: 0...100) { isEditing in
                    if !isEditing { Task { await pipeline.processImage() } }
                }
            }
            ColorPicker("Background Color", selection: $pipeline.backgroundColor).onChange(of: pipeline.backgroundColor) { Task { await pipeline.processImage() } }
            ColorPicker("Outline Color", selection: $pipeline.outlineColor).onChange(of: pipeline.outlineColor) { Task { await pipeline.processImage() } }
        }
    }
}