//
//  StickerPickerSheet.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 06/11/25.
//


import SwiftUI
import SwiftData

struct StickerPickerSheet: View {
    
    @Binding var selectedCollectible: Collectible?
    
    @Query(sort: \Collectible.createdAt, order: .reverse) private var collectibles: [Collectible]
    
    @State private var selectedTab: CollectibleType = .badge
    private let columnCount = 2
    
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
                
                // Main ScrollView
                ScrollView {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(columns.indices, id: \.self) { columnIndex in
                            LazyVStack(spacing: 12) {
                                ForEach(columns[columnIndex]) { collectible in
                                    
                                    Button(action: {
                                        if selectedCollectible?.id == collectible.id {
                                            selectedCollectible = nil
                                        } else {
                                            selectedCollectible = collectible
                                        }
                                    }) {
                                        let isSelected = selectedCollectible?.id == collectible.id
                                        
                                        if let image = collectible.displayImage {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(maxWidth: .infinity)
                                                .clipped()
                                                .brightness(isSelected ? 0.1 : 0)
                                                .saturation(isSelected ? 1.3 : 1.0)
                                                .contrast(isSelected ? 1.1 : 1.0)
                                                .scaleEffect(isSelected ? 1.0 : 0.95)
                                                .animation(.spring(response: 0.7, dampingFraction: 0.7), value: isSelected)
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
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
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
    
    struct PreviewWrapper: View {
        @State var collectible: Collectible?
        var body: some View {
            StickerPickerSheet(selectedCollectible: $collectible)
        }
    }
    
    return PreviewWrapper()
        .modelContainer(container)
        .environment(manager)
}
