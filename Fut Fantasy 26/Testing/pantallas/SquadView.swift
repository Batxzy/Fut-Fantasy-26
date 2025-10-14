//
//  SquadView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

import SwiftUI
import SwiftData

enum PlayerSlot: Equatable, Hashable {
    case starting(Player)
    case bench(Player)
}

struct SquadView: View {
    // ✅ @Query automatically fetches and observes squad
    @Query private var squads: [Squad]
    
    // ✅ ViewModel only for write operations
    @Bindable var viewModel: SquadViewModel
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    
    @State private var isEditMode = false
    @State private var showingCaptainSelection = false
    
    // State for the new tap-to-swap functionality
    @State private var selectedSlot: PlayerSlot?
    
    // User only has one squad
    var squad: Squad? {
        squads.first
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if let squad = squad {
                    squadContent(squad: squad)
                } else {
                    ContentUnavailableView(
                        "No Squad",
                        systemImage: "sportscourt",
                        description: Text("Create your squad to get started")
                    )
                }
            }
            .navigationTitle("My Squad")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // Edit button with animated pen icon
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                isEditMode.toggle()
                                if !isEditMode {
                                    selectedSlot = nil
                                }
                            }
                        } label: {
                            Image(systemName: isEditMode ? "pencil.circle.fill" : "pencil.circle")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(isEditMode ? .green : .primary)
                                .font(.title3)
                                .symbolEffect(.bounce, value: isEditMode)
                        }
                        .disabled((squad?.startingXI?.isEmpty) ?? true)
                        
                        // Transfers button
                        NavigationLink {
                            TransfersView(
                                playerRepository: playerRepository,
                                squadRepository: squadRepository,
                                viewModel: viewModel
                            )
                        } label: {
                            Image(systemName: "arrow.left.arrow.right.circle")
                                .symbolRenderingMode(.hierarchical)
                                .font(.title3)
                        }
                    }
                }
            }
            .toolbarBackground(.automatic, for: .navigationBar)
            .sheet(isPresented: $showingCaptainSelection) {
                if let squad = squad {
                    CaptainSelectionView(
                        squad: squad,
                        onCaptainSelected: { player in
                            Task {
                                await viewModel.setCaptain(player, squadId: squad.id)
                            }
                        },
                        onViceCaptainSelected: { player in
                            Task {
                                await viewModel.setViceCaptain(player, squadId: squad.id)
                            }
                        }
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func squadContent(squad: Squad) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                squadHeader(squad: squad)
                
                FormationView(
                    startingXI: squad.startingXI ?? [],
                    captain: squad.captain,
                    viceCaptain: squad.viceCaptain,
                    isEditMode: isEditMode,
                    selectedSlot: $selectedSlot,
                    isPlayerTappable: isPlayerTappable,
                    onPlayerTap: handlePlayerTap,
                    playerRepository: playerRepository,
                    squadRepository: squadRepository
                )
                .padding(.horizontal)
                
                
                BenchView(
                    benchPlayers: squad.bench ?? [],
                    isEditMode: isEditMode,
                    selectedSlot: $selectedSlot,
                    isPlayerTappable: isPlayerTappable,
                    onPlayerTap: handlePlayerTap,
                    playerRepository: playerRepository,
                    squadRepository: squadRepository
                )
                .padding()
                
                Button("Set Captain & Vice-Captain") {
                    showingCaptainSelection = true
                }
                .buttonStyle(.bordered)
                .padding()
            }
            .padding(.vertical)
        }
        .scrollContentBackground(.hidden)
        // **MARBLE STYLE**: Single bouncy animation for the whole array
        .animation(.bouncy(duration: 0.75), value: squad.startingXI?.map { $0.id })
        .animation(.bouncy(duration: 0.75), value: squad.bench?.map { $0.id })
    }
    
    @ViewBuilder
    private func squadHeader(squad: Squad) -> some View {
        VStack(spacing: 12) {
            Text(squad.teamName)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 32) {
                VStack {
                    Text("Budget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(squad.displayBudget)
                        .font(.headline)
                }
                
                VStack {
                    Text("Team Value")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(squad.displayTotalValue)
                        .font(.headline)
                }
                
                VStack {
                    Text("Players")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(squad.players?.count ?? 0)/15")
                        .font(.headline)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Tap and Swap Logic
    
    private func handlePlayerTap(on tappedSlot: PlayerSlot) {
        guard isEditMode else { return }

        if !isPlayerTappable(slot: tappedSlot) {
            return
        }

        if selectedSlot == tappedSlot {
            selectedSlot = nil
            return
        }

        guard let firstSlot = selectedSlot else {
            selectedSlot = tappedSlot
            return
        }
        
        let secondSlot = tappedSlot
        
        Task {
            guard let squadId = squad?.id else { return }
            await viewModel.swapPlayers(firstSlot, secondSlot, squadId: squadId)
            selectedSlot = nil
        }
    }
    
    private func isPlayerTappable(slot: PlayerSlot) -> Bool {
        guard let selected = selectedSlot else {
            return true
        }
        
        if selected == slot {
            return true
        }

        let selectedPlayer: Player
        switch selected {
        case .starting(let p): selectedPlayer = p
        case .bench(let p): selectedPlayer = p
        }

        let targetPlayer: Player
        switch slot {
        case .starting(let p): targetPlayer = p
        case .bench(let p): targetPlayer = p
        }

        switch (selected, slot) {
        case (.starting, .starting):
            return selectedPlayer.position == targetPlayer.position
        
        case (.starting, .bench), (.bench, .starting):
            return selectedPlayer.position == targetPlayer.position
            
        case (.bench, .bench):
            return false
        }
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
    
    // ✅ CREATE SAMPLE SQUAD WITH PLAYERS
    let squad = Squad(teamName: "Batxzy's Dream Team", ownerName: "Batxzy")
    context.insert(squad)
    
    // Fetch some players from the seeded data
    let fetchDescriptor = FetchDescriptor<Player>(
        sortBy: [SortDescriptor(\.totalPoints, order: .reverse)]
    )
    
    if let allPlayers = try? context.fetch(fetchDescriptor) {
        // Get players for 4-2-3-1 formation
        let goalkeepers = allPlayers.filter { $0.position == .goalkeeper }.prefix(2)
        let defenders = allPlayers.filter { $0.position == .defender }.prefix(5)
        let midfielders = allPlayers.filter { $0.position == .midfielder }.prefix(5)
        let forwards = allPlayers.filter { $0.position == .forward }.prefix(3)
        
        var selectedPlayers: [Player] = []
        selectedPlayers.append(contentsOf: goalkeepers)
        selectedPlayers.append(contentsOf: defenders)
        selectedPlayers.append(contentsOf: midfielders)
        selectedPlayers.append(contentsOf: forwards)
        
        // Add players to squad
        squad.players = Array(selectedPlayers.prefix(15))
        
        // Set up 4-2-3-1 formation (11 starters)
        if selectedPlayers.count >= 11 {
            let gk = Array(goalkeepers.prefix(1))
            let def = Array(defenders.prefix(4))
            let mid = Array(midfielders.prefix(5))
            let fwd = Array(forwards.prefix(1))
            
            // Build 2D structure for starting XI
            squad.startingXIIDs = [
                gk.map { $0.id },      // 1 GK
                def.map { $0.id },     // 4 DEF
                mid.map { $0.id },     // 5 MID (will split into 2-3)
                fwd.map { $0.id }      // 1 FWD
            ]
            
            // Remaining players go to bench (4 players)
            let startingIDs = Set(gk.map { $0.id } + def.map { $0.id } + mid.map { $0.id } + fwd.map { $0.id })
            squad.benchIDs = selectedPlayers.filter { !startingIDs.contains($0.id) }.prefix(4).map { $0.id }
            
            // Set captain and vice-captain
            if let captain = fwd.first {
                squad.captain = captain
            }
            if let viceCaptain = mid.first {
                squad.viceCaptain = viceCaptain
            }
        }
    }
    
    try? context.save()
    
    return SquadView(
        viewModel: SquadViewModel(squadRepository: squadRepo, playerRepository: playerRepo),
        playerRepository: playerRepo,
        squadRepository: squadRepo
    )
    .modelContainer(container)
}
