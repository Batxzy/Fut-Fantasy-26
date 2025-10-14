//
//  FixtureViewModel.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

/*

import Foundation
import Observation

@Observable
@MainActor
final class FixtureViewModel {
    // Dependencies
    private let fixtureRepository: FixtureRepository
    private let matchdayRepository: MatchdayRepository
    
    // State
    var fixtures: [Fixture] = []
    var currentMatchday: Matchday?
    var isLoading = false
    var errorMessage: String?
    
    init(fixtureRepository: FixtureRepository, matchdayRepository: MatchdayRepository) {
        self.fixtureRepository = fixtureRepository
        self.matchdayRepository = matchdayRepository
    }
    
    // MARK: - Fixture Operations
    
    func loadCurrentMatchdayFixtures() async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentMatchday = try await matchdayRepository.fetchCurrentMatchday()
            
            if let matchday = currentMatchday {
                fixtures = try await fixtureRepository.fetchFixturesForMatchday(matchday.number)
            } else {
                fixtures = []
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading fixtures: \(error)")
        }
        
        isLoading = false
    }
    
    func loadUpcomingFixtures(limit: Int = 5) async {
        isLoading = true
        errorMessage = nil
        
        do {
            fixtures = try await fixtureRepository.fetchUpcomingFixtures(limit: limit)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading upcoming fixtures: \(error)")
        }
        
        isLoading = false
    }
    
    func loadRecentFixtures(limit: Int = 5) async {
        isLoading = true
        errorMessage = nil
        
        do {
            fixtures = try await fixtureRepository.fetchRecentFixtures(limit: limit)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading recent fixtures: \(error)")
        }
        
        isLoading = false
    }
    
    func loadFixturesForNation(_ nation: Nation) async {
        isLoading = true
        errorMessage = nil
        
        do {
            fixtures = try await fixtureRepository.fetchFixturesForNation(nation)
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading fixtures for nation: \(error)")
        }
        
        isLoading = false
    }
    
    func updateFixtureScore(
        fixtureId: Int,
        homeScore: Int,
        awayScore: Int,
        hadExtraTime: Bool = false,
        hadPenaltyShootout: Bool = false,
        penaltyWinner: Nation? = nil
    ) async {
        do {
            try await fixtureRepository.updateFixtureScore(
                fixtureId: fixtureId,
                homeScore: homeScore,
                awayScore: awayScore,
                hadExtraTime: hadExtraTime,
                hadPenaltyShootout: hadPenaltyShootout,
                penaltyWinner: penaltyWinner
            )
            await loadCurrentMatchdayFixtures() // Reload to reflect changes
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error updating fixture score: \(error)")
        }
    }
}
*/
