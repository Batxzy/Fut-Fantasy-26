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
    private let baseRepository: BaseRepository<Matchday>
    private let contextProvider: ModelContextProvider
    
    init(contextProvider: ModelContextProvider) {
        self.contextProvider = contextProvider
        self.baseRepository = BaseRepository<Matchday>(contextProvider: contextProvider)
    }
    
    // MARK: - Matchday Queries
    
    func fetchCurrentMatchday() async throws -> Matchday? {
        print("📅 [MatchdayRepo] Fetching current matchday...")
        
        // First try to get active matchday
        let activePredicate = #Predicate<Matchday> { $0.isActive == true }
        
        do {
            if let active = try await baseRepository.fetchOne(with: activePredicate) {
                print("✅ [MatchdayRepo] Found active matchday: \(active.number)")
                return active
            }
            
            // If no active matchday, get next upcoming one
            let now = Date()
            let upcomingPredicate = #Predicate<Matchday> { $0.deadline > now }
            
            let upcomingMatchdays = try await baseRepository.fetch(
                with: upcomingPredicate,
                sortBy: [SortDescriptor(\.deadline)]
            )
            
            if let nextMatchday = upcomingMatchdays.first {
                print("✅ [MatchdayRepo] Found next matchday: \(nextMatchday.number)")
                return nextMatchday
            }
            
            print("⚠️ [MatchdayRepo] No current or upcoming matchday found")
            return nil
        } catch {
            print("❌ [MatchdayRepo] Fetch failed: \(error)")
            throw error
        }
    }
    
    func fetchMatchday(number: Int) async throws -> Matchday? {
        print("📅 [MatchdayRepo] Fetching matchday \(number)")
        
        let predicate = #Predicate<Matchday> { $0.number == number }
        
        do {
            let matchday = try await baseRepository.fetchOne(with: predicate)
            if matchday != nil {
                print("✅ [MatchdayRepo] Found matchday")
            } else {
                print("⚠️ [MatchdayRepo] Matchday not found")
            }
            return matchday
        } catch {
            print("❌ [MatchdayRepo] Fetch failed: \(error)")
            throw error
        }
    }
    
    func fetchAllMatchdays() async throws -> [Matchday] {
        print("📅 [MatchdayRepo] Fetching all matchdays...")
        
        do {
            let matchdays = try await baseRepository.fetchAll(
                sortBy: [SortDescriptor(\.number)]
            )
            print("✅ [MatchdayRepo] Fetched \(matchdays.count) matchdays")
            return matchdays
        } catch {
            print("❌ [MatchdayRepo] Fetch failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Matchday Management
    
    func activateMatchday(number: Int) async throws {
        print("📅 [MatchdayRepo] Activating matchday \(number)")
        
        guard let matchday = try await fetchMatchday(number: number) else {
            print("❌ [MatchdayRepo] Matchday not found")
            throw RepositoryError.notFound
        }
        
        do {
            // Deactivate all matchdays
            let allMatchdays = try await fetchAllMatchdays()
            for md in allMatchdays {
                md.isActive = false
            }
            
            // Activate the selected matchday
            matchday.isActive = true
            
            try await baseRepository.update(matchday)
            print("✅ [MatchdayRepo] Matchday activated successfully")
        } catch {
            print("❌ [MatchdayRepo] Activation failed: \(error)")
            throw error
        }
    }
    
    func completeMatchday(number: Int) async throws {
        print("📅 [MatchdayRepo] Completing matchday \(number)")
        
        guard let matchday = try await fetchMatchday(number: number) else {
            print("❌ [MatchdayRepo] Matchday not found")
            throw RepositoryError.notFound
        }
        
        do {
            matchday.isFinished = true
            matchday.isActive = false
            
            try await baseRepository.update(matchday)
            
            // Activate next matchday if available
            let nextNumber = number + 1
            if let nextMatchday = try await fetchMatchday(number: nextNumber) {
                nextMatchday.isActive = true
                try await baseRepository.update(nextMatchday)
                print("✅ [MatchdayRepo] Next matchday activated")
            }
            
            print("✅ [MatchdayRepo] Matchday completed successfully")
        } catch {
            print("❌ [MatchdayRepo] Completion failed: \(error)")
            throw error
        }
    }
    
    func addMatchday(_ matchday: Matchday) async throws {
        print("📅 [MatchdayRepo] Adding matchday")
        
        do {
            try await baseRepository.insert(matchday)
            print("✅ [MatchdayRepo] Matchday added successfully")
        } catch {
            print("❌ [MatchdayRepo] Add failed: \(error)")
            throw error
        }
    }
    
    func updateMatchday(_ matchday: Matchday) async throws {
        print("📅 [MatchdayRepo] Updating matchday")
        
        do {
            try await baseRepository.update(matchday)
            print("✅ [MatchdayRepo] Matchday updated successfully")
        } catch {
            print("❌ [MatchdayRepo] Update failed: \(error)")
            throw error
        }
    }
}