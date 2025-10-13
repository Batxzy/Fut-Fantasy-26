import SwiftUI
import SwiftData

struct TransfersView: View {
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    let squadViewModel: SquadViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlayerToRemove: Player?
    @State private var showingPlayerSelection = false
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var pendingTransfers: [TransferMove] = []
    @State private var showingCaptainSelection = false
    
    var body: some View {
        VStack(spacing: 0) {
            transferHeader
            
            Divider()
            
            if let error = errorMessage {
                errorBanner(error)
            }
            
            if !pendingTransfers.isEmpty {
                pendingTransfersSection
            }
            
            squadList
        }
        .navigationTitle("Transfers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Confirm") {
                    Task {
                        await confirmAllTransfers()
                    }
                }
                .disabled(pendingTransfers.isEmpty)
                .opacity(pendingTransfers.isEmpty ? 0.5 : 1.0)
            }
        }
        .sheet(isPresented: $showingPlayerSelection) {
            if let playerToRemove = selectedPlayerToRemove {
                PlayerSelectionView(
                    playerRepository: playerRepository,
                    playerToReplace: playerToRemove,
                    currentSquad: squadViewModel.squad,
                    temporaryBudget: calculateTemporaryBudget(),
                    onPlayerSelected: { newPlayer in
                        addPendingTransfer(out: playerToRemove, in: newPlayer)
                        selectedPlayerToRemove = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showingCaptainSelection) {
            if let squad = squadViewModel.squad {
                CaptainSelectionView(
                    squad: squad,
                    onCaptainSelected: { player in
                        Task { await squadViewModel.setCaptain(player) }
                    },
                    onViceCaptainSelected: { player in
                        Task { await squadViewModel.setViceCaptain(player) }
                    }
                )
            }
        }
        .overlay {
            if isProcessing {
                processingOverlay
            }
        }
    }
    
    // MARK: - Extracted View Components
    
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
                        .foregroundStyle(
                            pendingTransfers.count > (squadViewModel.squad?.freeTransfersRemaining ?? 0) ?
                            .red : .primary
                        )
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Budget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(displayTemporaryBudget())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            calculateTemporaryBudget() < 0 ? .red : .primary
                        )
                }
            }
            .padding()
        }
        .background(.regularMaterial)
    }
    
    @ViewBuilder
    var squadList: some View {
        if let squad = squadViewModel.squad {
            List {
                Section("Current Squad") {
                    ForEach(squad.players ?? [], id: \.id) { player in
                        HStack {
                            NavigationLink(destination: PlayerDetailView(player: player, playerRepository: playerRepository, squadRepository: squadRepository)) {
                                PlayerRowView(player: player)
                            }
                            
                            Spacer()
                            
                            Button {
                                selectedPlayerToRemove = player
                                showingPlayerSelection = true
                            } label: {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                            .buttonStyle(.plain)
                            .disabled(isProcessing || isPendingTransfer(player))
                            .opacity(isPendingTransfer(player) ? 0.6 : 1.0)
                        }
                    }
                }
                
                if let captain = squad.captain {
                    Section("Team Captain") {
                        PlayerRowView(player: captain)
                            .overlay(alignment: .trailing) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                    .padding(.trailing, 8)
                            }
                    }
                }
                
                if let viceCaptain = squad.viceCaptain {
                    Section("Vice Captain") {
                        PlayerRowView(player: viceCaptain)
                            .overlay(alignment: .trailing) {
                                Text("V")
                                    .font(.caption)
                                    .padding(4)
                                    .background(Circle().fill(.purple))
                                    .foregroundStyle(.white)
                                    .padding(.trailing, 8)
                            }
                    }
                }
                
                Section("Leadership") {
                    Button("Set Captain") {
                        showingCaptainSelection = true
                    }
                    .disabled(isProcessing)
                }
            }
        }
    }
    
    private func errorBanner(_ error: String) -> some View {
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
    
    private var pendingTransfersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pending Transfers")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(pendingTransfers.indices, id: \.self) { index in
                        pendingTransferCard(for: pendingTransfers[index], at: index)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
        }
        .padding(.vertical)
        .background(Color(.systemGray6))
    }
    
    private func pendingTransferCard(for transfer: TransferMove, at index: Int) -> some View {
        VStack(spacing: 6) {
            HStack(alignment: .center, spacing: 6) {
                // Player out
                VStack {
                    AsyncImage(url: URL(string: transfer.playerOut.imageURL)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: { Circle().fill(.quaternary) }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    
                    Text(transfer.playerOut.lastName.isEmpty ? transfer.playerOut.name : transfer.playerOut.lastName)
                        .font(.caption)
                        .lineLimit(1)
                    
                    Text(transfer.playerOut.displayPrice)
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                
                // Player in
                VStack {
                    AsyncImage(url: URL(string: transfer.playerIn.imageURL)) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: { Circle().fill(.quaternary) }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    
                    Text(transfer.playerIn.lastName.isEmpty ? transfer.playerIn.name : transfer.playerIn.lastName)
                        .font(.caption)
                        .lineLimit(1)
                    
                    Text(transfer.playerIn.displayPrice)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
            
            // Cancel button
            Button {
                pendingTransfers.remove(at: index)
            } label: {
                Text("Cancel")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.red.opacity(0.1)))
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(.regularMaterial))
    }
    
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            
            VStack(spacing: 12) {
                ProgressView()
                Text("Processing transfers...")
                    .font(.subheadline)
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Functions
    
    private func isPendingTransfer(_ player: Player) -> Bool {
        return pendingTransfers.contains { $0.playerOut.id == player.id }
    }
    
    private func addPendingTransfer(out: Player, in: Player) {
        let transfer = TransferMove(playerOut: out, playerIn: `in`)
        pendingTransfers.append(transfer)
    }
    
    private func calculateTemporaryBudget() -> Double {
        guard let squad = squadViewModel.squad else { return 0 }
        var tempBudget = squad.currentBudget
        for transfer in pendingTransfers {
            tempBudget += transfer.playerOut.price
            tempBudget -= transfer.playerIn.price
        }
        return tempBudget
    }
    
    private func displayTemporaryBudget() -> String {
        let budget = calculateTemporaryBudget()
        return String(format: "$%.1fM", budget)
    }
    
    private func confirmAllTransfers() async {
        guard !pendingTransfers.isEmpty else { return }
        
        isProcessing = true
        errorMessage = nil
        
        let transfersToProcess = pendingTransfers
        pendingTransfers = []

        for transfer in transfersToProcess {
            print("🔄 Processing transfer: \(transfer.playerOut.name) → \(transfer.playerIn.name)")
            await squadViewModel.transferPlayer(out: transfer.playerOut, in: transfer.playerIn)
        }
        
        print("✅ All transfers completed")
        
        if squadViewModel.errorMessage == nil {
            dismiss()
        } else {
            self.errorMessage = squadViewModel.errorMessage
        }
        
        isProcessing = false
    }
}

// MARK: - Supporting Types

struct TransferMove: Identifiable {
    let id = UUID()
    let playerOut: Player
    let playerIn: Player
}

struct PlayerSelectionView: View {
    let playerRepository: PlayerRepository
    let playerToReplace: Player
    let currentSquad: Squad?
    let temporaryBudget: Double
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
                } else if filteredPlayers.isEmpty {
                    ContentUnavailableView(
                        "No Replacements Found",
                        systemImage: "person.3.fill",
                        description: Text("Try adjusting your search or filters. Ensure you have enough budget.")
                    )
                } else {
                    List(filteredPlayers, id: \.id) { player in
                        Button {
                            onPlayerSelected(player)
                            dismiss()
                        } label: {
                            HStack {
                                PlayerRowView(player: player)
                                
                                Spacer()
                                
                                if isInSquad(player) {
                                    Label("In Squad", systemImage: "checkmark.circle.fill")
                                        .font(.caption).foregroundStyle(.green)
                                } else if !canAfford(player) {
                                    Label("Can't Afford", systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption).foregroundStyle(.red)
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
                    Button("Cancel") { dismiss() }
                }
            }
            .task {
                selectedPosition = playerToReplace.position
                await loadPlayers()
            }
            .onChange(of: selectedPosition) {
                Task { await loadPlayers() }
            }
        }
    }
    
    private var filteredPlayers: [Player] {
        var filtered = players
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filtered = filtered.filter { canAfford($0) }
        
        return filtered
    }
    
    private func canAfford(_ player: Player) -> Bool {
        return (temporaryBudget + playerToReplace.price) >= player.price
    }
    
    private func isInSquad(_ player: Player) -> Bool {
        currentSquad?.players?.contains(where: { $0.id == player.id }) ?? false
    }
    
    private func loadPlayers() async {
        guard let position = selectedPosition else { return }
        isLoading = true
        
        do {
            players = try await playerRepository.fetchPlayersForSquadBuilding(
                position: position,
                nation: nil,
                priceUnder: nil,
                sortType: .points,
                limit: 200,
                offset: 0
            )
            print("✅ Loaded \(players.count) players for position: \(position.rawValue)")
        } catch {
            print("❌ Error loading players: \(error)")
        }
        
        isLoading = false
    }
}

#Preview {
    // 1. Setup Data Layer
    let container = SwiftDataManager.shared.previewContainer
    let contextProvider = ModelContextProvider(container: container)
    let mainContext = contextProvider.mainContext

    MainActor.assumeIsolated {
        WorldCupDataSeeder.seedDataIfNeeded(context: mainContext)
    }
    
    let playerRepository = SwiftDataPlayerRepository(modelContext: mainContext)
    let squadRepository = SwiftDataSquadRepository(modelContext: mainContext, playerRepository: playerRepository)
    
    // 2. Create the View with an EMPTY ViewModel first.
    //    The @StateObject wrapper is key here.
    let view = TransfersView(
        playerRepository: playerRepository,
        squadRepository: squadRepository,
        squadViewModel: SquadViewModel(
            squadRepository: squadRepository,
            playerRepository: playerRepository
        )
    )

    // 3. Wrap in NavigationStack and run the seeding task.
    return NavigationStack {
        view
    }
    .task {
        // This task now runs, seeds the data, and the view's own task
        // will fetch it correctly after this is done.
        print("🚀 [Preview] Seeding squad for TransfersView...")
        await WorldCupDataSeeder.seedSquadIfNeeded(
            squadRepository: squadRepository,
            playerRepository: playerRepository,
            context: mainContext
        )
        print("✅ [Preview] TransfersView seeding complete.")
    }
    .modelContainer(container)
}
