//
//  BadgeGalleryView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 06/11/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct BadgeGalleryView: View {
    
    @Environment(CollectibleManager.self) private var collectibleManager
    @Query private var squads: [Squad]
    
    @Query(sort: \Collectible.createdAt, order: .reverse) private var collectibles: [Collectible]
    
    @State private var selectedTab: CollectibleType = .badge
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
                HStack(spacing: 15) {
                    
                    Button(action: { selectedTab = .badge }) {
                        Text("Badges")
                            .fontWidth(.condensed)
                            .font(.system(size: 24))
                            .fontDesign(.default)
                            .fontWeight(.medium)
                            .kerning(1.2)
                            .foregroundStyle(selectedTab == .badge ? .wpMint : .white.opacity(0.4))
                    }
                    
                    Rectangle()
                        .frame(width: 2,height: 20)
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Button(action: { selectedTab = .sticker }) {
                        Text("Stickers")
                            .fontWidth(.condensed)
                            .font(.system(size: 24))
                            .fontDesign(.default)
                            .fontWeight(.medium)
                            .kerning(1.2)
                            .foregroundStyle(selectedTab == .sticker ? .wpMint : .white.opacity(0.4))
                        
                    }
                    
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 19)
                .padding(.bottom, 19)
                
                // Main ScrollView for the entire layout
                ScrollView {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(columns.indices, id: \.self) { columnIndex in
                            LazyVStack(spacing: 12) {
                                ForEach(columns[columnIndex]) { collectible in
                                    
                                    // Wrap the image in a NavigationLink
                                    NavigationLink(destination: CollectibleDetailView(collectible: collectible)) {
                                        if let image = collectible.displayImage {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(maxWidth: .infinity)
                                                .background(.white.opacity(0.1))
                                                .cornerRadius(8)
                                                .clipped()
                                        } else {
                                            // Placeholder for missing image
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
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Gallery")
       
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if selectedTab == .sticker {
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Image(systemName: "plus")
                    }
                    .transition(.blurReplace(.downUp).combined(with: .opacity))
                }
            }
        }
        .animation(.spring(duration: 0.2), value: selectedTab)
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
        .toolbar(.hidden, for: .tabBar)
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
