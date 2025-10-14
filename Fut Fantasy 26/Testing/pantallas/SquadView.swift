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
                    onPlayerTap: handlePlayerTap
                )
                .padding()
                
                BenchView(
                    benchPlayers: squad.bench ?? [],
                    isEditMode: isEditMode,
                    selectedSlot: $selectedSlot,
                    isPlayerTappable: isPlayerTappable,
                    onPlayerTap: handlePlayerTap
                )
                .padding(.horizontal)
                
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

        // SAME AS MARBLE EXAMPLE: If tapping a non-tappable slot, do nothing
        if !isPlayerTappable(slot: tappedSlot) {
            return
        }

        // SAME AS MARBLE EXAMPLE: If tapping the currently selected slot, deselect it
        if selectedSlot == tappedSlot {
            selectedSlot = nil
            return
        }

        // SAME AS MARBLE EXAMPLE: If no slot is selected yet, select the tapped one
        guard let firstSlot = selectedSlot else {
            selectedSlot = tappedSlot
            return
        }
        
        // SAME AS MARBLE EXAMPLE: At this point, two valid slots are selected. Perform the swap.
        let secondSlot = tappedSlot
        
        Task {
            guard let squadId = squad?.id else { return }
            await viewModel.swapPlayers(firstSlot, secondSlot, squadId: squadId)
            selectedSlot = nil
        }
    }
    
    private func isPlayerTappable(slot: PlayerSlot) -> Bool {
        // SAME AS MARBLE EXAMPLE: If no player is selected, all slots are tappable
        guard let selected = selectedSlot else {
            return true
        }
        
        // SAME AS MARBLE EXAMPLE: The selected slot itself is always tappable (to deselect)
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
        // --- Rule: Field <-> Field ---
        // SAME AS MARBLE: Allow swaps only within the same "row" (position)
        case (.starting, .starting):
            return selectedPlayer.position == targetPlayer.position
        
        // --- Rule: Field <-> Bench ---
        // SAME AS MARBLE: Requires both slots to have a player and colors (positions) match
        case (.starting, .bench), (.bench, .starting):
            return selectedPlayer.position == targetPlayer.position
            
        // --- Rule: Bench <-> Bench ---
        // SAME AS MARBLE: Disallow swapping between two bench players
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
    
    return SquadView(
        viewModel: SquadViewModel(squadRepository: squadRepo, playerRepository: playerRepo),
        playerRepository: playerRepo,
        squadRepository: squadRepo
    )
    .modelContainer(container)
}
