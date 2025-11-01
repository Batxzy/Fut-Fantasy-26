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
    @Query private var squads: [Squad]
    
    @Bindable var viewModel: PlayerViewModel
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    var preSelectedPosition: PlayerPosition? = nil
    
    @State private var showingFilters = false
    @State private var searchText = ""
    @State private var selectedPosition: PlayerPosition?
    @State private var selectedNation: Nation?
    @State private var maxPrice: Double?
    @State private var isSearching = false
    @State private var sortType: PlayerSortType = .points
    @State private var playerToAdd: Player?
    @State private var showAddConfirmation = false
    @Namespace private var namespace
    
    var currentSquad: Squad? {
        squads.first
    }
    
    func isInSquad(_ player: Player) -> Bool {
        currentSquad?.players?.contains(where: { $0.id == player.id }) ?? false
    }
    
    func canAddPlayer(_ player: Player) -> Bool {
        guard let squad = currentSquad else { return false }
        return !isInSquad(player) && !squad.isFull && squad.currentBudget >= player.price
    }
    
    private func addPlayerToSquad() async {
        guard let squad = currentSquad, let player = playerToAdd else { return }
        
        do {
            try await squadRepository.addPlayerToSquad(playerId: player.id, squadId: squad.id)
            print("✅ [PlayersView] Player added successfully")
        } catch {
            viewModel.errorMessage = error.localizedDescription
            print("❌ [PlayersView] Failed to add player: \(error)")
        }
    }
    
    var filteredPlayers: [Player] {
        var filtered = allPlayers
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedStandardContains(searchText) ||
                $0.firstName.localizedStandardContains(searchText) ||
                $0.lastName.localizedStandardContains(searchText)
            }
        }
        
        if let position = selectedPosition {
            filtered = filtered.filter { $0.position == position }
        }
        
        if let nation = selectedNation {
            filtered = filtered.filter { $0.nation == nation }
        }
        
        if let maxPrice = maxPrice {
            filtered = filtered.filter { $0.price <= maxPrice }
        }
        
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

        VStack(spacing: 0) {
            if viewModel.isLoading {
                ProgressView()
                    .padding()
            }
            
            playerList
        }
        .navigationTitle("Players")
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $searchText,
            isPresented: $isSearching,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search by name"
        )
        .searchToolbarBehavior(.automatic)
        .textInputAutocapitalization(.never)
        .toolbar {
            ToolbarItem(placement: .principal) {
                budgetHeaderView
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingFilters = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .symbolVariant(hasActiveFilters ? .fill : .none)
                }
                .matchedTransitionSource(id: "transition_id", in: namespace)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        
        .scrollEdgeEffectStyle(.soft, for: .top)
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
            .navigationTransition(.zoom(sourceID: "transition_id", in: namespace))
        }
        .alert("Add \(playerToAdd?.name ?? "")?", isPresented: $showAddConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Add", role: .none) {
                Task {
                    await addPlayerToSquad()
                }
            }
        } message: {
            if let player = playerToAdd {
                Text("Add \(player.name) to your squad for \(player.displayPrice)?")
            }
        }
        .onAppear {
            if let position = preSelectedPosition, selectedPosition == nil {
                selectedPosition = position
            }
        }
    }
    
    @ViewBuilder
    private var budgetHeaderView: some View {
        if let squad = currentSquad {
            VStack(alignment: .center, spacing: 4) {
                Text("Budget")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                
                HStack(spacing: 3) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                    
                    Text(squad.displayBudgetNoDecimals)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
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
            ScrollView {
                ZStack(alignment: .top) {
                    Color(.mainBg)
                    GeometryReader { geometry in
                        let minY = geometry.frame(in: .global).minY
                        let scale = max(1.0, 1.0 + (minY / 500))
                        
                        Image("Vector")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width)
                            .scaleEffect(scale)
                            .offset(y: -minY - 1)
                    }
                    .frame(height: 230)
                    
                    GeometryReader { geometry in
                        let minY = geometry.frame(in: .global).minY
                        
                        VStack(spacing: 0) {
                            
                            LinearGradient(
                                stops: [
                                    Gradient.Stop(color: .mainBg.opacity(0.05), location: 0.00),
                                    Gradient.Stop(color: .mainBg.opacity(0.5), location: 0.7),
                                    Gradient.Stop(color: .mainBg, location: 1.00),
                                ],
                                startPoint: UnitPoint(x: 0.5, y: 0),
                                endPoint: UnitPoint(x: 0.5, y: 1)
                            )
                            .frame(height: 230)
                            
                            
                            Color.mainBg
                        }
                        .offset(y: -minY - 1)
                    }
                    .frame(height:300)
                    .allowsHitTesting(false)
                    
                    LazyVStack(spacing: 0) {
                        
                        Color.clear.opacity(0.40).frame(height: 230)
                        
                        ForEach(filteredPlayers, id: \.id) { player in
                            ZStack {
                                NavigationLink(destination: PlayerDetailView(
                                    player: player,
                                    viewModel: viewModel,
                                    playerRepository: playerRepository,
                                    squadRepository: squadRepository
                                )) {
                                    EmptyView()
                                }
                                .opacity(0)
                                
                                HStack(spacing: 12) {
                                    PlayerRowView(player: player)
                                    
                                    Spacer()
                                    
                                    Button {
                                        playerToAdd = player
                                        showAddConfirmation = true
                                    } label: {
                                        Image(systemName: isInSquad(player) ? "checkmark.circle.fill" : "plus.circle")
                                            .font(.system(size: 24))
                                            .foregroundStyle(isInSquad(player) ? .wpAqua : (canAddPlayer(player) ? .wpAqua : .wpAqua))
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isInSquad(player) || !canAddPlayer(player))
                                }
                                .padding(.leading, 16)
                                .padding(.trailing, 16)
                                .padding(.vertical, 16)
                            }
                            .background(Color(.systemGray6))
                            
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
        }
    }
    
    private var hasActiveFilters: Bool {
        selectedPosition != nil || selectedNation != nil || maxPrice != nil || sortType != .points
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
    
    return PlayersView(
        viewModel: PlayerViewModel(repository: playerRepo),
        playerRepository: playerRepo,
        squadRepository: squadRepo
    )
    .modelContainer(container)
}
