//
//  PlayerDetailView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 13/10/25.
//
 import SwiftData
 import SwiftUI

// MARK: - Actions



struct PlayerDetailView: View {
    
    let player: Player
    @Bindable var viewModel: PlayerViewModel
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    
    @Query private var squads: [Squad]
    
    @State private var showingAddConfirmation = false
    @State private var showValidationError = false  // ✅ ADD THIS
    @State private var validationErrorMessage = ""
    
    var currentSquad: Squad? {
        squads.first
    }
    
    var isInSquad: Bool {
        currentSquad?.players?.contains(where: { $0.id == player.id }) ?? false
    }
    
    private func addPlayerToSquad() async {
        guard let squad = currentSquad else { return }
        
        if squad.isFull {
            validationErrorMessage = "Squad is full. You have 15/15 players. Remove a player to add \(player.name)."
            showValidationError = true
            return
        }
        
        if !squad.canAddPlayer(position: player.position) {
            let posLimit = player.position.squadLimit
            validationErrorMessage = "You already have \(posLimit) \(player.position.fullName)s in your squad (maximum allowed). Remove one to add \(player.name)."
            showValidationError = true
            return
        }
        
        if squad.currentBudget < player.price {
            let shortfall = player.price - squad.currentBudget
            validationErrorMessage = "Insufficient budget. \(player.name) costs \(player.displayPrice) but you only have £\(squad.displayBudget) remaining. You need £\(String(format: "%.1f", shortfall))M more."
            showValidationError = true
            return
        }
        
        let totalStarting = squad.startingXI?.count ?? 0
        if totalStarting < 11 {
            let currentInStarting = squad.startingPlayerCount(for: player.position)
            
            let maxInStarting: Int
            let positionName: String
            switch player.position {
            case .goalkeeper:
                maxInStarting = 1
                positionName = "Goalkeeper"
            case .defender:
                maxInStarting = 4
                positionName = "Defender"
            case .midfielder:
                maxInStarting = 3
                positionName = "Midfielder"
            case .forward:
                maxInStarting = 3
                positionName = "Forward"
            }
            
            if currentInStarting >= maxInStarting {
                let benchCount = squad.bench?.count ?? 0
                if benchCount >= 4 {
                    validationErrorMessage = "Cannot add \(player.name). Your starting XI already has \(maxInStarting) \(positionName)s (formation 1-4-3-3) and your bench is full (4/4). Remove a player first."
                    showValidationError = true
                    return
                }
                print("ℹ️ [PlayerDetail] \(player.name) will be added to bench (starting XI position full)")
            }
        } else {
            let benchCount = squad.bench?.count ?? 0
            if benchCount >= 4 {
                validationErrorMessage = "Cannot add \(player.name). Your starting XI (1-4-3-3) is complete and your bench is full (4/4). Remove a player first."
                showValidationError = true
                return
            }
        }
        
        // Validation 5: Nation limit
        let currentStage: TournamentStage = .groupStage
        if !squad.canAddPlayerFromNation(player.nation, stage: currentStage) {
            let maxAllowed = currentStage.maxPlayersPerNation
            let currentCount = squad.playersFromNation(player.nation)
            validationErrorMessage = "Cannot add \(player.name). You already have \(currentCount) players from \(player.nation.rawValue). Maximum \(maxAllowed) players per nation allowed during \(currentStage.rawValue)."
            showValidationError = true
            return
        }
        
        // All validations passed - add player
        do {
            try await squadRepository.addPlayerToSquad(playerId: player.id, squadId: squad.id)
            print("✅ [PlayerDetail] Player added successfully")
        } catch {
            validationErrorMessage = "Failed to add player: \(error.localizedDescription)"
            showValidationError = true
            print("❌ [PlayerDetail] Failed to add player: \(error)")
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.mainBg)
                .ignoresSafeArea()
            
            ScrollView {
                ZStack(alignment: .top) {
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
                    .frame(height: 200)
                    
                    GeometryReader { geometry in
                        let minY = geometry.frame(in: .global).minY
                        
                        VStack(spacing: 0) {
                            LinearGradient(
                                stops: [
                                    Gradient.Stop(color: .mainBg.opacity(0), location: 0.00),
                                    Gradient.Stop(color: .mainBg.opacity(0), location: 0.7),
                                    Gradient.Stop(color: .mainBg, location: 1.00),
                                ],
                                startPoint: UnitPoint(x: 0.5, y: 0),
                                endPoint: UnitPoint(x: 0.5, y: 1)
                            )
                            .frame(height: 200)
                            
                            Color.mainBg
                        }
                        .offset(y: -minY - 1)
                    }
                    .allowsHitTesting(false)
                    
                    VStack(spacing: 20) {
                        Color.clear.frame(height: 140)
                        
                        playerHeader
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(.grayBg.opacity(0.8))
                            .padding(.horizontal, 20)
                        
                        statsSection
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
            
            actionButton
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        
        .alert("Add \(player.name)?", isPresented: $showingAddConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Add", role: .none) {
                Task {
                    await addPlayerToSquad()
                }
            }
        } message: {
            Text("Add \(player.name) to your squad for \(player.displayPrice)?")
        }
        .alert("Cannot Add Player", isPresented: $showValidationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationErrorMessage)
        }
    }
    
    // MARK: - View Components
    
    private var playerHeader: some View {
        
        HStack(spacing:10){
            
            Image(player.imageURL)
                .resizable()
                .padding(.top,3)
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .background(.white)
                .clipShape(Circle())


            VStack(alignment: .center){
                HStack(spacing: 12){
                    Rectangle()
                        .foregroundStyle(Color.wpAqua)
                        .frame(width: 2, height: 38)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 5) {
                            Text(player.name)
                                .font(Font.custom("SF Compact", size: 18))
                                .lineLimit(1)
                                .minimumScaleFactor(0.95)
                            
                            HStack(spacing: 3) {
                                Image(systemName: "star.circle.fill")
                                    .foregroundStyle(Color.wpAqua)
                                
                                Text(String(format: "%.0fM", player.price))
                                    .font(Font.custom("SF Compact", size: 15))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Text(player.position.rawValue)
                                .font(.caption.bold())
                                .foregroundStyle(player.position == .goalkeeper ? .black : .white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background {
                                    Capsule()
                                        .fill(player.position.displayColor)
                                }
                            
                            Text(player.nationName)
                                .font(Font.custom("SF Compact", size: 15))
                                .foregroundColor(.white.opacity(0.68))
                        }
                    }
                }
            }
            .padding(10)
            .padding(.bottom ,5)
            .frame(height: 100, alignment: .bottom)
            
            
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        if let squad = currentSquad {
            if isInSquad {
                Text("In Squad")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.wpGreenLime)
                    .cornerRadius(16)
                    .padding(.horizontal, 38)
            } else if squad.isFull {
                Text("Squad Full (15/15)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.wpRedOrange)
                    .cornerRadius(16)
                    .padding(.horizontal, 38)
            } else if !squad.canAddPlayer(position: player.position) {
                Text("\(player.position.fullName) Limit Reached (\(player.position.squadLimit)/\(player.position.squadLimit))")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.wpRedOrange)
                    .cornerRadius(16)
                    .padding(.horizontal, 38)
            } else if squad.currentBudget < player.price {
                Text("Can't Afford (£\(squad.displayBudget) left)")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.wpRedDark)
                    .cornerRadius(16)
                    .padding(.horizontal, 38)
            } else if !canAddToStartingOrBench(player: player, squad: squad) {
                Text("\(player.position.fullName) Spots Full")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.wpRedOrange)
                    .cornerRadius(16)
                    .padding(.horizontal, 38)
            } else if !canAddPlayerNation(player: player, squad: squad) {
                Text("\(player.nation.rawValue) Limit Reached")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.wpPurpleOrchid)
                    .cornerRadius(16)
                    .padding(.horizontal, 38)
            } else {
                Button {
                       showingAddConfirmation = true
                   } label: {
                       HStack(spacing: 5) {
                           Text("Buy for \(String(format: "%.0fM", player.price))")
                               .font(.system(size: 20, weight: .semibold))
                               .foregroundStyle(.black)
                           
                           Image(systemName: "star.circle.fill")
                               .foregroundStyle(.black)
                       }
                   }
                   .frame(maxWidth: .infinity)
                   .frame(height: 40)
                   .background(Color.wpMint)
                   .cornerRadius(16)
                   .padding(.horizontal, 38)
            }
        } else {
            Text("No Squad Available")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.wpBlueSky.opacity(0.5))
                .cornerRadius(16)
                .padding(.horizontal, 38)
        }
    }
    
    // MARK: - Helper Functions

    private func canAddToStartingOrBench(player: Player, squad: Squad) -> Bool {
        let totalStarting = squad.startingXI?.count ?? 0
        
        if totalStarting < 11 {
            let currentInStarting = squad.startingPlayerCount(for: player.position)
            
           
            let maxInStarting: Int
            switch player.position {
            case .goalkeeper: maxInStarting = 1
            case .defender: maxInStarting = 4
            case .midfielder: maxInStarting = 3
            case .forward: maxInStarting = 3
            }
            
            if currentInStarting >= maxInStarting {
                let benchCount = squad.bench?.count ?? 0
                return benchCount < 4
            }
            
            return true
        } else {
            let benchCount = squad.bench?.count ?? 0
            return benchCount < 4
        }
    }

    private func canAddPlayerNation(player: Player, squad: Squad) -> Bool {
        let currentStage: TournamentStage = .groupStage
        return squad.canAddPlayerFromNation(player.nation, stage: currentStage)
    }
    
    private var statsSection: some View {
        
        VStack(alignment: .leading, spacing: 12){
            
            Text("stats")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                StatRow(label: "Total Points", value: "\(player.totalPoints)")
                Divider()
                StatRow(label: "Matchday Points", value: "\(player.matchdayPoints)")
                Divider()
                StatRow(label: "Price", value: player.displayPriceNoDecimals,)
                Divider()
                StatRow(label: "Appearances", value: "\(player.appearances)")
            }
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
        }
        
        
    }
    
    private var infoSection: some View {
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
    }
}

// MARK: - Preview
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
        PlayerDetailView(
            player: MockData.messi,
            viewModel: PlayerViewModel(repository: playerRepo),
            playerRepository: playerRepo,
            squadRepository: squadRepo
        )
    }
    .modelContainer(container)
}

extension Player {
    var displayPriceNoDecimals: String {
        return String(format: "$%.0fM", price)
    }
}

struct buttonBottom : View {
    
    var body : some View {
        Text("Hello, World!")
    }
}

#Preview{
    
}
