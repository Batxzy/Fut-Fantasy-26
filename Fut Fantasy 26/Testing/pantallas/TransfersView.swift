//
//  TransfersView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


//
//  TransfersView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

import SwiftUI

import SwiftUI

struct TransfersView: View {
    let playerRepository: PlayerRepository
    let squadViewModel: SquadViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlayerToRemove: Player?
    @State private var showingPlayerSelection = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Transfer info header
                transferHeader
                
                Divider()
                
                // Error banner
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.red.opacity(0.1))
                }
                
                // Players to transfer out
                if let squad = squadViewModel.squad {
                    List {
                        Section("Current Squad - Tap to Replace") {
                            ForEach(squad.players ?? [], id: \.id) { player in
                                Button {
                                    selectedPlayerToRemove = player
                                    showingPlayerSelection = true
                                } label: {
                                    HStack {
                                        PlayerRowView(player: player)
                                        Spacer()
                                        Image(systemName: "arrow.right.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .disabled(isProcessing)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Transfers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPlayerSelection) {
                if let playerToRemove = selectedPlayerToRemove {
                    PlayerSelectionView(
                        playerRepository: playerRepository,
                        playerToReplace: playerToRemove,
                        currentSquad: squadViewModel.squad,
                        onPlayerSelected: { newPlayer in
                            Task {
                                await handleTransfer(oldPlayer: playerToRemove, newPlayer: newPlayer)
                            }
                        }
                    )
                }
            }
            .overlay {
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Processing transfer...")
                                .font(.subheadline)
                        }
                        .padding()
                        .background(.regularMaterial)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private var transferHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Free Transfers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(squadViewModel.squad?.freeTransfersRemaining ?? 0)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Budget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(squadViewModel.squad?.displayBudget ?? "£0.0M")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .padding()
        }
        .background(.regularMaterial)
    }
    
    private func handleTransfer(oldPlayer: Player, newPlayer: Player) async {
        isProcessing = true
        errorMessage = nil
        
        do {
            print("🔄 Starting transfer: \(oldPlayer.name) → \(newPlayer.name)")
            await squadViewModel.transferPlayer(out: oldPlayer, in: newPlayer)
            print("✅ Transfer completed successfully")
            
            // Dismiss the sheet
            showingPlayerSelection = false
            selectedPlayerToRemove = nil
            
        } catch {
            print("❌ Transfer failed: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isProcessing = false
    }
}

struct PlayerSelectionView: View {
    let playerRepository: PlayerRepository
    let playerToReplace: Player
    let currentSquad: Squad?
    let onPlayerSelected: (Player) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var players: [Player] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedPosition: PlayerPosition?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    ProgressView("Loading players...")
                } else {
                    List(filteredPlayers, id: \.id) { player in
                        Button {
                            onPlayerSelected(player)
                            dismiss()
                        } label: {
                            HStack {
                                PlayerRowView(player: player)
                                
                                Spacer()
                                
                                // Validation indicators
                                if isInSquad(player) {
                                    Label("In Squad", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                } else if !canAfford(player) {
                                    Label("Can't Afford", systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .disabled(isInSquad(player) || !canAfford(player))
                    }
                }
            }
            .navigationTitle("Select Replacement")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search players")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All Positions") { selectedPosition = nil }
                        Divider()
                        ForEach([PlayerPosition.goalkeeper, .defender, .midfielder, .forward], id: \.self) { position in
                            Button(position.rawValue) {
                                selectedPosition = position
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .task {
                await loadPlayers()
            }
        }
    }
    
    private var filteredPlayers: [Player] {
        var filtered = players
        
        // Always filter by same position as player being replaced
        filtered = filtered.filter { $0.position == playerToReplace.position }
        
        // Filter by selected position filter
        if let position = selectedPosition {
            filtered = filtered.filter { $0.position == position }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    private func canAfford(_ player: Player) -> Bool {
        guard let squad = currentSquad else { return false }
        let budgetAfterSale = squad.currentBudget + playerToReplace.price
        return budgetAfterSale >= player.price
    }
    
    private func isInSquad(_ player: Player) -> Bool {
        currentSquad?.players?.contains(where: { $0.id == player.id }) ?? false
    }
    
    private func loadPlayers() async {
        isLoading = true
        
        do {
            // Load all players of same position
            players = try await playerRepository.fetchPlayersForSquadBuilding(
                position: playerToReplace.position,
                nation: nil,
                priceUnder: nil,
                sortType: .points,
                limit: 200,
                offset: 0
            )
            print("✅ Loaded \(players.count) players for position: \(playerToReplace.position.rawValue)")
        } catch {
            print("❌ Error loading players: \(error)")
        }
        
        isLoading = false
    }
}
