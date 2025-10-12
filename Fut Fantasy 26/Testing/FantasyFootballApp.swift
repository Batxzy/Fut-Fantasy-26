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
    // SwiftData setup
    let container = SwiftDataManager.shared.container
    let contextProvider: ModelContextProvider
    
    // Repositories
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    let matchdayRepository: MatchdayRepository
    let fixtureRepository: FixtureRepository
    
    init() {
        // Initialize context provider
        contextProvider = ModelContextProvider(container: container)
        
        // Initialize repositories
        playerRepository = PlayerRepository(contextProvider: contextProvider)
        squadRepository = SquadRepository(contextProvider: contextProvider)
        matchdayRepository = MatchdayRepository(contextProvider: contextProvider)
        fixtureRepository = FixtureRepository(contextProvider: contextProvider)
        
        // --- REMOVED THE TASK FROM THE INITIALIZER ---
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
            // --- ADD THE .task MODIFIER HERE ---
            // This task runs automatically when the view appears.
            .task {
                await seedDataIfNeeded()
            }
        }
    }
    
    @MainActor
    private func seedDataIfNeeded() async {
        // Get a context for seeding
        let context = contextProvider.createMainContext()
        
        // Use the provided seeder class
        WorldCupDataSeeder.seedDataIfNeeded(context: context)
    }
}
