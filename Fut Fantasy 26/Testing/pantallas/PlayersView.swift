//
//  PlayersView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import SwiftUI
import SwiftData

struct PlayersView: View {
    let playerRepository: PlayerRepository
    
    @State private var players: [Player] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingFilters = false
    @State private var searchText = ""
    
    // Filter state
    @State private var selectedPosition: PlayerPosition?
    @State private var selectedNation: Nation?
    @State private var maxPrice: Double?
    @State private var sortType: PlayerSortType = .points
    
    var body: some View {
        NavigationStack {
            playerList
                .navigationTitle("Players")
                .navigationBarTitleDisplayMode(.automatic)
                .searchable(
                    text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .automatic),
                    prompt: "Search by name"
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit(of: .search) {
                    Task {
                        if !searchText.isEmpty {
                            await performSearch(searchText)
                        }
                    }
                }
                .onChange(of: searchText) { oldValue, newValue in
                    if newValue.isEmpty {
                        Task {
                            await loadPlayers()
                        }
                    } else if newValue.count >= 2 {
                        Task {
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            if searchText == newValue {
                                await performSearch(newValue)
                            }
                        }
                    }
                }
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
                .toolbarBackground(.automatic) // ✅ Only blur the navbar
                .sheet(isPresented: $showingFilters) {
                    PlayerFiltersView(
                        selectedPosition: $selectedPosition,
                        selectedNation: $selectedNation,
                        maxPrice: $maxPrice,
                        sortType: $sortType,
                        onApply: {
                            showingFilters = false
                            Task { await loadPlayers() }
                        },
                        onReset: {
                            selectedPosition = nil
                            selectedNation = nil
                            maxPrice = nil
                            sortType = .points
                            Task { await loadPlayers() }
                        }
                    )
                }
                .task {
                    if players.isEmpty {
                        await loadPlayers()
                    }
                }
        }
    }
    
    @ViewBuilder
    private var playerList: some View {
        if isLoading {
            ProgressView("Loading...")
        } else if let errorMessage = errorMessage {
            ContentUnavailableView {
                Label("Error", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Retry") {
                    Task { await loadPlayers() }
                }
            }
        } else if players.isEmpty {
            ContentUnavailableView(
                "No Players Found",
                systemImage: "person.3.fill",
                description: Text("Try adjusting your filters or search")
            )
        } else {
            List(players, id: \.id) { player in
                NavigationLink(destination: PlayerDetailView(player: player, playerRepository: playerRepository)) {
                    PlayerRowView(player: player)
                }
            }
            .listStyle(.plain) // ✅ Clean style for better scroll behavior
            .refreshable {
                await loadPlayers()
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        selectedPosition != nil || selectedNation != nil || maxPrice != nil || sortType != .points
    }
    
    private func loadPlayers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            players = try await playerRepository.fetchPlayersForSquadBuilding(
                position: selectedPosition,
                nation: selectedNation,
                priceUnder: maxPrice,
                sortType: sortType,
                limit: 100,
                offset: 0
            )
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to fetch players: \(error)")
        }
        
        isLoading = false
    }
    
    private func performSearch(_ query: String) async {
        guard !query.isEmpty else {
            await loadPlayers()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            players = try await playerRepository.searchPlayers(query: query)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Search failed: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Component Views

struct PlayerRowView: View {
    let player: Player
    
    var body: some View {
        HStack(spacing: 12) {
            // Player image
            AsyncImage(url: player.imageURL.isEmpty ? nil : URL(string: player.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.2))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            // Player info
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    // Nation flag
                    AsyncImage(url: player.nationFlagURL.isEmpty ? nil : URL(string: player.nationFlagURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 20, height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    
                    // Position
                    Text(player.position.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                        }
                }
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(player.totalPoints)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(player.displayPrice)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail View

struct PlayerDetailView: View {
    let player: Player
    let playerRepository: PlayerRepository
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    AsyncImage(url: player.imageURL.isEmpty ? nil : URL(string: player.imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.2))
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    
                    Text(player.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        AsyncImage(url: player.nationFlagURL.isEmpty ? nil : URL(string: player.nationFlagURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 32, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        Text(player.nation.rawValue)
                            .font(.subheadline)
                        
                        Text("•")
                        
                        Text(player.position.rawValue)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
                
                // Stats
                VStack(spacing: 16) {
                    HStack {
                        StatBox(title: "Total Points", value: "\(player.totalPoints)")
                        StatBox(title: "Price", value: player.displayPrice)
                    }
                    
                    HStack {
                        StatBox(title: "Form", value: "\(player.matchdayPoints)")
                        StatBox(title: "Appearances", value: "\(player.appearances)")
                    }
                }
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Information")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        InfoRow(label: "Full Name", value: "\(player.firstName) \(player.lastName)")
                        Divider()
                        InfoRow(label: "Shirt Number", value: "#\(player.shirtNumber)")
                        Divider()
                        InfoRow(label: "Group", value: player.group?.rawValue ?? "N/A")
                    }
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .navigationTitle("Player Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding()
    }
}

// MARK: - Filters View

struct PlayerFiltersView: View {
    @Binding var selectedPosition: PlayerPosition?
    @Binding var selectedNation: Nation?
    @Binding var maxPrice: Double?
    @Binding var sortType: PlayerSortType
    
    let onApply: () -> Void
    let onReset: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Position") {
                    Picker("Position", selection: $selectedPosition) {
                        Text("All").tag(nil as PlayerPosition?)
                        ForEach([PlayerPosition.goalkeeper, .defender, .midfielder, .forward], id: \.self) { position in
                            Text(position.rawValue).tag(position as PlayerPosition?)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Nation") {
                    Picker("Nation", selection: $selectedNation) {
                        Text("All Nations").tag(nil as Nation?)
                        ForEach([Nation.argentina, .brazil, .england, .france, .germany, .spain, .portugal], id: \.self) { nation in
                            Text(nation.rawValue).tag(nation as Nation?)
                        }
                    }
                }
                
                Section("Price") {
                    Toggle("Set Max Price", isOn: Binding(
                        get: { maxPrice != nil },
                        set: { if !$0 { maxPrice = nil } else { maxPrice = 10.0 } }
                    ))
                    
                    if maxPrice != nil {
                        HStack {
                            Text("Max:")
                            Slider(value: Binding(
                                get: { maxPrice ?? 10.0 },
                                set: { maxPrice = $0 }
                            ), in: 4.0...15.0, step: 0.5)
                            Text("$\(String(format: "%.1f", maxPrice ?? 10.0))M")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Sort By") {
                    Picker("Sort", selection: $sortType) {
                        Text("Points").tag(PlayerSortType.points)
                        Text("Price").tag(PlayerSortType.price)
                        Text("Value").tag(PlayerSortType.value)
                        Text("Form").tag(PlayerSortType.form)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .destructiveAction) {
                    Button("Reset") {
                        onReset()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let container = SwiftDataManager.shared.previewContainer
    
    MainActor.assumeIsolated {
        let context = ModelContext(container)
        WorldCupDataSeeder.seedDataIfNeeded(context: context)
    }
    
    let contextProvider = ModelContextProvider(container: container)
    let playerRepository: PlayerRepository = SwiftDataPlayerRepository(contextProvider: contextProvider)
    
    return PlayersView(playerRepository: playerRepository)
        .modelContainer(container)
}
