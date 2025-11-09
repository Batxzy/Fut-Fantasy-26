import SwiftUI
import SwiftData

struct TransfersView: View {
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    @Bindable var viewModel: SquadViewModel
    
    @Query private var squads: [Squad]
    
    @Query(sort: \Player.totalPoints, order: .reverse) private var allPlayers: [Player]
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlayerToRemove: Player?
    @State private var showingPlayerSelection = false
    @State private var isProcessing = false
    @State private var pendingTransfers: [TransferMove] = []
    
    var squad: Squad? {
        squads.first
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let squad = squad {
                transferHeader(squad: squad)
                
                Divider()
                
                if !pendingTransfers.isEmpty {
                    pendingTransfersSection
                }
                
                squadList(squad: squad)
            }
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
                .disabled(pendingTransfers.isEmpty || isProcessing)
                .opacity(pendingTransfers.isEmpty ? 0.5 : 1.0)
            }
        }
        .sheet(item: $selectedPlayerToRemove) { playerToRemove in
            if let squad = squad {
                PlayerSelectionView(
                    allPlayers: allPlayers,
                    playerToReplace: playerToRemove,
                    currentSquad: squad,
                    temporaryBudget: calculateTemporaryBudget(),
                    onPlayerSelected: { newPlayer in
                        addPendingTransfer(out: playerToRemove, in: newPlayer)
                        selectedPlayerToRemove = nil
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
    
    // MARK: - View Components
    
    private func transferHeader(squad: Squad) -> some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Free Transfers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(squad.freeTransfersRemaining)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            pendingTransfers.count > squad.freeTransfersRemaining ?
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
    private func squadList(squad: Squad) -> some View {
        List {
            Section("Current Squad (\((squad.players ?? []).count))") {
                ForEach(squad.players ?? [], id: \.id) { player in
                    HStack(spacing: 12) {
                        PlayerRowView(player: player)
                        
                        Spacer()
                        
                        Button {
                            selectedPlayerToRemove = player
                        } label: {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.black)
                        }
                        .buttonStyle(.glassProminent)
                        .disabled(isProcessing || isPendingTransfer(player))
                        .opacity(isPendingTransfer(player) ? 0.3 : 1.0)
                    }
                }
            }
        }
    }
    
    private var pendingTransfersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pending Transfers (\(pendingTransfers.count))")
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
                    Image(transfer.playerOut.imageURL)
                        .resizable()
                        .padding(.top,3)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .background(.white)
                        .clipShape(Circle())
                    
                    Text(transfer.playerOut.lastName.isEmpty ? transfer.playerOut.name : transfer.playerOut.lastName)
                        .font(.caption)
                        .lineLimit(1)
                    
                    Text(transfer.playerIn.displayPrice)
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
                
                Image(systemName: "arrow.right")
                    .foregroundStyle(.secondary)
                
                // Player in
                VStack {
                    Image(transfer.playerIn.imageURL)
                        .resizable()
                        .padding(.top,3)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .background(.white)
                        .clipShape(Circle())
                    
                    Text(transfer.playerIn.lastName.isEmpty ? transfer.playerIn.name : transfer.playerIn.lastName)
                        .font(.caption)
                        .lineLimit(1)
                    
                    Text(transfer.playerIn.displayPrice)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
            
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
        guard let squad = squad else { return 0 }
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
        guard !pendingTransfers.isEmpty, let squad = squad else { return }
        
        isProcessing = true
        viewModel.errorMessage = nil
        
        let transfersToProcess = pendingTransfers
        pendingTransfers = []

        for transfer in transfersToProcess {
            print("🔄 Processing transfer: \(transfer.playerOut.name) → \(transfer.playerIn.name)")
            
            // Remove old player
            await viewModel.removePlayerFromSquad(transfer.playerOut, squadId: squad.id)
            
            // Add new player
            await viewModel.addPlayerToSquad(transfer.playerIn, squadId: squad.id)
        }
        
        print("✅ All transfers completed")
        
        if viewModel.errorMessage == nil {
            dismiss()
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

// MARK: - Player Selection View

struct PlayerSelectionView: View {
    let allPlayers: [Player]
    let playerToReplace: Player
    let currentSquad: Squad
    let temporaryBudget: Double
    let onPlayerSelected: (Player) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var filteredPlayers: [Player] {
        var filtered = allPlayers.filter { player in
            // Same position
            player.position == playerToReplace.position &&
            // Not already in squad
            !(currentSquad.players?.contains(where: { $0.id == player.id }) ?? false) &&
            // Can afford
            canAfford(player)
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedStandardContains(searchText)
            }
        }
        
        return filtered.sorted { $0.totalPoints > $1.totalPoints }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if filteredPlayers.isEmpty {
                    ContentUnavailableView(
                        "No Replacements Found",
                        systemImage: "person.3.fill",
                        description: Text("Try adjusting your search or budget.")
                    )
                } else {
                    List {
                        Section("Available Players (\(filteredPlayers.count))") {
                            ForEach(filteredPlayers, id: \.id) { player in
                                Button {
                                    onPlayerSelected(player)
                                    dismiss()
                                } label: {
                                    HStack {
                                        PlayerRowView(player: player)
                                        
                                        Spacer()
                                        
                        
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.tint)
                                            .symbolRenderingMode(.hierarchical)
                                    }
                                }
                                .buttonStyle(.plain)
                                .tint(.green)
                            }
                        }
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
        }
    }
    
    private func canAfford(_ player: Player) -> Bool {
        return (temporaryBudget + playerToReplace.price) >= player.price
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
    
    return NavigationStack {
        TransfersView(
            playerRepository: playerRepo,
            squadRepository: squadRepo,
            viewModel: SquadViewModel(
                squadRepository: squadRepo,
                playerRepository: playerRepo
            )
        )
    }
    .modelContainer(container)
}
