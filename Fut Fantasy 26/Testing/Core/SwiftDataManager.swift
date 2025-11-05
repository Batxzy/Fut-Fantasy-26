//
//  SwiftDataManager.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import SwiftUI
import SwiftData

// Central manager for SwiftData configuration
class SwiftDataManager {
    static let shared = SwiftDataManager()
    
    // MARK: - Schema Configuration
    
    lazy var schema: Schema = {
        Schema([
            Player.self,
            Squad.self,
            Matchday.self,
            MatchdayPerformance.self,
            MatchdaySquad.self,
            Transfer.self,
            Fixture.self,
            TeamStandings.self,
            UserQuestionProgress.self,
            Prediction.self
        ])
    }()
    
    // MARK: - Container Configuration
    
    lazy var container: ModelContainer = {
        let configuration = ModelConfiguration(
            schema: schema,
            url: URL.documentsDirectory.appending(path: "WorldCupFantasy.store")
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            return container
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
    
    // Preview container for SwiftUI previews and testing
    lazy var previewContainer: ModelContainer = {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }()
}
