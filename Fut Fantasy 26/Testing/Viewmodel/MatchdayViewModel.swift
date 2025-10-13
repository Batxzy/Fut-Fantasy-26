//
//  MatchdayViewModel.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

/*
import Foundation
import Observation

@Observable
@MainActor
final class MatchdayViewModel {
    // Dependencies
    private let matchdayRepository: MatchdayRepository
    
    // State
    var matchdays: [Matchday] = []
    var currentMatchday: Matchday?
    var isLoading = false
    var errorMessage: String?
    
    init(matchdayRepository: MatchdayRepository) {
        self.matchdayRepository = matchdayRepository
    }
    
    // MARK: - Matchday Operations
    
    func loadAllMatchdays() async {
        isLoading = true
        errorMessage = nil
        
        do {
            matchdays = try await matchdayRepository.fetchAllMatchdays()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading matchdays: \(error)")
        }
        
        isLoading = false
    }
    
    func loadCurrentMatchday() async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentMatchday = try await matchdayRepository.fetchCurrentMatchday()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading current matchday: \(error)")
        }
        
        isLoading = false
    }
    
    func activateMatchday(number: Int) async {
        do {
            try await matchdayRepository.activateMatchday(number: number)
            await loadCurrentMatchday()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error activating matchday: \(error)")
        }
    }
    
    func completeMatchday(number: Int) async {
        do {
            try await matchdayRepository.completeMatchday(number: number)
            await loadCurrentMatchday()
            await loadAllMatchdays()
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error completing matchday: \(error)")
        }
    }
}
*/
