//
//  MatchdayRepository.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

import Foundation

protocol MatchdayRepository {
    func fetchCurrentMatchday() async throws -> Matchday?
    func fetchMatchday(number: Int) async throws -> Matchday?
    func fetchAllMatchdays() async throws -> [Matchday]
    func activateMatchday(number: Int) async throws
    func completeMatchday(number: Int) async throws
    func addMatchday(_ matchday: Matchday) async throws
    func updateMatchday(_ matchday: Matchday) async throws
}
