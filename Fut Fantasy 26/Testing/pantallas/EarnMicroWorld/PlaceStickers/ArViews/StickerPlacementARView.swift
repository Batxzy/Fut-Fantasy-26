//
//  StickerPlacementARView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 06/11/25.
//


//
//  StickerPlacementARView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 06/11/25.
//

import SwiftUI
import SwiftData

struct StickerPlacementARView: View {
    @State private var selectedCollectible: Collectible?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            StickerARViewContainer(selectedCollectible: $selectedCollectible)
                .ignoresSafeArea()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
            }
            .padding()
        }
        .sheet(isPresented: .constant(true)) {
            StickerPickerSheet(selectedCollectible: $selectedCollectible)
                .presentationDetents([.fraction(0.2), .fraction(0.4), .large])
                .presentationBackgroundInteraction(.enabled)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
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
    
    return StickerPlacementARView()
        .modelContainer(container)
        .environment(manager)
}
