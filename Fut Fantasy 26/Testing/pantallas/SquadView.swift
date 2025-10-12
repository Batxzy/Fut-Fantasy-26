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
    @State private var showingTransfers = false
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
                        .disabled((viewModel?.squad?.startingXI?.count ?? 0) == 0)
                        
                        Button {
                            showingTransfers = true
                        } label: {
                            Image(systemName: "arrow.left.arrow.right.circle")
                        }
                    }
                }
            }
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .sheet(isPresented: $showingTransfers) {
                if let viewModel = viewModel {
                    TransfersView(
                        playerRepository: playerRepository,
                        squadViewModel: viewModel
                    )
                }
            }
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
                
                // Formation info
                if let startingXI = squad.startingXI, !startingXI.isEmpty {
                    formationInfo(squad: squad)
                }
                
                // Formation Pitch
                FormationView(
                    startingXI: squad.startingXI ?? [],
                    captain: squad.captain,
                    viceCaptain: squad.viceCaptain,
                    isDragMode: isDragMode,
                    onPlayerTap: { player in
                        if !isDragMode {
                            // Show player detail
                            print("👆 Tapped player: \(player.name)")
                        }
                    },
                    onPlayerMove: { fromIndex, toIndex in
                        Task {
                            await viewModel.swapStartingPlayers(from: fromIndex, to: toIndex)
                        }
                    }
                )
                .frame(height: 500)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal)
                
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
                
                // Helpful tip if squad is empty
                if (squad.players?.count ?? 0) < 15 {
                    helpfulTip
                }
            }
            .padding(.vertical)
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
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
                        .foregroundColor(squad.currentBudget < 0 ? .red : .primary)
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
                        .foregroundColor((squad.players?.count ?? 0) < 15 ? .orange : .green)
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
    
    @ViewBuilder
    private func formationInfo(squad: Squad) -> some View {
        HStack(spacing: 20) {
            // Formation display
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.blue)
                Text("Formation:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(squad.formationString)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // Captain info
            if let captain = squad.captain {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Captain:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(captain.lastName.isEmpty ? captain.name : captain.lastName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var helpfulTip: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Quick Tip")
                    .font(.headline)
                Spacer()
            }
            
            Text("Go to the Players tab to add players to your squad. You need 15 players total: 2 Goalkeepers, 5 Defenders, 5 Midfielders, and 3 Forwards.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.blue.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.blue.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}
