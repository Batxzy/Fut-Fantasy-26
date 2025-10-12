//
//  ContentView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

//
//  ContentView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

import SwiftUI
import SwiftData


struct PlayerListingView: View {
    let playerRepository: PlayerRepository
    @State private var players: [Player] = []
    @State private var isLoading = false
    
    var body: some View {
        content
            .navigationTitle("Players")
            .task {
                if players.isEmpty {
                    await loadPlayers()
                }
            }
    }
    
    // Using @ViewBuilder to construct the view content.
    // This is a more robust pattern and helps the compiler.
    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView("Loading players...")
        } else if players.isEmpty {
            ContentUnavailableView {
                Label("No Players", systemImage: "person.slash")
            } description: {
                Text("Player data will appear here.")
            } actions: {
                Button("Refresh") {
                    Task { await loadPlayers() }
                }
            }
        } else {
            List(players, id: \.id) { player in
                // Assuming PlayerRowView is defined elsewhere and accessible
                PlayerRowView(player: player)
            }
            .refreshable {
                await loadPlayers()
            }
        }
    }
    
    private func loadPlayers() async {
        isLoading = true
        do {
            // Ensure repository methods are async or run them in a background task
            players = try await playerRepository.fetchTopPlayers(limit: 50)
        } catch {
            print("Error loading players: \(error)")
        }
        isLoading = false
    }
}

struct ContentView: View {
    // MARK: - Dependencies
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    let matchdayRepository: MatchdayRepository
    let fixtureRepository: FixtureRepository
    
    // MARK: - State
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Players tab
            PlayersBrowserView(playerRepository: playerRepository)
                .tabItem {
                    Label("Players", systemImage: "person.3")
                }
                .tag(0)
            
            // My Squad tab
            SquadBrowserView(
                squadRepository: squadRepository,
                playerRepository: playerRepository
            )
                .tabItem {
                    Label("My Squad", systemImage: "sportscourt")
                }
                .tag(1)
            
            // Fixtures tab
            FixturesBrowserView(
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
    }
}

// MARK: - Tab Container Views
struct PlayersBrowserView: View {
    let playerRepository: PlayerRepository
    
    var body: some View {
        NavigationStack {
            // This now correctly references the view from PlayerListingView.swift
            PlayerListingView(playerRepository: playerRepository)
        }
    }
}

struct SquadBrowserView: View {
    let squadRepository: SquadRepository
    let playerRepository: PlayerRepository
    
    var body: some View {
        NavigationStack {
            SquadManagementView(
                squadRepository: squadRepository,
                playerRepository: playerRepository
            )
        }
    }
}

struct FixturesBrowserView: View {
    let fixtureRepository: FixtureRepository
    let matchdayRepository: MatchdayRepository
    
    var body: some View {
        NavigationStack {
            FixturesListView(
                fixtureRepository: fixtureRepository,
                matchdayRepository: matchdayRepository
            )
        }
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

// MARK: - Child Views
struct SquadManagementView: View {
    let squadRepository: SquadRepository
    let playerRepository: PlayerRepository
    
    var body: some View {
        Text("Squad management view")
            .navigationTitle("My Squad")
    }
}

struct FixturesListView: View {
    let fixtureRepository: FixtureRepository
    let matchdayRepository: MatchdayRepository
    @State private var fixtures: [Fixture] = []
    @State private var currentMatchday: Matchday?
    @State private var isLoading = true
    
    var body: some View {
        content
            .navigationTitle("Fixtures")
            .task {
                if fixtures.isEmpty {
                    await loadFixtures()
                }
            }
    }
    
    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView("Loading fixtures...")
        } else if fixtures.isEmpty {
            // A simple text view can also be used if ContentUnavailableView gives issues
            Text("No fixtures available")
                .font(.callout)
                .foregroundStyle(.secondary)
        } else {
            List {
                if let matchday = currentMatchday {
                    Section(header: Text(matchday.name)) {
                        ForEach(fixtures, id: \.id) { fixture in
                            FixtureRowView(fixture: fixture)
                        }
                    }
                }
            }
            .refreshable {
                await loadFixtures()
            }
        }
    }
    
    private func loadFixtures() async {
        isLoading = true
        do {
            currentMatchday = try await matchdayRepository.fetchCurrentMatchday()
            if let matchday = currentMatchday {
                fixtures = try await fixtureRepository.fetchFixturesForMatchday(matchday.number)
            }
        } catch {
            print("Error loading fixtures: \(error)")
        }
        isLoading = false
    }
}

struct FixtureRowView: View {
    let fixture: Fixture
    
    var body: some View {
        HStack {
            HStack {
                // Home Team
                Text(fixture.homeNation.rawValue).frame(maxWidth: .infinity, alignment: .trailing)
                AsyncImage(url: URL(string: fixture.homeFlagURL)) { $0.resizable().aspectRatio(contentMode: .fit) } placeholder: { Color.gray.opacity(0.2) }.frame(width: 24, height: 16)
            }
            
            Text(fixture.displayScore).font(.headline).padding(.horizontal, 12)
            
            HStack {
                // Away Team
                AsyncImage(url: URL(string: fixture.awayFlagURL)) { $0.resizable().aspectRatio(contentMode: .fit) } placeholder: { Color.gray.opacity(0.2) }.frame(width: 24, height: 16)
                Text(fixture.awayNation.rawValue).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .font(.subheadline)
        .padding(.vertical, 4)
    }
}

// MARK: - ContentView Preview
#Preview {
    // 1. Get the in-memory preview container
    let container = SwiftDataManager.shared.previewContainer
    
    // 2. Seed the data on the main thread
    MainActor.assumeIsolated {
        let context = ModelContext(container)
        WorldCupDataSeeder.seedDataIfNeeded(context: context)
    }
    
    // 3. Create the context provider and all repositories
    let contextProvider = ModelContextProvider(container: container)
    let playerRepository = PlayerRepository(contextProvider: contextProvider)
    let squadRepository = SquadRepository(contextProvider: contextProvider)
    let matchdayRepository = MatchdayRepository(contextProvider: contextProvider)
    let fixtureRepository = FixtureRepository(contextProvider: contextProvider)
    
    // 4. Instantiate ContentView with the repositories
    return ContentView(
        playerRepository: playerRepository,
        squadRepository: squadRepository,
        matchdayRepository: matchdayRepository,
        fixtureRepository: fixtureRepository
    )
    .modelContainer(container) // Attach the container to the view hierarchy
}
