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



import SwiftUI
import SwiftData

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
            PlayersView(
                playerRepository: playerRepository,
                squadRepository: squadRepository
            )
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

struct SquadBrowserView: View {
    let squadRepository: SquadRepository
    let playerRepository: PlayerRepository
    
    var body: some View {
        SquadView(
            squadRepository: squadRepository,
            playerRepository: playerRepository
        )
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

struct FixturesListView: View {
    let fixtureRepository: FixtureRepository
    let matchdayRepository: MatchdayRepository
    @State private var fixtures: [Fixture] = []
    @State private var currentMatchday: Matchday?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
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
        } else if let errorMessage = errorMessage {
            ContentUnavailableView {
                Label("Error", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                Button("Retry") {
                    Task { await loadFixtures() }
                }
            }
        } else if fixtures.isEmpty {
            ContentUnavailableView("No fixtures available", systemImage: "calendar.badge.exclamationmark")
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
        errorMessage = nil
        
        do {
            currentMatchday = try await matchdayRepository.fetchCurrentMatchday()
            if let matchday = currentMatchday {
                fixtures = try await fixtureRepository.fetchFixturesForMatchday(matchday.number)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading fixtures: \(error)")
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
                // Away Team
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

// MARK: - Notification Extension
extension Notification.Name {
    static let squadDidUpdate = Notification.Name("squadDidUpdate")
}

// MARK: - ContentView Preview
#Preview {
    let container = SwiftDataManager.shared.previewContainer
    
    MainActor.assumeIsolated {
        let context = ModelContext(container)
        WorldCupDataSeeder.seedDataIfNeeded(context: context)
    }
    
    let contextProvider = ModelContextProvider(container: container)
    
    // Use protocol types
    let playerRepository: PlayerRepository = SwiftDataPlayerRepository(contextProvider: contextProvider)
    let squadRepository: SquadRepository = SwiftDataSquadRepository(contextProvider: contextProvider)
    let matchdayRepository: MatchdayRepository = SwiftDataMatchdayRepository(contextProvider: contextProvider)
    let fixtureRepository: FixtureRepository = SwiftDataFixtureRepository(contextProvider: contextProvider)
    
    return ContentView(
        playerRepository: playerRepository,
        squadRepository: squadRepository,
        matchdayRepository: matchdayRepository,
        fixtureRepository: fixtureRepository
    )
    .modelContainer(container)
}
