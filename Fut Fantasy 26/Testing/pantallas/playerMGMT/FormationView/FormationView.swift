//
//  FormationView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

import SwiftUI
import SwiftData

struct FormationView: View {
    let startingXI: [Player]
    let captain: Player?
    let viceCaptain: Player?
    let isEditMode: Bool
    
    @Binding var selectedSlot: PlayerSlot?
    let isPlayerTappable: (PlayerSlot) -> Bool
    let onPlayerTap: (PlayerSlot) -> Void
    
    // For navigation to detail view
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    
    var body: some View {
        ZStack {
            pitchBackground
                
                .rotation3DEffect(
                                .degrees(15),
                                axis: (x: 1.0, y: 0.0, z: 0.0),
                                anchor: .center,
                                perspective: 2
                            )
                .offset(y:-50)
                .scaleEffect(0.95)
            
            
            if startingXI.isEmpty {
                emptyPitchState
            } else {
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        
                        formationLine(
                            players: goalkeepers,
                            position: .goalkeeper,
                            geometry: geometry,
                            lineHeight: geometry.size.height * 0.16
                        )
                        
                        Spacer()
                        
                    
                        formationLine(
                            players: defenders,
                            position: .defender,
                            geometry: geometry,
                            lineHeight: geometry.size.height * 0.18
                        )
                        
                        Spacer()
                        

                        formationLine(
                            players: defensiveMidfielders,
                            position: .midfielder,
                            geometry: geometry,
                            lineHeight: geometry.size.height * 0.20
                        )
                        
                        Spacer()
                        
                        
                        formationLine(
                            players: forwards,
                            position: .forward,
                            geometry: geometry,
                            lineHeight: geometry.size.height * 0.20
                        )
                    }
                    .padding(.vertical, 15)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
        .aspectRatio(0.7, contentMode: .fit)
    }
    

    
    // MARK: - Formation Line
    
    @ViewBuilder
    private func formationLine(
        players: [Player],
        position: PlayerPosition,
        geometry: GeometryProxy,
        lineHeight: CGFloat
    ) -> some View {
        HStack(spacing: 0) {
            if players.isEmpty {
                Spacer()
                EmptyPlayerSlot(position: position )
                Spacer()
            } else {
                ForEach(players) { player in
                    Spacer()
                    playerCard(for: player)
                        .id(player.id)
                        .transition(.asymmetric(
                            insertion: .scale.animation(.spring(response: 0.4, dampingFraction: 0.6)),
                            removal: .scale.animation(.spring(response: 0.3, dampingFraction: 0.7))
                        ))
                    Spacer()
                }
            }
        }
        .frame(height: lineHeight)
    }
    
    // MARK: - Player Card Builder
    
    @ViewBuilder
    private func playerCard(for player: Player) -> some View {
        let slot = PlayerSlot.starting(player)
        let isSelected = selectedSlot == slot
        let tappable = isPlayerTappable(slot)
        
        ZStack {
            PitchPlayerCard(
                player: player,
                isCaptain: captain?.id == player.id,
                isViceCaptain: viceCaptain?.id == player.id,
                isEditMode: isEditMode,
                isSelected: isSelected,
                isTappable: tappable
            )
            
            if !isEditMode {
                NavigationLink(destination: PlayerDetailView(
                    player: player,
                    viewModel: PlayerViewModel(repository: playerRepository),
                    playerRepository: playerRepository,
                    squadRepository: squadRepository
                )) {
                    Color.clear
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditMode {
                onPlayerTap(slot)
            }
        }
    }
    
    
    // MARK: - Position Filters (4-2-3-1)
    
    private var goalkeepers: [Player] {
        let gks = startingXI.filter { $0.position == .goalkeeper }
        return Array(gks.prefix(1))
    }

    private var defenders: [Player] {
        let defs = startingXI.filter { $0.position == .defender }
        return Array(defs.prefix(4))
    }

    private var defensiveMidfielders: [Player] {
        let mids = startingXI.filter { $0.position == .midfielder }
        return Array(mids.prefix(3))
    }

    private var attackingMidfielders: [Player] {
        return []
    }

    private var forwards: [Player] {
        let fwds = startingXI.filter { $0.position == .forward }
        return Array(fwds.prefix(3)) // 3 FWD (was 1)
    }
}






//MARK: - Previews

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
    
    struct FormationPreview: View {
        @State private var selectedSlot: PlayerSlot?
        
        let startingXI = MockData.startingXI
        let mbappe = MockData.mbappe
        let deBruyne = MockData.deBruyne
        let playerRepo: PlayerRepository
        let squadRepo: SquadRepository
        
        var body: some View {
            NavigationStack {
                ZStack {
                    Color.gray.opacity(0.2).ignoresSafeArea()
                    
                    VStack {
                        FormationView(
                            startingXI: startingXI,
                            captain: mbappe,
                            viceCaptain: deBruyne,
                            isEditMode: true,
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
                        .padding()
                    }
                }
            }
        }
    }
    
    return FormationPreview(
        playerRepo: playerRepo,
        squadRepo: squadRepo
    )
    .modelContainer(container)
}

#Preview("Empty State") {
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
    
    let playerRepo = SwiftDataPlayerRepository(modelContext: context)
    let squadRepo = SwiftDataSquadRepository(modelContext: context, playerRepository: playerRepo)
    
    
    return NavigationStack {
        ZStack {
            Color.gray.opacity(0.2).ignoresSafeArea()
            
            VStack {
                FormationView(
                    startingXI: [],
                    captain: nil,
                    viceCaptain: nil,
                    isEditMode: false,
                    selectedSlot: .constant(nil),
                    isPlayerTappable: { slot in
                        return false
                    },
                    onPlayerTap: { tappedSlot in
                    },
                    playerRepository: playerRepo,
                    squadRepository: squadRepo
                )
                .padding()
            }
        }
    }
    .modelContainer(container)
}
