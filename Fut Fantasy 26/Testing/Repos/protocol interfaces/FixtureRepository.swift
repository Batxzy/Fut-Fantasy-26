//
//  FixtureRepository.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import SwiftData

protocol FixtureRepository {
    func fetchFixtureById(_ id: Int) async throws -> Fixture?
    func fetchFixturesForMatchday(_ matchdayNumber: Int) async throws -> [Fixture]
    func fetchFixturesForNation(_ nation: Nation) async throws -> [Fixture]
    func fetchFixturesForGroup(_ group: Group) async throws -> [Fixture]
    func fetchUpcomingFixtures(limit: Int) async throws -> [Fixture]
    func fetchRecentFixtures(limit: Int) async throws -> [Fixture]
    func updateFixtureScore(
        fixtureId: Int,
        homeScore: Int,
        awayScore: Int,
        hadExtraTime: Bool,
        hadPenaltyShootout: Bool,
        penaltyWinner: Nation?
    ) async throws
    func addFixture(_ fixture: Fixture) async throws
    func deleteFixture(_ fixture: Fixture) async throws
}
