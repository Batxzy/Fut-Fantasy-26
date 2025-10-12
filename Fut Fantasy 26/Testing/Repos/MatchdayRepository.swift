//
//  MatchdayRepository.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import SwiftData

class MatchdayRepository: BaseRepository<Matchday> {
    
    // MARK: - Matchday Queries
    
    func fetchCurrentMatchday() throws -> Matchday? {
        // First try to get active matchday
        let activePredicate = #Predicate<Matchday> { $0.isActive == true }
        if let active = try fetchOne(with: activePredicate) {
            return active
        }
        
        // If no active matchday, get next upcoming one
        let now = Date()
        let upcomingPredicate = #Predicate<Matchday> { $0.deadline > now }
        var descriptor = FetchDescriptor<Matchday>(
            predicate: upcomingPredicate,
            sortBy: [SortDescriptor(\.deadline)]
        )
        descriptor.fetchLimit = 1
        
        let results = try mainContext.fetch(descriptor)
        return results.first
    }
    
    func fetchMatchday(number: Int) throws -> Matchday? {
        try fetchOne(with: #Predicate { $0.number == number })
    }
    
    func fetchAllMatchdays() throws -> [Matchday] {
        try fetchAll(sortBy: [SortDescriptor(\.number)])
    }
    
    // MARK: - Matchday Management
    
    func activateMatchday(number: Int) throws -> Bool {
        guard let matchday = try fetchMatchday(number: number) else {
            return false
        }
        
        // Deactivate all matchdays
        contextProvider.performTransaction(in: mainContext) { context in
            let allMatchdaysPredicate = #Predicate<Matchday> { _ in true }
            if let allMatchdays = try? context.fetch(FetchDescriptor<Matchday>(predicate: allMatchdaysPredicate)) {
                for md in allMatchdays {
                    md.isActive = false
                }
            }
            
            // Activate the selected matchday
            matchday.isActive = true
        }
        
        return true
    }
    
    func completeMatchday(number: Int) throws -> Bool {
        guard let matchday = try fetchMatchday(number: number) else {
            return false
        }
        
        contextProvider.performTransaction(in: mainContext) { context in
            matchday.isFinished = true
            matchday.isActive = false
            
            // Activate next matchday if available
            let nextNumber = number + 1
            let nextMatchdayPredicate = #Predicate<Matchday> { $0.number == nextNumber }
            if let nextMatchday = try? context.fetch(FetchDescriptor<Matchday>(predicate: nextMatchdayPredicate)).first {
                nextMatchday.isActive = true
            }
        }
        
        return true
    }
}