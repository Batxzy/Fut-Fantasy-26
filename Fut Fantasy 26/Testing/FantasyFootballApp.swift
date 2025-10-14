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
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Player.self,
                Squad.self,
                Matchday.self,
                MatchdayPerformance.self,
                MatchdaySquad.self,
                Transfer.self,
                Fixture.self
            ])
            
            let configuration = ModelConfiguration(
                schema: schema,
                url: URL.documentsDirectory.appending(path: "WorldCupFantasy.store")
            )
            
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                playerRepository: createPlayerRepository(),
                squadRepository: createSquadRepository(),
                matchdayRepository: createMatchdayRepository(),
                fixtureRepository: createFixtureRepository()
            )
            .modelContainer(modelContainer)
            .task {
                print("🚀 [App] Starting data seeding...")
                await seedDataIfNeeded()
                
                // Fix this line with the proper function call
                await WorldCupDataSeeder.seedSquadIfNeeded(
                    squadRepository: createSquadRepository(),
                    playerRepository: createPlayerRepository(),
                    context: modelContainer.mainContext
                )
                
                print("✅ [App] All seeding tasks completed!")
            }
        }
    }
    
    // MARK: - Repository Factory Methods
    
    private func createPlayerRepository() -> PlayerRepository {
        SwiftDataPlayerRepository(modelContext: modelContainer.mainContext)
    }
    
    private func createSquadRepository() -> SquadRepository {
        SwiftDataSquadRepository(
            modelContext: modelContainer.mainContext,
            playerRepository: createPlayerRepository()
        )
    }
    
    private func createMatchdayRepository() -> MatchdayRepository {
        SwiftDataMatchdayRepository(modelContext: modelContainer.mainContext)
    }
    
    private func createFixtureRepository() -> FixtureRepository {
        SwiftDataFixtureRepository(modelContext: modelContainer.mainContext)
    }
    
    // MARK: - Seeding
    
    @MainActor
    private func seedDataIfNeeded() async {
        WorldCupDataSeeder.seedDataIfNeeded(context: modelContainer.mainContext)
    }
    /*
    @MainActor
    private func seedSquadIfNeeded() async {
        await WorldCupDataSeeder.seedSquadIfNeeded(
            squadRepository: createSquadRepository(),
            playerRepository: createPlayerRepository(),
            context: modelContainer.mainContext
        )
    }
     */
}
