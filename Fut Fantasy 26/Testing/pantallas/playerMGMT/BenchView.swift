//
//  BenchView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import SwiftData
import SwiftUI

struct BenchView: View {
    let benchPlayers: [Player]
    let isEditMode: Bool
    
    @Binding var selectedSlot: PlayerSlot?
    let isPlayerTappable: (PlayerSlot) -> Bool
    let onPlayerTap: (PlayerSlot) -> Void
    
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    
    @State private var selectedPlayerForDetail: Player?
    @State private var navigateToAddPlayer = false
    
    var body: some View {
        VStack(spacing: 12) {
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
            
            HStack(spacing: 8) {
                ForEach(benchPlayers) { player in
                    benchPlayerCard(for: player)
                        .id(player.id)
                        .transition(.asymmetric(
                            insertion: .scale.animation(.spring(response: 0.4, dampingFraction: 0.6)),
                            removal: .scale.animation(.spring(response: 0.3, dampingFraction: 0.7))
                        ))
                }
                
                ForEach(0..<(4 - benchPlayers.count), id: \.self) { _ in
                    EmptyBenchSlot()
                        .onTapGesture {
                            navigateToAddPlayer = true
                        }
                }
            }
        }
        .padding(22)
        .navigationDestination(item: $selectedPlayerForDetail) { player in
            PlayerDetailView(
                player: player,
                viewModel: PlayerViewModel(repository: playerRepository),
                playerRepository: playerRepository,
                squadRepository: squadRepository
            )
        }
        .navigationDestination(isPresented: $navigateToAddPlayer) {
            PlayersView(
                viewModel: PlayerViewModel(repository: playerRepository),
                playerRepository: playerRepository,
                squadRepository: squadRepository
            )
        }
    }
    
    private func benchPlayerCard(for player: Player) -> some View {
        let slot = PlayerSlot.bench(player)
        let isSelected = selectedSlot == slot
        let tappable = isPlayerTappable(slot)
        
        return BenchPlayerCard(
            player: player,
            isSelected: isSelected,
            isTappable: tappable
        )
        .onTapGesture {
            if isEditMode {
                onPlayerTap(slot)
            } else {
                selectedPlayerForDetail = player
            }
        }
    }
}

// MARK: - Las tarjetas en si
struct BenchPlayerCard: View {
    let player: Player
    let isSelected: Bool
    let isTappable: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: 65, height: 65)
                
                AsyncImage(url: URL(string: player.nationFlagURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 32, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 4)
                    .frame(width: 65, height: 65)
            )
            
            playerName
            
        }
        .opacity(isTappable ? 1.0 : 0.4)
        .grayscale(isTappable ? 0 : 0.8)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: [isSelected,isTappable])
        .padding(.vertical,8)
        .padding(.horizontal,4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial))
    }
    
    private var playerName: some View {
        Text(formattedPlayerName)
            .font(.system(size: 10, weight: .bold))
            .lineLimit(1)
            .minimumScaleFactor(0.95)
            .frame(width: 65)
            .frame(maxHeight: 15)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
            )
    }
    
    private var formattedPlayerName: String {
        if player.lastName.isEmpty {
            return player.name
        }
        
        let firstInitial = player.firstName.prefix(1).uppercased()
        return "\(firstInitial). \(player.lastName)"
    }
}

struct EmptyBenchSlot: View {
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.grayBg)
                    .frame(width: 65, height: 65)
                
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.5))
            }
            
            Text("Empty")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.black.opacity(0.6))
                .frame(width: 65,height: 15)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.grayBg)
                )
        }
        .padding(.vertical,8)
        .padding(.horizontal,4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial))
    }
}

// MARK: - Previews

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container: ModelContainer
    
    do {
        container = try ModelContainer(
            for: Player.self, Squad.self,
            configurations: config
        )
    } catch {
        fatalError("Failed to create preview container")
    }
    
    let context = container.mainContext
    WorldCupDataSeeder.seedDataIfNeeded(context: context)
    
    let playerRepo = SwiftDataPlayerRepository(modelContext: context)
    let squadRepo = SwiftDataSquadRepository(modelContext: context, playerRepository: playerRepo)
    
    struct BenchPreview: View {
        @State private var selectedSlot: PlayerSlot?
        
        let benchPlayers = [MockData.mbappe, MockData.deBruyne]
        let playerRepo: PlayerRepository
        let squadRepo: SquadRepository
        
        var body: some View {
            NavigationStack {
                BenchView(
                    benchPlayers: benchPlayers,
                    isEditMode: false,
                    selectedSlot: $selectedSlot,
                    isPlayerTappable: { slot in
                        return true
                    },
                    onPlayerTap: { tappedSlot in
                        if selectedSlot == tappedSlot {
                            selectedSlot = nil
                        } else {
                            selectedSlot = tappedSlot
                        }
                    },
                    playerRepository: playerRepo,
                    squadRepository: squadRepo
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }
    
    return BenchPreview(
        playerRepo: playerRepo,
        squadRepo: squadRepo
    )
    .modelContainer(container)
}

#Preview("Bench Player Card - Selected") {
    let samplePlayer = Player(
        id: 10,
        name: "Messi",
        firstName: "Lionel",
        lastName: "Messi",
        position: .forward,
        nation: .argentina,
        shirtNumber: 10,
        price: 10.5
    )
    
    return BenchPlayerCard(
        player: samplePlayer,
        isSelected: true,
        isTappable: true
    )
    .padding(50)
    .background(Color.gray.opacity(0.2))
}

#Preview("Bench Player Card - Unselected") {
    let samplePlayer = Player(
        id: 7,
        name: "Mbappé",
        firstName: "Kylian",
        lastName: "Mbappé",
        position: .forward,
        nation: .france,
        shirtNumber: 7,
        price: 11.0
    )
    
    return BenchPlayerCard(
        player: samplePlayer,
        isSelected: false,
        isTappable: true
    )
    .padding(50)
    .background(Color.gray.opacity(0.2))
}

#Preview("Bench Player Card - Not Tappable") {
    let samplePlayer = Player(
        id: 17,
        name: "De Bruyne",
        firstName: "Kevin",
        lastName: "De Bruyne",
        position: .midfielder,
        nation: .belgium,
        shirtNumber: 17,
        price: 10.0
    )
    
    return BenchPlayerCard(
        player: samplePlayer,
        isSelected: false,
        isTappable: false
    )
    .padding(50)
    .background(Color.gray.opacity(0.2))
}

#Preview("Empty Bench Slot") {
    EmptyBenchSlot()
        .padding(50)
        .background(Color.gray.opacity(0.2))
}

