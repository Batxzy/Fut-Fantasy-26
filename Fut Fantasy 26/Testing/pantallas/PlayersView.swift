//
//  PlayersView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import SwiftUI
import SwiftData

struct PlayersView: View {

    @Query(sort: \Player.totalPoints, order: .reverse) private var allPlayers: [Player]
    
    // ✅ ViewModel only for write operations
    @Bindable var viewModel: PlayerViewModel
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    
    @State private var showingFilters = false
    @State private var searchText = ""
    @State private var selectedPosition: PlayerPosition?
    @State private var selectedNation: Nation?
    @State private var maxPrice: Double?
    @State private var sortType: PlayerSortType = .points
    
    // Computed filtered players
    var filteredPlayers: [Player] {
        var filtered = allPlayers
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedStandardContains(searchText) ||
                $0.firstName.localizedStandardContains(searchText) ||
                $0.lastName.localizedStandardContains(searchText)
            }
        }
        
        // Apply position filter
        if let position = selectedPosition {
            filtered = filtered.filter { $0.position == position }
        }
        
        // Apply nation filter
        if let nation = selectedNation {
            filtered = filtered.filter { $0.nation == nation }
        }
        
        // Apply price filter
        if let maxPrice = maxPrice {
            filtered = filtered.filter { $0.price <= maxPrice }
        }
        
        // Apply sorting
        switch sortType {
        case .points:
            filtered.sort { $0.totalPoints > $1.totalPoints }
        case .price:
            filtered.sort {
                if $0.price != $1.price {
                    return $0.price < $1.price
                } else {
                    return $0.totalPoints > $1.totalPoints
                }
            }
        case .value:
            filtered.sort { $0.pointsPerPrice > $1.pointsPerPrice }
        case .form:
            filtered.sort { $0.matchdayPoints > $1.matchdayPoints }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .padding()
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
                
                playerList
            }
            .navigationTitle("Players")
            .navigationBarTitleDisplayMode(.automatic)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: "Search by name"
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .symbolVariant(hasActiveFilters ? .fill : .none)
                            .foregroundStyle(hasActiveFilters ? Color.accentColor : .primary)
                    }
                }
            }
            .toolbarBackground(.automatic)
            .sheet(isPresented: $showingFilters) {
                PlayerFiltersView(
                    selectedPosition: $selectedPosition,
                    selectedNation: $selectedNation,
                    maxPrice: $maxPrice,
                    sortType: $sortType,
                    onApply: {
                        showingFilters = false
                    },
                    onReset: {
                        selectedPosition = nil
                        selectedNation = nil
                        maxPrice = nil
                        sortType = .points
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    private var playerList: some View {
        if filteredPlayers.isEmpty {
            ContentUnavailableView(
                "No Players Found",
                systemImage: "person.3.fill",
                description: Text("Try adjusting your filters or search")
            )
        } else {
            List(filteredPlayers, id: \.id) { player in
                NavigationLink(
                    destination: PlayerDetailView(
                        player: player,
                        viewModel: viewModel,
                        playerRepository: playerRepository,
                        squadRepository: squadRepository
                    )
                ) {
                    PlayerRowView(player: player)
                }
            }
            .listStyle(.plain)
        }
    }
    
    private var hasActiveFilters: Bool {
        selectedPosition != nil || selectedNation != nil || maxPrice != nil || sortType != .points
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Player.self, Squad.self,
        configurations: config
    )
    
    let context = container.mainContext
    
    // Seed data
    WorldCupDataSeeder.seedDataIfNeeded(context: context)
    
    let playerRepo = SwiftDataPlayerRepository(modelContext: context)
    let squadRepo = SwiftDataSquadRepository(modelContext: context, playerRepository: playerRepo)
    
    return PlayersView(
        viewModel: PlayerViewModel(repository: playerRepo),
        playerRepository: playerRepo,
        squadRepository: squadRepo
    )
    .modelContainer(container)
}
