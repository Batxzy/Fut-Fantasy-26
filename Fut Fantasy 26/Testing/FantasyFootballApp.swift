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
    // Single source of truth for the data container and context provider
    let dataManager: SwiftDataManager
    let contextProvider: ModelContextProvider
    
    // Repositories are now properties of the App
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    let matchdayRepository: MatchdayRepository
    let fixtureRepository: FixtureRepository
    
    init() {
        // 1. Initialize data manager and context provider
        self.dataManager = SwiftDataManager.shared
        self.contextProvider = ModelContextProvider(container: dataManager.container)
        
        // 2. Create a shared main context
        let mainContext = contextProvider.mainContext
        
        // 3. Initialize repositories with the shared context
        // Note: Repositories that depend on other repositories must be initialized in order.
        self.playerRepository = SwiftDataPlayerRepository(modelContext: mainContext)
        self.matchdayRepository = SwiftDataMatchdayRepository(modelContext: mainContext)
        self.fixtureRepository = SwiftDataFixtureRepository(modelContext: mainContext)
        
        // SquadRepository depends on PlayerRepository, so we inject it.
        self.squadRepository = SwiftDataSquadRepository(
            modelContext: mainContext,
            playerRepository: self.playerRepository
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                playerRepository: playerRepository,
                squadRepository: squadRepository,
                matchdayRepository: matchdayRepository,
                fixtureRepository: fixtureRepository
            )
            .modelContainer(dataManager.container)
            .task {
                print("🚀 [App] Starting data seeding...")
                // Pass the shared context to the seeder
                await seedDataIfNeeded(context: contextProvider.mainContext)
                
                // Then seed the squad using the repositories
                await seedSquadIfNeeded()
                print("✅ [App] All seeding tasks completed!")
            }
        }
    }
    
    @MainActor
    private func seedDataIfNeeded(context: ModelContext) async {
        WorldCupDataSeeder.seedDataIfNeeded(context: context)
    }
    
    @MainActor
    private func seedSquadIfNeeded() async {
        // Pass the already initialized repositories to the seeder
        await WorldCupDataSeeder.seedSquadIfNeeded(
            squadRepository: squadRepository,
            playerRepository: playerRepository,
            context: contextProvider.mainContext
        )
    }
}
