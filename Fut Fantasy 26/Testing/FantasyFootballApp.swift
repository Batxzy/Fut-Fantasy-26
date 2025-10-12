//
//  FantasyFootballApp.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import SwiftUI
import SwiftData

@main
struct FantasyFootballApp: App {
    let container = SwiftDataManager.shared.container
    let contextProvider: ModelContextProvider
    
    // Use protocol types for repositories
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    let matchdayRepository: MatchdayRepository
    let fixtureRepository: FixtureRepository
    
    init() {
        contextProvider = ModelContextProvider(container: container)
        
        // Initialize with concrete implementations
        playerRepository = SwiftDataPlayerRepository(contextProvider: contextProvider)
        squadRepository = SwiftDataSquadRepository(contextProvider: contextProvider)
        matchdayRepository = SwiftDataMatchdayRepository(contextProvider: contextProvider)
        fixtureRepository = SwiftDataFixtureRepository(contextProvider: contextProvider)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                playerRepository: playerRepository,
                squadRepository: squadRepository,
                matchdayRepository: matchdayRepository,
                fixtureRepository: fixtureRepository
            )
            .modelContainer(container)
            .task {
                await seedDataIfNeeded()
            }
        }
    }
    
    @MainActor
    private func seedDataIfNeeded() async {
        let context = contextProvider.createMainContext()
        WorldCupDataSeeder.seedDataIfNeeded(context: context)
    }
}
