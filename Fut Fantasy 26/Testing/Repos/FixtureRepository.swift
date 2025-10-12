//
//  FixtureRepository.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import SwiftData

class FixtureRepository: BaseRepository<Fixture> {
    
    // MARK: - Fixture Queries
    
    func fetchFixtureById(_ id: Int) throws -> Fixture? {
        try fetchOne(with: #Predicate { $0.id == id })
    }
    
    func fetchFixturesForMatchday(_ matchdayNumber: Int) throws -> [Fixture] {
        try fetch(
            with: #Predicate { $0.matchdayNumber == matchdayNumber },
            sortBy: [SortDescriptor(\.kickoffTime)]
        )
    }
    
    func fetchFixturesForNation(_ nation: Nation) throws -> [Fixture] {
        try fetch(
            with: #Predicate { $0.homeNation == nation || $0.awayNation == nation },
            sortBy: [SortDescriptor(\.kickoffTime)]
        )
    }
    
    func fetchFixturesForGroup(_ group: Group) throws -> [Fixture] {
        try fetch(
            with: #Predicate { $0.group == group },
            sortBy: [SortDescriptor(\.kickoffTime)]
        )
    }
    
    func fetchUpcomingFixtures(limit: Int = 5) throws -> [Fixture] {
        let now = Date()
        return try fetchWithPagination(
            predicate: #Predicate { $0.kickoffTime > now && !$0.isFinished },
            sortBy: [SortDescriptor(\.kickoffTime)],
            limit: limit,
            offset: 0
        )
    }
    
    func fetchRecentFixtures(limit: Int = 5) throws -> [Fixture] {
        let now = Date()
        return try fetchWithPagination(
            predicate: #Predicate { $0.kickoffTime < now && $0.isFinished },
            sortBy: [SortDescriptor(\.kickoffTime, order: .reverse)],
            limit: limit,
            offset: 0
        )
    }
    
    // MARK: - Fixture Management
    
    func updateFixtureScore(
        fixtureId: Int, 
        homeScore: Int, 
        awayScore: Int, 
        hadExtraTime: Bool = false,
        hadPenaltyShootout: Bool = false,
        penaltyWinner: Nation? = nil
    ) throws -> Bool {
        guard let fixture = try fetchFixtureById(fixtureId) else {
            return false
        }
        
        contextProvider.performTransaction(in: mainContext) { _ in
            fixture.homeScore = homeScore
            fixture.awayScore = awayScore
            fixture.hadExtraTime = hadExtraTime
            fixture.hadPenaltyShootout = hadPenaltyShootout
            fixture.penaltyWinner = penaltyWinner
            fixture.isFinished = true
        }
        
        return true
    }
}