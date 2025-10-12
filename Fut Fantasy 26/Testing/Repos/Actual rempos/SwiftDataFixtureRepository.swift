//
//  SwiftDataFixtureRepository.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


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
    private let baseRepository: BaseRepository<Fixture>
    
    init(contextProvider: ModelContextProvider) {
        self.baseRepository = BaseRepository<Fixture>(contextProvider: contextProvider)
    }
    
    func fetchFixtureById(_ id: Int) async throws -> Fixture? {
        print("⚽ [FixtureRepo] Fetching fixture with ID: \(id)")
        
        let predicate = #Predicate<Fixture> { $0.id == id }
        
        do {
            let fixture = try await baseRepository.fetchOne(with: predicate)
            if fixture != nil {
                print("✅ [FixtureRepo] Found fixture")
            } else {
                print("⚠️ [FixtureRepo] Fixture not found")
            }
            return fixture
        } catch {
            print("❌ [FixtureRepo] Fetch failed: \(error)")
            throw error
        }
    }
    
    func fetchFixturesForMatchday(_ matchdayNumber: Int) async throws -> [Fixture] {
        print("⚽ [FixtureRepo] Fetching fixtures for matchday \(matchdayNumber)")
        
        let predicate = #Predicate<Fixture> { $0.matchdayNumber == matchdayNumber }
        
        do {
            let fixtures = try await baseRepository.fetch(
                with: predicate,
                sortBy: [SortDescriptor(\.kickoffTime)]
            )
            print("✅ [FixtureRepo] Fetched \(fixtures.count) fixtures")
            return fixtures
        } catch {
            print("❌ [FixtureRepo] Fetch failed: \(error)")
            throw error
        }
    }
    
    func fetchFixturesForNation(_ nation: Nation) async throws -> [Fixture] {
        print("⚽ [FixtureRepo] Fetching fixtures for nation: \(nation.rawValue)")
        
        let predicate = #Predicate<Fixture> {
            $0.homeNation == nation || $0.awayNation == nation
        }
        
        do {
            let fixtures = try await baseRepository.fetch(
                with: predicate,
                sortBy: [SortDescriptor(\.kickoffTime)]
            )
            print("✅ [FixtureRepo] Fetched \(fixtures.count) fixtures")
            return fixtures
        } catch {
            print("❌ [FixtureRepo] Fetch failed: \(error)")
            throw error
        }
    }
    
    func fetchFixturesForGroup(_ group: WorldCupGroup) async throws -> [Fixture] {
        print("⚽ [FixtureRepo] Fetching fixtures for group: \(group.rawValue)")
        
        let predicate = #Predicate<Fixture> { $0.group == group }
        
        do {
            let fixtures = try await baseRepository.fetch(
                with: predicate,
                sortBy: [SortDescriptor(\.kickoffTime)]
            )
            print("✅ [FixtureRepo] Fetched \(fixtures.count) fixtures")
            return fixtures
        } catch {
            print("❌ [FixtureRepo] Fetch failed: \(error)")
            throw error
        }
    }
    
    func fetchUpcomingFixtures(limit: Int = 5) async throws -> [Fixture] {
        print("⚽ [FixtureRepo] Fetching upcoming fixtures (limit: \(limit))")
        
        let now = Date()
        let predicate = #Predicate<Fixture> {
            $0.kickoffTime > now && !$0.isFinished
        }
        
        do {
            let fixtures = try await baseRepository.fetchWithPagination(
                predicate: predicate,
                sortBy: [SortDescriptor(\.kickoffTime)],
                limit: limit,
                offset: 0
            )
            print("✅ [FixtureRepo] Fetched \(fixtures.count) upcoming fixtures")
            return fixtures
        } catch {
            print("❌ [FixtureRepo] Fetch failed: \(error)")
            throw error
        }
    }
    
    func fetchRecentFixtures(limit: Int = 5) async throws -> [Fixture] {
        print("⚽ [FixtureRepo] Fetching recent fixtures (limit: \(limit))")
        
        let now = Date()
        let predicate = #Predicate<Fixture> {
            $0.kickoffTime < now && $0.isFinished
        }
        
        do {
            let fixtures = try await baseRepository.fetchWithPagination(
                predicate: predicate,
                sortBy: [SortDescriptor(\.kickoffTime, order: .reverse)],
                limit: limit,
                offset: 0
            )
            print("✅ [FixtureRepo] Fetched \(fixtures.count) recent fixtures")
            return fixtures
        } catch {
            print("❌ [FixtureRepo] Fetch failed: \(error)")
            throw error
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
        
        guard let fixture = try await fetchFixtureById(fixtureId) else {
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
            try await baseRepository.update(fixture)
            print("✅ [FixtureRepo] Score updated successfully")
        } catch {
            print("❌ [FixtureRepo] Update failed: \(error)")
            throw error
        }
    }
    
    func addFixture(_ fixture: Fixture) async throws {
        print("⚽ [FixtureRepo] Adding fixture")
        
        do {
            try await baseRepository.insert(fixture)
            print("✅ [FixtureRepo] Fixture added successfully")
        } catch {
            print("❌ [FixtureRepo] Add failed: \(error)")
            throw error
        }
    }
    
    func deleteFixture(_ fixture: Fixture) async throws {
        print("⚽ [FixtureRepo] Deleting fixture")
        
        do {
            try await baseRepository.delete(fixture)
            print("✅ [FixtureRepo] Fixture deleted successfully")
        } catch {
            print("❌ [FixtureRepo] Delete failed: \(error)")
            throw error
        }
    }
}
