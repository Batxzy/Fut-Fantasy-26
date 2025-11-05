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
    
    // 1. Define properties as 'let' constants
    let modelContainer: ModelContainer
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    let matchdayRepository: MatchdayRepository
    let fixtureRepository: FixtureRepository
    
    init() {
        // 2. Initialize the container first
        let container = SwiftDataManager.shared.container
        self.modelContainer = container
        
        let context = container.mainContext
        
        // 3. Initialize all repositories in order, resolving dependencies
        // Create playerRepo first
        let playerRepo = SwiftDataPlayerRepository(modelContext: context)
        self.playerRepository = playerRepo
        
        // Now squadRepo can use the playerRepo instance
        self.squadRepository = SwiftDataSquadRepository(
            modelContext: context,
            playerRepository: playerRepo
        )
        
        self.matchdayRepository = SwiftDataMatchdayRepository(modelContext: context)
        self.fixtureRepository = SwiftDataFixtureRepository(modelContext: context)
        
        print("🚀 [App] ModelContainer and Repositories initialized.")
    }
    
    var body: some Scene {
        WindowGroup {
            // 4. Now these are just accessing immutable 'let' constants
            ContentView(
                playerRepository: playerRepository,
                squadRepository: squadRepository,
                matchdayRepository: matchdayRepository,
                fixtureRepository: fixtureRepository
            )
            .modelContainer(modelContainer) // Inject the shared container
            .task {
                print("🚀 [App] Starting data seeding...")
                await seedDataIfNeeded()
                
                await WorldCupDataSeeder.seedSquadIfNeeded(
                    squadRepository: squadRepository,
                    playerRepository: playerRepository,
                    context: modelContainer.mainContext
                )
                
                print("✅ [App] All seeding tasks completed!")
            }
        }
    }
    
    // MARK: - Seeding
    
    @MainActor
    private func seedDataIfNeeded() async {
        let context = modelContainer.mainContext
        WorldCupDataSeeder.seedDataIfNeeded(context: context)
        QuestionSeeder.seedQuestionsIfNeeded(context: context)
        WorldCupDataSeeder.seedFixtures(context: context)
    }
}
