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
    
    // For navigation to detail view
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    
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
                        benchPlayerCard(for: player)
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
    
    // MARK: - Bench Player Card Builder
    
    @ViewBuilder
    private func benchPlayerCard(for player: Player) -> some View {
        let slot = PlayerSlot.bench(player)
        let isSelected = selectedSlot == slot
        let tappable = isPlayerTappable(slot)
        
        // **FIX**: Don't conditionally change view structure
        BenchPlayerCard(
            player: player,
            isSelected: isSelected,
            isTappable: isEditMode ? tappable : true // Always tappable in view mode
        )
        .contentShape(Rectangle()) // Make entire area tappable
        .onTapGesture {
            if isEditMode {
                // Edit mode: swap logic
                onPlayerTap(slot)
            }
        }
        .background(
            // Navigation only active in view mode
            NavigationLink(destination: PlayerDetailView(
                player: player,
                viewModel: PlayerViewModel(repository: playerRepository),
                playerRepository: playerRepository,
                squadRepository: squadRepository
            )) {
                EmptyView()
            }
            .opacity(0)
            .allowsHitTesting(!isEditMode) // Disable navigation in edit mode
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
            .overlay {
                Circle()
                    .stroke(isSelected ? Color.yellow : positionColor, lineWidth: isSelected ? 4 : 2)
                    .frame(width: 58, height: 58)
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
