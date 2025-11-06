//
//  BadgeGalleryView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 06/11/25.
//

import SwiftUI
import SwiftData
import PhotosUI // <-- ADD THIS for Photo Picker

struct BadgeGalleryView: View {
    
    @Environment(CollectibleManager.self) private var collectibleManager
    @Query private var squads: [Squad]
    
    // 1. Fetch collectibles for the current squad
    @Query(sort: \Collectible.createdAt, order: .reverse) private var collectibles: [Collectible]
    
    // 2. Filter collectibles based on the selected tab
    @State private var selectedTab: CollectibleType = .sticker
    
    // 3. Columns for the grid
    private let columnCount = 3
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showStickerEditor = false
   
    private var columns: [[Collectible]] {
        let filteredCollectibles = collectibles.filter { $0.type == selectedTab }
        
        var cols: [[Collectible]] = Array(repeating: [], count: columnCount)
        
        for (index, collectible) in filteredCollectibles.enumerated() {
            let columnIndex = index % columnCount
            cols[columnIndex].append(collectible)
        }
        return cols
    }
    
    var body: some View {
        ZStack {
            Color(.mainBg)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // "STICKERS" / "BADGES" tabs
                HStack(spacing: 20) {
                    Button(action: { selectedTab = .sticker }) {
                        Text("STICKERS")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(selectedTab == .sticker ? .white : .white.opacity(0.4))
                    }
                    
                    Button(action: { selectedTab = .badge }) {
                        Text("BADGES")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(selectedTab == .badge ? .white : .white.opacity(0.4))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 16)
                
                
                ScrollView {
                    HStack(alignment: .top, spacing: 12) {
                        
                        // Loop to create each column
                        ForEach(columns.indices, id: \.self) { columnIndex in
                            LazyVStack(spacing: 12) {
                                ForEach(columns[columnIndex]) { collectible in
                                    if let image = collectible.displayImage {
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxWidth: .infinity)
                                            .clipped()
                                    } else {
                                        Rectangle()
                                            .fill(.gray.opacity(0.2))
                                            .aspectRatio(1, contentMode: .fit)
                                            .overlay(Text("Error").foregroundStyle(.red))
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Image(systemName: "plus")
                }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                    showStickerEditor = true
                }
            }
        }
        .navigationDestination(isPresented: $showStickerEditor) {
            if let selectedImage {
                StickerEditorView(sourceImage: selectedImage)
            }
        }
        .onAppear {
            if let squad = squads.first {
                do {
                    try collectibleManager.seedInitialBadges(for: squad)
                } catch {
                    print("❌ Failed to seed badges: \(error)")
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Squad.self, Collectible.self,
        configurations: config
    )
    let context = container.mainContext
    let manager = CollectibleManager(modelContext: context)
    let squad = Squad(teamName: "Preview Squad")
    context.insert(squad)
    
    try? manager.seedInitialBadges(for: squad)
    
    return NavigationStack {
        BadgeGalleryView()
    }
    .modelContainer(container)
    .environment(manager)
    .environment(EffectsPipeline())
}
