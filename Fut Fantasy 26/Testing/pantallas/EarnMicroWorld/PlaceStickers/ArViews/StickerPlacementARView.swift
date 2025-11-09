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
    @State private var sheetHeight: CGFloat = 0
    @State private var animationDuration: Double = 0.3
    @Environment(\.dismiss) var dismiss
    @State private var showPlanes: Bool = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            StickerARViewContainer(
                            selectedCollectible: $selectedCollectible,
                            showPlanes: $showPlanes
                        )
            
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
        .overlay(alignment: .bottomTrailing) {
            Button {
                showPlanes.toggle()

            } label: {
                    Image(systemName: showPlanes ? "eye.fill" : "eye.slash.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.black)
                        .padding(12)
                        .background(
                            Circle()
                                .fill(Color.wpMint)
                                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                        )
            }
            .padding(.vertical,24)
            .padding(.horizontal,16)
            .offset(y: -sheetHeight)
            .animation(.interpolatingSpring(duration: animationDuration, bounce: 0, initialVelocity: 0), value: sheetHeight)
        }
        .sheet(isPresented: .constant(true)) {
            StickerPickerSheet(selectedCollectible: $selectedCollectible)
                .presentationDetents([.fraction(0.2), .fraction(0.4), .large])
                .presentationBackgroundInteraction(.enabled)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
                .onGeometryChange(for: CGFloat.self) { proxy in
                    max(min(proxy.size.height, 350), 0)
                } action: { oldValue, newValue in
                    sheetHeight = newValue
                    
                    let diff = abs(newValue - oldValue)
                    let duration = max(min(diff / 100, 0.3), 0)
                    animationDuration = duration
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
    
    return StickerPlacementARView()
        .modelContainer(container)
        .environment(manager)
}
