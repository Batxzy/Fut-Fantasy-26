//
//  SquadView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

import SwiftUI
import SwiftData

enum PlayerSlot: Equatable, Hashable {
    case starting(Player)
    case bench(Player)
}

struct SquadView: View {
   
    
    @Query private var squads: [Squad]
    
    @Bindable var viewModel: SquadViewModel
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    
    @State private var isEditMode = false
    @State private var showingCaptainSelection = false
    @State private var selectedSlot: PlayerSlot?
    
    var squad: Squad? {
        squads.first
    }
    
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.1, green: 0.14, blue: 0.49)
                    .ignoresSafeArea()
                
               
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
                            isEditMode.toggle()
                            if !isEditMode {
                                selectedSlot = nil
                            }
                        } label: {
                            Image(systemName: isEditMode ? "pencil.circle.fill" : "pencil.circle")
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(isEditMode ? .green : .primary)
                                .font(.title3)
                                .symbolEffect(.bounce, value: isEditMode)
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
                                .symbolRenderingMode(.hierarchical)
                                .font(.title3)
                        }
                    }
                }
            }
            .toolbarBackground(.automatic, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
    
    private func squadContent(squad: Squad) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                ZStack(alignment: .top) {
                    FormationView(
                        startingXI: squad.startingXI ?? [],
                        captain: squad.captain,
                        viceCaptain: squad.viceCaptain,
                        isEditMode: isEditMode,
                        selectedSlot: $selectedSlot,
                        isPlayerTappable: isPlayerTappable,
                        onPlayerTap: handlePlayerTap,
                        playerRepository: playerRepository,
                        squadRepository: squadRepository
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 80)
                    .animation(.bouncy(duration: 0.75), value: squad.startingXI?.map { $0.id })
                    
                    VStack(spacing: 0) {
                        LinearGradient(
                            stops: [
                                Gradient.Stop(color:.bgBlue, location: 0.00),
                                Gradient.Stop(color: .bgBlue.opacity(0), location: 1.00),
                            ],
                            startPoint: UnitPoint(x: 0.5, y: 0),
                            endPoint: UnitPoint(x: 0.5, y: 1)
                        )
                        .frame(height: 190)
                        
                        Spacer()
                    }
                    .allowsHitTesting(false)
                    
                    squadHeader(squad: squad)
                }
             
                BenchView(
                    benchPlayers: squad.bench ?? [],
                    isEditMode: isEditMode,
                    startingXICount: squad.startingXI?.count ?? 0,
                    selectedSlot: $selectedSlot,
                    isPlayerTappable: isPlayerTappable,
                    onPlayerTap: handlePlayerTap,
                    playerRepository: playerRepository,
                    squadRepository: squadRepository
                )
                .animation(.bouncy(duration: 0.75), value: squad.bench?.map { $0.id })
                
                Button(action: {
                    showingCaptainSelection = true
                }) {
                    Text("Set Captain & Vice-Captain")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.black)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.wpMint)
                .cornerRadius(16)
                .padding(.horizontal, 38)
            }
        }
        .scrollContentBackground(.hidden)
    }
    
    private func squadHeader(squad: Squad) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Players")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.white)
                Text("\(squad.players?.count ?? 0)/15")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Budget")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.white)
                
                HStack(spacing: 3) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.white)
                    
                    Text(squad.displayBudgetNoDecimals)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 2)
        .padding(.top,12)
    }
    
    // MARK: - Tap and Swap Logic
    
    private func handlePlayerTap(on tappedSlot: PlayerSlot) {
        guard isEditMode else { return }

        if !isPlayerTappable(slot: tappedSlot) {
            return
        }

        if selectedSlot == tappedSlot {
            selectedSlot = nil
            return
        }

        guard let firstSlot = selectedSlot else {
            selectedSlot = tappedSlot
            return
        }
        
        let secondSlot = tappedSlot
        
        Task {
            guard let squadId = squad?.id else { return }
            await viewModel.swapPlayers(firstSlot, secondSlot, squadId: squadId)
            selectedSlot = nil
        }
    }
    
    private func isPlayerTappable(slot: PlayerSlot) -> Bool {
        guard let selected = selectedSlot else {
            return true
        }
        
        if selected == slot {
            return true
        }

        let selectedPlayer: Player
        switch selected {
        case .starting(let p): selectedPlayer = p
        case .bench(let p): selectedPlayer = p
        }

        let targetPlayer: Player
        switch slot {
        case .starting(let p): targetPlayer = p
        case .bench(let p): targetPlayer = p
        }

        switch (selected, slot) {
        case (.starting, .starting):
            return selectedPlayer.position == targetPlayer.position
        
        case (.starting, .bench), (.bench, .starting):
            return selectedPlayer.position == targetPlayer.position
            
        case (.bench, .bench):
            return false
        }
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
    
    let squad = Squad(teamName: "Batxzy's Dream Team", ownerName: "Batxzy")
    context.insert(squad)
    
    let fetchDescriptor = FetchDescriptor<Player>(
        sortBy: [SortDescriptor(\.totalPoints, order: .reverse)]
    )
    
    if let allPlayers = try? context.fetch(fetchDescriptor) {
        let goalkeepers = allPlayers.filter { $0.position == .goalkeeper }.prefix(2)
        let defenders = allPlayers.filter { $0.position == .defender }.prefix(5)
        let midfielders = allPlayers.filter { $0.position == .midfielder }.prefix(5)
        let forwards = allPlayers.filter { $0.position == .forward }.prefix(3)
        
        var selectedPlayers: [Player] = []
        selectedPlayers.append(contentsOf: goalkeepers)
        selectedPlayers.append(contentsOf: defenders)
        selectedPlayers.append(contentsOf: midfielders)
        selectedPlayers.append(contentsOf: forwards)
        
        squad.players = Array(selectedPlayers.prefix(15))
        
        if selectedPlayers.count >= 11 {
            let gk = Array(goalkeepers.prefix(1))
            let def = Array(defenders.prefix(4))
            let mid = Array(midfielders.prefix(5))
            let fwd = Array(forwards.prefix(1))
            
            squad.startingXIIDs = [
                gk.map { $0.id },
                def.map { $0.id },
                mid.map { $0.id },
                fwd.map { $0.id }
            ]
            
            let startingIDs = Set(gk.map { $0.id } + def.map { $0.id } + mid.map { $0.id } + fwd.map { $0.id })
            squad.benchIDs = selectedPlayers.filter { !startingIDs.contains($0.id) }.prefix(4).map { $0.id }
            
            if let captain = fwd.first {
                squad.captain = captain
            }
            if let viceCaptain = mid.first {
                squad.viceCaptain = viceCaptain
            }
        }
    }
    
    try? context.save()
    
    return SquadView(
        viewModel: SquadViewModel(squadRepository: squadRepo, playerRepository: playerRepo),
        playerRepository: playerRepo,
        squadRepository: squadRepo
    )
    .modelContainer(container)
}







struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var featuredFixtures: [Fixture] = []
    @State private var currentIndex: Int = 0
    
    // Array of background images
    private let backgroundImages = ["Home 7", "Home 8", "Home 6"]
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background color
            Color.mainBg
                .ignoresSafeArea()
            
            // Background image - changes based on current fixture
            Image(backgroundImages[currentIndex])
                .resizable()
                .scaledToFit()
                .frame(height: 560)
                .ignoresSafeArea()
                .transition(.opacity)
                .id(currentIndex) // Force view update on index change
            
            VStack(spacing: 20) {
                // Spacer for image
                Color.clear
                    .frame(height: 420)
                
                
                VStack(spacing:20){
                    if !featuredFixtures.isEmpty {
                        FixtureCarouselView(
                            fixtures: featuredFixtures,
                            currentIndex: $currentIndex
                        )
                    } else {
                        Text("No fixtures available")
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Button(action: {
                        print("")
                    }) {
                        Text("pick your team")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Color.wpMint)
                    .cornerRadius(16)
                    .padding(.horizontal, 38)
                    
                }
            }
        }
        .onAppear {
            createFeaturedFixtures()
        }
    }
    
    private func createFeaturedFixtures() {
        // Only create if not already created
        guard featuredFixtures.isEmpty else { return }
        
        // Create 3 featured fixtures (not saved to database)
        let fixture1 = Fixture(
            id: 9001, // High ID to avoid conflicts
            matchdayNumber: 2,
            homeNation: .argentina,
            awayNation: .germany,
            kickoffTime: Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date(),
            group: .a
        )
        
        let fixture2 = Fixture(
            id: 9002,
            matchdayNumber: 2,
            homeNation: .brazil,
            awayNation: .usa,
            kickoffTime: Calendar.current.date(byAdding: .hour, value: 9, to: Date()) ?? Date(),
            group: .g
        )
        
        let fixture3 = Fixture(
            id: 9003,
            matchdayNumber: 2,
            homeNation: .england,
            awayNation: .mexico,
            kickoffTime: Calendar.current.date(byAdding: .hour, value: 12, to: Date()) ?? Date(),
            group: .b
        )
        
        featuredFixtures = [fixture1, fixture2, fixture3]
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Fixture.self,
        configurations: config
    )
    
    return HomeView()
        .modelContainer(container)
}



