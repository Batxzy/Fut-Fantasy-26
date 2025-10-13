//
//  SquadView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import SwiftUI
import SwiftData


struct SquadView: View {
    let squadRepository: SquadRepository
    let playerRepository: PlayerRepository
    
    @State private var viewModel: SquadViewModel?
    @State private var isDragMode = false
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationStack {
            ZStack {
                if let viewModel = viewModel {
                    if viewModel.isLoading {
                        ProgressView("Loading squad...")
                    } else if let errorMessage = viewModel.errorMessage {
                        ContentUnavailableView {
                            Label("Error", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(errorMessage)
                        } actions: {
                            Button("Retry") {
                                Task { await viewModel.loadSquad() }
                            }
                        }
                    } else if let squad = viewModel.squad {
                        squadContent(squad: squad, viewModel: viewModel)
                    } else {
                        ContentUnavailableView(
                            "No Squad",
                            systemImage: "sportscourt",
                            description: Text("Create your squad to get started")
                        )
                    }
                } else {
                    ProgressView()
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
                        .disabled((viewModel?.squad?.startingXI?.isEmpty) ?? true)
                        
                        // Use NavigationLink for transfers
                        if let viewModel = viewModel {
                            NavigationLink {
                                TransfersView(
                                    playerRepository: playerRepository, squadRepository: squadRepository,
                                    squadViewModel: viewModel
                                )
                            } label: {
                                Image(systemName: "arrow.left.arrow.right.circle")
                            }
                        }
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .task {
                if viewModel == nil {
                    viewModel = SquadViewModel(
                        squadRepository: squadRepository,
                        playerRepository: playerRepository
                    )
                    await viewModel?.loadSquad()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .squadDidUpdate)) { _ in
                print("🔔 Squad update notification received")
                Task {
                    await viewModel?.loadSquad()
                    refreshID = UUID()
                }
            }
            .onAppear {
                Task {
                    await viewModel?.loadSquad()
                }
            }
        }
    }
    
    @ViewBuilder
    private func squadContent(squad: Squad, viewModel: SquadViewModel) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Squad Info
                squadHeader(squad: squad)
                    .id(refreshID)
                
                // Formation Pitch
                FormationView(
                    startingXI: squad.startingXI ?? [],
                    captain: squad.captain,
                    viceCaptain: squad.viceCaptain,
                    isDragMode: isDragMode,
                    onPlayerTap: { player in
                        // This closure is now handled inside FormationView with a NavigationLink
                    },
                    onPlayerMove: { fromIndex, toIndex in
                        Task {
                            await viewModel.swapStartingPlayers(from: fromIndex, to: toIndex)
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
                                startingPlayer: startingPlayer
                            )
                        }
                    }
                )
                .padding(.horizontal)
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
