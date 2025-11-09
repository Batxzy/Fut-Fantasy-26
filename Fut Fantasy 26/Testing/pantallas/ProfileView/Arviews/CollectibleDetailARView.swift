//
//  CollectibleDetailARView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 06/11/25.
//


import SwiftUI
import SwiftData

struct CollectibleDetailARView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(CollectibleManager.self) private var collectibleManager
    @State private var showPlanes: Bool = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            CollectibleDetailARContainer(showPlanes: $showPlanes)
                .ignoresSafeArea()
            
            // Top buttons overlay
            HStack {
                Button {
                    showPlanes.toggle()
                } label: {
                    Image(systemName: showPlanes ? "eye.fill" : "eye.slash.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .glassEffect(.regular.interactive())
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                }
                .glassEffect(.regular.interactive())
            }
            .padding(.horizontal,20)
            .padding(.leading,40)
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
    
    // Seed some collectibles
    try? manager.seedInitialBadges(for: squad)
    
    // Set a selected collectible for the detail view
    if let firstCollectible = try? context.fetch(FetchDescriptor<Collectible>()).first {
        manager.selectedCollectibleForDetail = firstCollectible
    }
    
    return CollectibleDetailARView()
        .modelContainer(container)
        .environment(manager)
}
