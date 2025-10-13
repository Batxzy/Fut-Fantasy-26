//
//  SwiftDataFixtureRepository.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import SwiftData

@MainActor
final class SwiftDataFixtureRepository: FixtureRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func addFixture(_ fixture: Fixture) async throws {
        print("⚽ [FixtureRepo] Adding fixture")
        modelContext.insert(fixture)
        
        do {
            try modelContext.save()
            print("✅ [FixtureRepo] Fixture saved successfully")
        } catch {
            print("❌ [FixtureRepo] Save failed: \(error)")
            throw RepositoryError.saveFailed(underlyingError: error)
        }
    }
    
    func deleteFixture(_ fixture: Fixture) async throws {
        print("⚽ [FixtureRepo] Deleting fixture")
        modelContext.delete(fixture)
        
        do {
            try modelContext.save()
            print("✅ [FixtureRepo] Fixture deleted successfully")
        } catch {
            print("❌ [FixtureRepo] Delete failed: \(error)")
            throw RepositoryError.deleteFailed(underlyingError: error)
        }
    }
    
    func updateFixtureScore(
        fixtureId: Int,
        homeScore: Int,
        awayScore: Int,
        hadExtraTime: Bool = false,
        hadPenaltyShootout: Bool = false,
        penaltyWinner: Nation? = nil
    ) async throws {
        print("⚽ [FixtureRepo] Updating score for fixture \(fixtureId)")
        
        let predicate = #Predicate<Fixture> { $0.id == fixtureId }
        var descriptor = FetchDescriptor<Fixture>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        guard let fixture = try modelContext.fetch(descriptor).first else {
            print("❌ [FixtureRepo] Fixture not found")
            throw RepositoryError.notFound
        }
        
        fixture.homeScore = homeScore
        fixture.awayScore = awayScore
        fixture.hadExtraTime = hadExtraTime
        fixture.hadPenaltyShootout = hadPenaltyShootout
        fixture.penaltyWinner = penaltyWinner
        fixture.isFinished = true
        
        do {
            try modelContext.save()
            print("✅ [FixtureRepo] Score updated successfully")
        } catch {
            print("❌ [FixtureRepo] Update failed: \(error)")
            throw RepositoryError.updateFailed(underlyingError: error)
        }
    }
}

