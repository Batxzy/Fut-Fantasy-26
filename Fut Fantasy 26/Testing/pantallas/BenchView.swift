//
//  BenchView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import SwiftUI

struct BenchView: View {
    let benchPlayers: [Player]
    let isEditMode: Bool
    
    @Binding var selectedSlot: PlayerSlot?
    let isPlayerTappable: (PlayerSlot) -> Bool
    let onPlayerTap: (PlayerSlot) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.secondary)
                Text("Bench")
                    .font(.headline)
                
                Spacer()
                
                Text("\(benchPlayers.count)/4")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if benchPlayers.isEmpty {
                ContentUnavailableView(
                    "No Bench Players",
                    systemImage: "person.crop.circle.badge.xmark",
                    description: Text("Add players to your bench")
                )
                .frame(height: 120)
            } else {
                HStack(spacing: 12) {
                    ForEach(benchPlayers) { player in
                        let slot = PlayerSlot.bench(player)
                        let isSelected = selectedSlot == slot
                        let tappable = isPlayerTappable(slot)
                        
                        BenchPlayerCard(
                            player: player,
                            isSelected: isSelected,
                            isTappable: isEditMode && tappable
                        )
                        .onTapGesture {
                            onPlayerTap(slot)
                        }
                        // Add ID and transition for animations
                        .id(player.id)
                        .transition(.asymmetric(
                            insertion: .scale.animation(.spring(response: 0.4, dampingFraction: 0.6)),
                            removal: .scale.animation(.spring(response: 0.3, dampingFraction: 0.7))
                        ))
                    }
                    
                    // Empty slots
                    ForEach(0..<(4 - benchPlayers.count), id: \.self) { _ in
                        EmptyBenchSlot()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
    }
}

struct BenchPlayerCard: View {
    let player: Player
    let isSelected: Bool
    let isTappable: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                AsyncImage(url: URL(string: player.imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(.quaternary)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            }
            // **FIX:** Move the outline outside the image ZStack
            .overlay {
                Circle()
                    .stroke(isSelected ? Color.yellow : positionColor, lineWidth: isSelected ? 4 : 2)
                    .frame(width: 58, height: 58) // Slightly larger than the circle
            }
            
            Text(player.name)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 60)
            
            Text("\(player.totalPoints)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
        .opacity(isTappable ? 1.0 : 0.4)
        .grayscale(isTappable ? 0 : 0.8)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isTappable)
    }
    
    private var positionColor: Color {
        switch player.position {
        case .goalkeeper: return .yellow
        case .defender: return .blue
        case .midfielder: return .green
        case .forward: return .red
        }
    }
}

struct EmptyBenchSlot: View {
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundStyle(.quaternary)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "plus")
                        .foregroundStyle(.secondary)
                }
            
            Text("Empty")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 60)
        }
        .padding(8)
    }
}
