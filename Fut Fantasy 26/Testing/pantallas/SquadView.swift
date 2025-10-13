//
//  SquadView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

import SwiftUI
import SwiftData

struct SquadView: View {
    // ✅ @Query automatically fetches and observes squad
    @Query private var squads: [Squad]
    
    // ✅ ViewModel only for write operations
    @Bindable var viewModel: SquadViewModel
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    
    @State private var isDragMode = false
    @State private var showingCaptainSelection = false
    
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
                        Button {
                            withAnimation {
                                isDragMode.toggle()
                            }
                        } label: {
                            Image(systemName: isDragMode ? "checkmark.circle.fill" : "arrow.up.arrow.down.circle")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(isDragMode ? .green : .primary)
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
                        }
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
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
                // Squad Info Header
                squadHeader(squad: squad)
                
                // Formation Pitch
                FormationView(
                    startingXI: squad.startingXI ?? [],
                    captain: squad.captain,
                    viceCaptain: squad.viceCaptain,
                    isDragMode: isDragMode,
                    onPlayerTap: { _ in },
                    onPlayerMove: { fromIndex, toIndex in
                        Task {
                            await viewModel.swapStartingPlayers(
                                from: fromIndex,
                                to: toIndex,
                                squadId: squad.id,
                                startingXI: squad.startingXI ?? []
                            )
                        }
                    },
                    playerRepository: playerRepository,
                    squadRepository: squadRepository
                )
                .padding()
                
                // Bench
                BenchView(
                    benchPlayers: squad.bench ?? [],
                    isDragMode: isDragMode,
                    onSubstitution: { benchPlayer, startingPlayer in
                        Task {
                            await viewModel.makeSubstitution(
                                benchPlayer: benchPlayer,
                                startingPlayer: startingPlayer,
                                squadId: squad.id,
                                startingXI: squad.startingXI ?? []
                            )
                        }
                    }
                )
                .padding(.horizontal)
                
                // Set Captain Button
                Button("Set Captain & Vice-Captain") {
                    showingCaptainSelection = true
                }
                .buttonStyle(.bordered)
                .padding()
            }
            .padding(.vertical)
        }
        .scrollContentBackground(.hidden)
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
}
#Preview {
    let squad = MockData.squad
    
    return CaptainSelectionView(
        squad: squad,
        onCaptainSelected: { player in print("Captain selected: \(player.name)") },
        onViceCaptainSelected: { player in print("Vice-captain selected: \(player.name)") }
    )
}
