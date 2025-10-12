//
//  FantasyFootballApp.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import SwiftUI
import SwiftData

import SwiftUI
import SwiftData

@main
struct FantasyFootballApp: App {
    let container = SwiftDataManager.shared.container
    let contextProvider: ModelContextProvider
    
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    let matchdayRepository: MatchdayRepository
    let fixtureRepository: FixtureRepository
    
    init() {
        contextProvider = ModelContextProvider(container: container)
        
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
                print("🚀 [App] Starting data seeding...")
                
                // Seed basic data first
                await seedDataIfNeeded()
                
                // Wait a bit for context to be ready
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                print("🔧 [App] Now seeding squad...")
                
                // Then seed squad
                await seedSquadIfNeeded()
                
                print("✅ [App] All seeding tasks completed!")
            }
        }
    }
    
    @MainActor
    private func seedDataIfNeeded() async {
        let context = contextProvider.createMainContext()
        WorldCupDataSeeder.seedDataIfNeeded(context: context)
    }
    
    @MainActor
    private func seedSquadIfNeeded() async {
        let context = contextProvider.createMainContext()
        await WorldCupDataSeeder.seedSquadIfNeeded(
            squadRepository: squadRepository,
            context: context
        )
    }
}
