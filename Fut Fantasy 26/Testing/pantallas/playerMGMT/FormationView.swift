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
    
    // MARK: - Background Components
    
    private var pitchBackground: some View {
        ZStack {
            
            hardStripes
            pitchLines
            cornerCircles
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        
    }
    
    private var pitchLines: some View {
        VStack(spacing: 0) {
            Rectangle()
                .stroke(.white.opacity(0.8), lineWidth: 2)
                .frame(height: 50)
                .padding(.horizontal, 60)
                .padding(.top, 10)
            
            Spacer()
            
            Circle()
                .stroke(.white.opacity(0.8), lineWidth: 2)
                .frame(width: 80, height: 80)
            
            Rectangle()
                .fill(.white.opacity(0.8))
                .frame(height: 2)
                .offset(y: -40)
            
            Spacer()
            
            Rectangle()
                .stroke(.white.opacity(0.8), lineWidth: 2)
                .frame(height: 50)
                .padding(.horizontal, 60)
                .padding(.bottom, 10)
        }
    }
    
    private var cornerCircles: some View {
        VStack {
            HStack {
                cornerArc
                Spacer()
                cornerArc.rotation3DEffect(.degrees(90), axis: (x: 0, y: 1, z: 0))
            }
            Spacer()
            HStack {
                cornerArc.rotation3DEffect(.degrees(-90), axis: (x: 1, y: 0, z: 0))
                Spacer()
                cornerArc.rotation3DEffect(.degrees(180), axis: (x: 1, y: 1, z: 0))
            }
        }
    }
    
    private var cornerArc: some View {
        Circle()
            .trim(from: 0, to: 0.25)
            .stroke(.white.opacity(0.8 ), lineWidth: 2)
            .frame(width: 30, height: 30)
    }
    
    private var emptyPitchState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sportscourt")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.3))
            
            Text("No Starting XI Selected")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
            
            Text("Add 11 players to your squad and set your starting lineup")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var hardStripes: some View {
        VStack(spacing: 0) {
            ForEach(0..<24) { i in
                Rectangle()
                    .fill(i % 2 == 0 ? Color.pitchGreenDark : Color.pitchGreen)
            }
        }
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
                EmptyPlayerSlot()
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
    // We don't need to seed data for an empty state
    // WorldCupDataSeeder.seedDataIfNeeded(context: context)
    
    let playerRepo = SwiftDataPlayerRepository(modelContext: context)
    let squadRepo = SwiftDataSquadRepository(modelContext: context, playerRepository: playerRepo)
    
    // We don't need the helper struct here, we can use .constant
    
    return NavigationStack {
        ZStack {
            Color.gray.opacity(0.2).ignoresSafeArea()
            
            VStack {
                FormationView(
                    startingXI: [],          // <-- Pass an empty array
                    captain: nil,            // <-- Pass nil
                    viceCaptain: nil,        // <-- Pass nil
                    isEditMode: false,
                    selectedSlot: .constant(nil), // <-- Use .constant for the binding
                    isPlayerTappable: { slot in
                        return false // Not tappable in empty state
                    },
                    onPlayerTap: { tappedSlot in
                        // No action
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
