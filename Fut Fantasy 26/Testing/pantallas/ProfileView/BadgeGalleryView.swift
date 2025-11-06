//
//  BadgeGalleryView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 06/11/25.
//

import SwiftUI
import SwiftData

struct BadgeGalleryView: View {
    
    // --- New Layout Logic ---
    
    // 1. Define the number of columns
    private let columnCount = 3
    
    // 2. Your list of badge images, repeated for effect
    private let allBadgeImages = Array(
        repeating: ["Throphy", "LaCabra", "PinPoint", "VectorArtQuestion"],
        count: 5
    ).flatMap { $0 }
    
    // 3. Computed property to split images into 3 columns
    private var columns: [[String]] {
        var cols: [[String]] = Array(repeating: [], count: columnCount)
        
        // Distribute images one by one into each column
        for (index, imageName) in allBadgeImages.enumerated() {
            let columnIndex = index % columnCount
            cols[columnIndex].append(imageName)
        }
        return cols
    }
    
    // --- State for Tabs ---
    @State private var selectedTab = "STICKERS"
    private let tabs = ["STICKERS", "MY STUFF"]
    
    var body: some View {
        ZStack {
            Color(.mainBg)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // "STICKERS" / "MY STUFF" tabs
                HStack(spacing: 20) {
                    ForEach(tabs, id: \.self) { tab in
                        Button(action: { selectedTab = tab }) {
                            Text(tab)
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundStyle(selectedTab == tab ? .white : .white.opacity(0.4))
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 16) // Added padding since search bar is gone
                
                // 4. Main ScrollView for the entire layout
                ScrollView {
                    // 5. HStack holds the 3 vertical columns
                    HStack(alignment: .top, spacing: 12) {
                        
                        // 6. Loop to create each column
                        ForEach(columns.indices, id: \.self) { columnIndex in
                            // 7. LazyVStack creates a single column
                            LazyVStack(spacing: 12) {
                                // 8. Loop over the images for *this column only*
                                ForEach(columns[columnIndex], id: \.self) { imageName in
                                    Image(imageName)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit) // .fit allows varying heights
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        // Per your request, no .navigationTitle or .toolbar is added
    }
}

#Preview {
    NavigationStack {
        BadgeGalleryView()
    }
}
