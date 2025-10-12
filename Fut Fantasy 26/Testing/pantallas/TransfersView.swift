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

struct TransfersView: View {
    let playerRepository: PlayerRepository
    let squadViewModel: SquadViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlayerToRemove: Player?
    @State private var showingPlayerSelection = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Transfer info header
                transferHeader
                
                Divider()
                
                // Players to transfer out
                if let squad = squadViewModel.squad {
                    List {
                        Section("Current Squad") {
                            ForEach(squad.players ?? [], id: \.id) { player in
                                Button {
                                    selectedPlayerToRemove = player
                                    showingPlayerSelection = true
                                } label: {
                                    HStack {
                                        PlayerRowView(player: player)
                                        Spacer()
                                        Image(systemName: "arrow.right.circle")
                                            .foregroundStyle(.blue)
                                    }
                                }
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
                PlayerSelectionView(
                    playerRepository: playerRepository,
                    playerToReplace: selectedPlayerToRemove,
                    onPlayerSelected: { newPlayer in
                        if let oldPlayer = selectedPlayerToRemove {
                            Task {
                                await squadViewModel.transferPlayer(out: oldPlayer, in: newPlayer)
                            }
                        }
                        showingPlayerSelection = false
                    }
                )
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
                    Text("1")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Budget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(squadViewModel.squad?.displayBudget ?? "$0.0M")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .padding()
        }
        .background(.regularMaterial)
    }
}

struct PlayerSelectionView: View {
    let playerRepository: PlayerRepository
    let playerToReplace: Player?
    let onPlayerSelected: (Player) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            PlayersView(playerRepository: playerRepository)
                .navigationTitle("Select Player")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}