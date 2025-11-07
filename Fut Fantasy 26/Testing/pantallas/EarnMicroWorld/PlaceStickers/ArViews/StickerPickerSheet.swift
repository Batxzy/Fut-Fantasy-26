//
//  StickerPickerSheet.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 06/11/25.
//


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
    
    @State private var selectedTab: CollectibleType = .sticker
    private let columnCount = 3
    
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
                
                // Main ScrollView for the entire layout
                ScrollView {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(columns.indices, id: \.self) { columnIndex in
                            LazyVStack(spacing: 12) {
                                ForEach(columns[columnIndex]) { collectible in
                                    
                                    Button(action: {
                                        selectedCollectible = collectible
                                    }) {
                                        let isSelected = selectedCollectible?.id == collectible.id
                                        
                                        if let image = collectible.displayImage {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(maxWidth: .infinity)
                                                .background(.white.opacity(0.1))
                                                .cornerRadius(8)
                                                .clipped()
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 4)
                                                )
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
