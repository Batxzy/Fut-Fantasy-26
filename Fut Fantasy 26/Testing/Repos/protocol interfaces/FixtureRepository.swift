//
//  FixtureRepository.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import SwiftData


protocol FixtureRepository {
    func addFixture(_ fixture: Fixture) async throws
    func deleteFixture(_ fixture: Fixture) async throws
    func updateFixtureScore(
        fixtureId: Int,
        homeScore: Int,
        awayScore: Int,
        hadExtraTime: Bool,
        hadPenaltyShootout: Bool,
        penaltyWinner: Nation?
    ) async throws
}
