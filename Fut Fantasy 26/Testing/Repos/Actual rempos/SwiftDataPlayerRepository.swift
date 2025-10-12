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
    private let baseRepository: BaseRepository<Player>
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.baseRepository = BaseRepository<Player>(modelContext: modelContext)
    }
    
    // MARK: - Player Queries
    
    func fetchPlayerById(_ id: Int) async throws -> Player? {
        let predicate = #Predicate<Player> { $0.id == id }
        return try await baseRepository.fetchOne(with: predicate)
    }
    
    func fetchTopPlayers(limit: Int = 10) async throws -> [Player] {
        return try await baseRepository.fetchWithPagination(
            sortBy: [SortDescriptor(\.totalPoints, order: .reverse)],
            limit: limit,
            offset: 0
        )
    }
    
    func searchPlayers(query: String) async throws -> [Player] {
        if query.isEmpty {
            return try await fetchPlayersForSquadBuilding(limit: 100)
        }
        
        let predicate = #Predicate<Player> {
            $0.name.localizedStandardContains(query) ||
            $0.firstName.localizedStandardContains(query) ||
            $0.lastName.localizedStandardContains(query)
        }
        
        return try await baseRepository.fetch(with: predicate)
    }
    
    // --- NUKED AND REPLACED PREDICATE LOGIC ---
    // This is the simplest, most stable implementation. No complex macros, no NSPredicate.
    func fetchPlayersForSquadBuilding(
        position: PlayerPosition? = nil,
        nation: Nation? = nil,
        priceUnder: Double? = nil,
        sortType: PlayerSortType = .points,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [Player] {
        
        // 1. Fetch all players first.
        let allPlayers = try await baseRepository.fetchAll()
        
        // 2. Apply filters in-memory. This is clear and avoids compiler issues.
        var filteredPlayers = allPlayers
        
        if let position = position {
            filteredPlayers = filteredPlayers.filter { $0.position == position }
        }
        
        if let nation = nation {
            filteredPlayers = filteredPlayers.filter { $0.nation == nation }
        }
        
        if let priceUnder = priceUnder {
            filteredPlayers = filteredPlayers.filter { $0.price <= priceUnder }
        }
        
        // 3. Apply sorting.
        switch sortType {
        case .points:
            filteredPlayers.sort { $0.totalPoints > $1.totalPoints }
        case .price:
            filteredPlayers.sort {
                if $0.price != $1.price {
                    return $0.price < $1.price
                } else {
                    return $0.totalPoints > $1.totalPoints
                }
            }
        case .value:
            // Sorting by computed property requires this approach
            filteredPlayers.sort { $0.pointsPerPrice > $1.pointsPerPrice }
        case .form:
            filteredPlayers.sort { $0.matchdayPoints > $1.matchdayPoints }
        }
        
        // 4. Apply pagination.
        let startIndex = offset
        let endIndex = min(startIndex + limit, filteredPlayers.count)
        
        if startIndex >= endIndex {
            return [] // Return empty if the offset is out of bounds.
        }
        
        return Array(filteredPlayers[startIndex..<endIndex])
    }
    
    // MARK: - Player Management
    
    func addPlayer(_ player: Player) async throws {
        try await baseRepository.insert(player)
    }
    
    func updatePlayer(_ player: Player) async throws {
        try await baseRepository.update(player)
    }
    
    func deletePlayer(_ player: Player) async throws {
        try await baseRepository.delete(player)
    }
    
    // MARK: - Player Performance Management
    
    func updatePlayerPerformance(
        playerId: Int,
        matchdayNumber: Int,
        stats: [String: Any]
    ) async throws {
        guard let player = try await fetchPlayerById(playerId) else {
            throw RepositoryError.notFound
        }
        
        let predicate = #Predicate<MatchdayPerformance> {
            $0.player?.id == playerId && $0.matchdayNumber == matchdayNumber
        }
        
        var descriptor = FetchDescriptor<MatchdayPerformance>(predicate: predicate)
        descriptor.fetchLimit = 1
        
        let performance: MatchdayPerformance
        if let existing = try modelContext.fetch(descriptor).first {
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
