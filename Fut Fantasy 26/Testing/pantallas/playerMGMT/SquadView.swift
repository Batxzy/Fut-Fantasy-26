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
   
    
    @Query private var squads: [Squad]
    
    @Bindable var viewModel: SquadViewModel
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    
    @State private var isEditMode = false
    @State private var showingCaptainSelection = false
    @State private var selectedSlot: PlayerSlot?
    
    var squad: Squad? {
        squads.first
    }
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.mainBg)
                    .ignoresSafeArea()
                
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
                        Button {
                            isEditMode.toggle()
                            if !isEditMode {
                                selectedSlot = nil
                            }
                        } label: {
                            Image(systemName: isEditMode ? "pencil.circle.fill" : "pencil.circle")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(isEditMode ? .green : .primary)
                                .font(.title3)
                                .symbolEffect(.bounce, value: isEditMode)
                        }
                        .disabled((squad?.startingXI?.isEmpty) ?? true)
                        
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
            .toolbarColorScheme(.dark, for: .navigationBar)
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
    
    private func squadContent(squad: Squad) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                ZStack(alignment: .top) {
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
                    .padding(.horizontal, 24)
                    .padding(.top, 80)
                    .animation(.bouncy(duration: 0.75), value: squad.startingXI?.map { $0.id })
                    
                    VStack(spacing: 0) {
                        LinearGradient(
                            stops: [
                                Gradient.Stop(color:.mainBg, location: 0.00),
                                Gradient.Stop(color: .mainBg.opacity(0), location: 1.00),
                            ],
                            startPoint: UnitPoint(x: 0.5, y: 0),
                            endPoint: UnitPoint(x: 0.5, y: 1)
                        )
                        .frame(height: 150)
                        
                        Spacer()
                    }
                    .allowsHitTesting(false)
                    
                    squadHeader(squad: squad)
                }
             
                BenchView(
                    benchPlayers: squad.bench ?? [],
                    isEditMode: isEditMode,
                    selectedSlot: $selectedSlot,
                    isPlayerTappable: isPlayerTappable,
                    onPlayerTap: handlePlayerTap,
                    playerRepository: playerRepository,
                    squadRepository: squadRepository
                )
                .animation(.bouncy(duration: 0.75), value: squad.bench?.map { $0.id })
                
                Button("Set Captain & Vice-Captain") {
                    showingCaptainSelection = true
                }
                .buttonStyle(.bordered)
            }
        }
        .scrollContentBackground(.hidden)
    }
    
    private func squadHeader(squad: Squad) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Players")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white)
                Text("\(squad.players?.count ?? 0)/15")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Budget")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.white)
                
                HStack(spacing: 3) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.white)
                    
                    Text(squad.displayBudgetNoDecimals)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 2)
        .padding(.top,12)
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
    
    let squad = Squad(teamName: "Batxzy's Dream Team", ownerName: "Batxzy")
    context.insert(squad)
    
    let fetchDescriptor = FetchDescriptor<Player>(
        sortBy: [SortDescriptor(\.totalPoints, order: .reverse)]
    )
    
    if let allPlayers = try? context.fetch(fetchDescriptor) {
        let goalkeepers = allPlayers.filter { $0.position == .goalkeeper }.prefix(2)
        let defenders = allPlayers.filter { $0.position == .defender }.prefix(5)
        let midfielders = allPlayers.filter { $0.position == .midfielder }.prefix(5)
        let forwards = allPlayers.filter { $0.position == .forward }.prefix(3)
        
        var selectedPlayers: [Player] = []
        selectedPlayers.append(contentsOf: goalkeepers)
        selectedPlayers.append(contentsOf: defenders)
        selectedPlayers.append(contentsOf: midfielders)
        selectedPlayers.append(contentsOf: forwards)
        
        squad.players = Array(selectedPlayers.prefix(15))
        
        if selectedPlayers.count >= 11 {
            let gk = Array(goalkeepers.prefix(1))
            let def = Array(defenders.prefix(4))
            let mid = Array(midfielders.prefix(5))
            let fwd = Array(forwards.prefix(1))
            
            squad.startingXIIDs = [
                gk.map { $0.id },
                def.map { $0.id },
                mid.map { $0.id },
                fwd.map { $0.id }
            ]
            
            let startingIDs = Set(gk.map { $0.id } + def.map { $0.id } + mid.map { $0.id } + fwd.map { $0.id })
            squad.benchIDs = selectedPlayers.filter { !startingIDs.contains($0.id) }.prefix(4).map { $0.id }
            
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
