//
//  ContentView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//
import SwiftData
import SwiftUI



struct ContentView: View {
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    let matchdayRepository: MatchdayRepository
    let fixtureRepository: FixtureRepository
    
    // ✅ Create ViewModels here
    @State private var playerViewModel: PlayerViewModel?
    @State private var squadViewModel: SquadViewModel?
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Players tab
            if let playerViewModel = playerViewModel,
               let squadViewModel = squadViewModel {
                PlayersView(
                    viewModel: playerViewModel,
                    playerRepository: playerRepository,
                    squadRepository: squadRepository
                )
                .tabItem {
                    Label("Players", systemImage: "person.3")
                }
                .tag(0)
                
                // My Squad tab
                SquadView(
                    viewModel: squadViewModel,
                    playerRepository: playerRepository,
                    squadRepository: squadRepository
                )
                .tabItem {
                    Label("My Squad", systemImage: "sportscourt")
                }
                .tag(1)
            }
            
            // Fixtures tab
            FixturesListView(
                fixtureRepository: fixtureRepository,
                matchdayRepository: matchdayRepository
            )
            .tabItem {
                Label("Fixtures", systemImage: "calendar")
            }
            .tag(2)
            
            // Leaderboard tab
            LeaderboardView()
                .tabItem {
                    Label("Leaderboard", systemImage: "list.number")
                }
                .tag(3)
        }
        .onAppear {
            if playerViewModel == nil {
                playerViewModel = PlayerViewModel(repository: playerRepository)
            }
            if squadViewModel == nil {
                squadViewModel = SquadViewModel(
                    squadRepository: squadRepository,
                    playerRepository: playerRepository
                )
            }
        }
    }
}

// MARK: - Fixtures List (with @Query)

struct FixturesListView: View {
    let fixtureRepository: FixtureRepository
    let matchdayRepository: MatchdayRepository
    
    // ✅ @Query for fixtures
    @Query(sort: \Fixture.kickoffTime) private var allFixtures: [Fixture]
    
    // ✅ @Query for matchdays
    @Query(sort: \Matchday.number) private var allMatchdays: [Matchday]
    
    var currentMatchday: Matchday? {
        allMatchdays.first { $0.isActive } ?? allMatchdays.first
    }
    
    var fixturesForCurrentMatchday: [Fixture] {
        guard let matchday = currentMatchday else { return [] }
        return allFixtures.filter { $0.matchdayNumber == matchday.number }
    }
    
    var body: some View {
        NavigationStack {
            if fixturesForCurrentMatchday.isEmpty {
                ContentUnavailableView("No fixtures available", systemImage: "calendar.badge.exclamationmark")
            } else {
                List {
                    if let matchday = currentMatchday {
                        Section(header: Text(matchday.name)) {
                            ForEach(fixturesForCurrentMatchday, id: \.id) { fixture in
                                FixtureRowView(fixture: fixture)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Fixtures")
    }
}

struct FixtureRowView: View {
    let fixture: Fixture
    
    var body: some View {
        HStack {
            HStack {
                Text(fixture.homeNation.rawValue)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                AsyncImage(url: URL(string: fixture.homeFlagURL)) {
                    $0.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 24, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 2))
            }
            
            Text(fixture.displayScore)
                .font(.headline)
                .padding(.horizontal, 12)
                .frame(minWidth: 50)
            
            HStack {
                AsyncImage(url: URL(string: fixture.awayFlagURL)) {
                    $0.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 24, height: 16)
                .clipShape(RoundedRectangle(cornerRadius: 2))
                
                Text(fixture.awayNation.rawValue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .font(.subheadline)
        .padding(.vertical, 4)
    }
}

struct LeaderboardView: View {
    var body: some View {
        NavigationStack {
            Text("Leaderboard coming soon")
                .navigationTitle("Leaderboard")
        }
    }
}




// MARK: - Notification Extension
extension Notification.Name {
    static let squadDidUpdate = Notification.Name("squadDidUpdate")
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
        fatalError("Failed to create preview container: \(error)")
    }
    
    let context = container.mainContext
    
    // Seed data

    WorldCupDataSeeder.seedDataIfNeeded(context: context)
    
    // Create repositories
    let playerRepo = SwiftDataPlayerRepository(modelContext: context)
    let squadRepo = SwiftDataSquadRepository(modelContext: context, playerRepository: playerRepo)
    let matchdayRepo = SwiftDataMatchdayRepository(modelContext: context)
    let fixtureRepo = SwiftDataFixtureRepository(modelContext: context)
    
    
    return ContentView(
        playerRepository: playerRepo,
        squadRepository: squadRepo,
        matchdayRepository: matchdayRepo,
        fixtureRepository: fixtureRepo
    )
    .modelContainer(container)
}
