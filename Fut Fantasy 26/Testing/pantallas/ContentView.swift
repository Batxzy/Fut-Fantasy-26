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
    
    @State private var playerViewModel: PlayerViewModel?
    @State private var squadViewModel: SquadViewModel?
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // My Squad tab
            if let squadViewModel = squadViewModel {
                SquadView(
                    viewModel: squadViewModel,
                    playerRepository: playerRepository,
                    squadRepository: squadRepository
                )
                .tabItem {
                    Label("My Team", systemImage: "sportscourt")
                }
                .tag(0)
            }
            
            // Earn tab
            EarnView()
                .tabItem {
                    Label("Earn", systemImage: "star.circle.fill")
                }
                .tag(1)
            
            // Scores tab
            ScoresView()
                .tabItem {
                    Label("Scores", systemImage: "trophy.fill")
                }
                .tag(2)
            
            // Profile tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
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
