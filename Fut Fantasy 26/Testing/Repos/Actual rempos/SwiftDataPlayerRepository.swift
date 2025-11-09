//
//  SwiftDataPlayerRepository.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import SwiftData

@MainActor
final class SwiftDataPlayerRepository: PlayerRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Write Operations Only
    
    func addPlayer(_ player: Player) async throws {
        print("⚽ [PlayerRepo] Adding player: \(player.name)")
        modelContext.insert(player)
        
        do {
            try modelContext.save()
            print("✅ [PlayerRepo] Player saved successfully")
        } catch {
            print("❌ [PlayerRepo] Save failed: \(error)")
            throw RepositoryError.saveFailed(underlyingError: error)
        }
    }
    
    func updatePlayer(_ player: Player) async throws {
        print("⚽ [PlayerRepo] Updating player: \(player.name)")
        
        do {
            try modelContext.save()
            print("✅ [PlayerRepo] Player updated successfully")
        } catch {
            print("❌ [PlayerRepo] Update failed: \(error)")
            throw RepositoryError.updateFailed(underlyingError: error)
        }
    }
    
    func deletePlayer(_ player: Player) async throws {
        print("⚽ [PlayerRepo] Deleting player: \(player.name)")
        modelContext.delete(player)
        
        do {
            try modelContext.save()
            print("✅ [PlayerRepo] Player deleted successfully")
        } catch {
            print("❌ [PlayerRepo] Delete failed: \(error)")
            throw RepositoryError.deleteFailed(underlyingError: error)
        }
    }
    
    func updatePlayerPerformance(
        playerId: Int,
        matchdayNumber: Int,
        stats: [String: Any]
    ) async throws {
        print("⚽ [PlayerRepo] Updating performance for player \(playerId)")
        
        let predicate = #Predicate<Player> { $0.id == playerId }
        var descriptor = FetchDescriptor<Player>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        guard let player = try modelContext.fetch(descriptor).first else {
            throw RepositoryError.notFound
        }
        
        let perfPredicate = #Predicate<MatchdayPerformance> {
            $0.player?.id == playerId && $0.matchdayNumber == matchdayNumber
        }
        
        var perfDescriptor = FetchDescriptor<MatchdayPerformance>(predicate: perfPredicate)
        perfDescriptor.fetchLimit = 1
        
        let performance: MatchdayPerformance
        if let existing = try modelContext.fetch(perfDescriptor).first {
            performance = existing
        } else {
            performance = MatchdayPerformance(matchdayNumber: matchdayNumber, player: player)
            modelContext.insert(performance)
        }
        
        updatePerformanceStats(performance: performance, stats: stats)
        
        let points = performance.calculatePoints(position: player.position)
        player.matchdayPoints = points
        player.totalPoints += points
        
        if stats["didAppear"] as? Bool == true {
            player.appearances += 1
        }
        
        if player.recentForm == nil {
            player.recentForm = []
        }
        player.recentForm?.append(points)
        if (player.recentForm?.count ?? 0) > 3 {
            player.recentForm?.removeFirst()
        }
        
        try modelContext.save()
    }
    
    private func updatePerformanceStats(performance: MatchdayPerformance, stats: [String: Any]) {
        if let didAppear = stats["didAppear"] as? Bool { performance.didAppear = didAppear }
        if let minutes = stats["minutesPlayed"] as? Int { performance.minutesPlayed = minutes; performance.played60Plus = minutes >= 60 }
        if let goals = stats["goals"] as? Int { performance.goalsScored = goals }
        if let assists = stats["assists"] as? Int { performance.assists = assists }
        if let cleanSheet = stats["cleanSheet"] as? Bool { performance.cleanSheet = cleanSheet }
    }
}