struct FixtureCarouselView: View {
    let fixtures: [Fixture]
    @Binding var currentIndex: Int

    var body: some View {
        HStack(spacing: -20) {
            // Left arrow button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if currentIndex > 0 {
                        currentIndex -= 1
                    } else {
                        currentIndex = fixtures.count - 1
                    }
                }
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 32, height: 32)
                    .background(Color.wpMint)
                    .clipShape(Circle())
            }
            .zIndex(2)
            
            // Main fixture card
            
            
            if let fixture = fixtures[safe: currentIndex] {
                FixtureCardView(fixture: fixture)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(currentIndex)
            }
            
            // Right arrow button
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if currentIndex < fixtures.count - 1 {
                        currentIndex += 1
                    } else {
                        currentIndex = 0
                    }
                }
            } label: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 32, height: 32)
                    .background(Color.wpMint)
                    .clipShape(Circle())
            }
            
        }
    }
}

struct FixtureCardView: View {
    let fixture: Fixture
    
    var body: some View {
        
            
            VStack(spacing: 0) {
                // Time and round info
                VStack(spacing: 8) {
                    Text(fixture.formattedKickoffTime)
                        .textStyle(.body)
                        .foregroundColor(.white)
                    
                    Text(fixture.roundInfo)
                        .textStyle(.caption)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text(fixture.groupInfo)
                        .textStyle(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                
                // Teams and VS
                HStack {
                    VStack(alignment: .center, spacing: 8) {
                        AsyncImage(url: URL(string: fixture.homeFlagURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Color.black, lineWidth: 1)
                        }
                        
                        Text(fixture.homeNation.rawValue)
                            .textStyle(.body, weight: .bold)
                            .foregroundColor(.white)
                    }
                    .frame(width: 80)
                    
                    Spacer()
                    
                    Text(fixture.displayScore)
                        .textStyle(.h1, weight: .bold)
                        .foregroundColor(.wpMint)
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 8) {
                        AsyncImage(url: URL(string: fixture.awayFlagURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .stroke(Color.black, lineWidth: 1)
                        }
                        
                        Text(fixture.awayNation.rawValue)
                            .textStyle(.body, weight: .bold)
                            .foregroundColor(.white)
                    }
                    .frame(width:100)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                
            }
            .padding()
        .frame(width: 350)
        
        .background(.wpBlueDeep)
        .clipShape(RoundedRectangle(cornerRadius: 30))
    }
}

// Extension for safe array access
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Extension to Fixture for formatted display
extension Fixture {
    var formattedKickoffTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "Today, \(formatter.string(from: kickoffTime)) h"
    }
    
    var roundInfo: String {
        if let stage = knockoutStage {
            switch stage {
            case .roundOf16: return "Round of 16"
            case .quarterFinals: return "Quarter Finals"
            case .semiFinals: return "Semi Finals"
            case .thirdPlace: return "Third Place"
            case .final: return "Final"
            default: return "Group Stage"
            }
        }
        return "Group Stage - Matchday \(matchdayNumber)"
    }
    
    var groupInfo: String {
        if let group = group {
            return group.rawValue.uppercased()
        }
        return ""
    }
}
