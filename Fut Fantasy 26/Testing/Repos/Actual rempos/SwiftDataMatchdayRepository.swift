//
//  SwiftDataMatchdayRepository.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import SwiftData

@MainActor
final class SwiftDataMatchdayRepository: MatchdayRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func addMatchday(_ matchday: Matchday) async throws {
        print("📅 [MatchdayRepo] Adding matchday")
        modelContext.insert(matchday)
        
        do {
            try modelContext.save()
            print("✅ [MatchdayRepo] Matchday added successfully")
        } catch {
            print("❌ [MatchdayRepo] Add failed: \(error)")
            throw RepositoryError.saveFailed(underlyingError: error)
        }
    }
    
    func updateMatchday(_ matchday: Matchday) async throws {
        print("📅 [MatchdayRepo] Updating matchday")
        
        do {
            try modelContext.save()
            print("✅ [MatchdayRepo] Matchday updated successfully")
        } catch {
            print("❌ [MatchdayRepo] Update failed: \(error)")
            throw RepositoryError.updateFailed(underlyingError: error)
        }
    }
    
    func activateMatchday(number: Int) async throws {
        print("📅 [MatchdayRepo] Activating matchday \(number)")
        
        // Fetch all matchdays
        let allMatchdays = try modelContext.fetch(FetchDescriptor<Matchday>())
        
        // Deactivate all
        for md in allMatchdays {
            md.isActive = false
        }
        
        // Activate the selected one
        let predicate = #Predicate<Matchday> { $0.number == number }
        var descriptor = FetchDescriptor<Matchday>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        guard let matchday = try modelContext.fetch(descriptor).first else {
            print("❌ [MatchdayRepo] Matchday not found")
            throw RepositoryError.notFound
        }
        
        matchday.isActive = true
        
        do {
            try modelContext.save()
            print("✅ [MatchdayRepo] Matchday activated successfully")
        } catch {
            print("❌ [MatchdayRepo] Activation failed: \(error)")
            throw RepositoryError.updateFailed(underlyingError: error)
        }
    }
    
    func completeMatchday(number: Int) async throws {
        print("📅 [MatchdayRepo] Completing matchday \(number)")
        
        let predicate = #Predicate<Matchday> { $0.number == number }
        var descriptor = FetchDescriptor<Matchday>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        guard let matchday = try modelContext.fetch(descriptor).first else {
            print("❌ [MatchdayRepo] Matchday not found")
            throw RepositoryError.notFound
        }
        
        matchday.isFinished = true
        matchday.isActive = false
        
        // Activate next matchday if available
        let nextNumber = number + 1
        let nextPredicate = #Predicate<Matchday> { $0.number == nextNumber }
        var nextDescriptor = FetchDescriptor<Matchday>(predicate: nextPredicate)
        nextDescriptor.fetchLimit = 1
        
        if let nextMatchday = try modelContext.fetch(nextDescriptor).first {
            nextMatchday.isActive = true
            print("✅ [MatchdayRepo] Next matchday activated")
        }
        
        do {
            try modelContext.save()
            print("✅ [MatchdayRepo] Matchday completed successfully")
        } catch {
            print("❌ [MatchdayRepo] Completion failed: \(error)")
            throw RepositoryError.updateFailed(underlyingError: error)
        }
    }
}

