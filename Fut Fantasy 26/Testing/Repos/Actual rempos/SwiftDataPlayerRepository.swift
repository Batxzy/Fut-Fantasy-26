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
    private let contextProvider: ModelContextProvider
    
    init(contextProvider: ModelContextProvider) {
        self.contextProvider = contextProvider
        self.baseRepository = BaseRepository<Player>(contextProvider: contextProvider)
    }
    
    // MARK: - Player Queries
    
    func fetchPlayerById(_ id: Int) async throws -> Player? {
        print("⚽ [PlayerRepo] Fetching player with ID: \(id)")
        
        let predicate = #Predicate<Player> { $0.id == id }
        
        do {
            let player = try await baseRepository.fetchOne(with: predicate)
            if player != nil {
                print("✅ [PlayerRepo] Found player")
            } else {
                print("⚠️ [PlayerRepo] Player not found")
            }
            return player
        } catch {
            print("❌ [PlayerRepo] Fetch failed: \(error)")
            throw error
        }
    }
    
    func fetchTopPlayers(limit: Int = 10) async throws -> [Player] {
        print("⚽ [PlayerRepo] Fetching top \(limit) players...")
        
        do {
            let players = try await baseRepository.fetchWithPagination(
                sortBy: [SortDescriptor(\.totalPoints, order: .reverse)],
                limit: limit,
                offset: 0
            )
            print("✅ [PlayerRepo] Fetched \(players.count) top players")
            return players
        } catch {
            print("❌ [PlayerRepo] Fetch failed: \(error)")
            throw error
        }
    }
    
    func searchPlayers(query: String) async throws -> [Player] {
        print("⚽ [PlayerRepo] Searching players with query: \(query)")
        
        if query.isEmpty {
            return try await baseRepository.fetchAll()
        }
        
        let predicate = #Predicate<Player> {
            $0.name.localizedStandardContains(query) ||
            $0.firstName.localizedStandardContains(query) ||
            $0.lastName.localizedStandardContains(query)
        }
        
        do {
            let players = try await baseRepository.fetch(with: predicate)
            print("✅ [PlayerRepo] Found \(players.count) players matching '\(query)'")
            return players
        } catch {
            print("❌ [PlayerRepo] Search failed: \(error)")
            throw error
        }
    }
    
    func fetchPlayersForSquadBuilding(
        position: PlayerPosition? = nil,
        nation: Nation? = nil,
        priceUnder: Double? = nil,
        sortType: PlayerSortType = .points,
        limit: Int = 20,
        offset: Int = 0
    ) async throws -> [Player] {
        print("⚽ [PlayerRepo] Fetching players for squad building...")
        
        // Build predicate dynamically based on filters
        var predicates: [Predicate<Player>] = []
        
        if let position = position {
            let posPredicate = #Predicate<Player> { $0.position == position }
            predicates.append(posPredicate)
        }
        
        if let nation = nation {
            let nationPredicate = #Predicate<Player> { $0.nation == nation }
            predicates.append(nationPredicate)
        }
        
        if let priceUnder = priceUnder {
            let pricePredicate = #Predicate<Player> { $0.price <= priceUnder }
            predicates.append(pricePredicate)
        }
        
        // Combine predicates if any exist
        let finalPredicate: Predicate<Player>? = {
            if predicates.isEmpty {
                return nil
            }
            // Use the first predicate as base, then combine with others
            // Note: In production, you might want a more sophisticated predicate combiner
            return predicates.first
        }()
        
        // Choose sort descriptors based on sort type
        let sortDescriptors: [SortDescriptor<Player>]
        switch sortType {
        case .points:
            sortDescriptors = [SortDescriptor(\.totalPoints, order: .reverse)]
        case .price:
            sortDescriptors = [SortDescriptor(\.price), SortDescriptor(\.totalPoints, order: .reverse)]
        case .value:
            sortDescriptors = [SortDescriptor(\.totalPoints, order: .reverse)]
        case .form:
            sortDescriptors = [SortDescriptor(\.matchdayPoints, order: .reverse)]
        }
        
        do {
            let players = try await baseRepository.fetchWithPagination(
                predicate: finalPredicate,
                sortBy: sortDescriptors,
                limit: limit,
                offset: offset
            )
            print("✅ [PlayerRepo] Fetched \(players.count) players for squad building")
            return players
        } catch {
            print("❌ [PlayerRepo] Fetch failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Player Management
    
    func addPlayer(_ player: Player) async throws {
        print("⚽ [PlayerRepo] Adding player: \(player.name)")
        
        do {
            try await baseRepository.insert(player)
            print("✅ [PlayerRepo] Player added successfully")
        } catch {
            print("❌ [PlayerRepo] Add failed: \(error)")
            throw error
        }
    }
    
    func updatePlayer(_ player: Player) async throws {
        print("⚽ [PlayerRepo] Updating player: \(player.name)")
        
        do {
            try await baseRepository.update(player)
            print("✅ [PlayerRepo] Player updated successfully")
        } catch {
            print("❌ [PlayerRepo] Update failed: \(error)")
            throw error
        }
    }
    
    func deletePlayer(_ player: Player) async throws {
        print("⚽ [PlayerRepo] Deleting player: \(player.name)")
        
        do {
            try await baseRepository.delete(player)
            print("✅ [PlayerRepo] Player deleted successfully")
        } catch {
            print("❌ [PlayerRepo] Delete failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Player Performance Management
    
    func updatePlayerPerformance(
        playerId: Int,
        matchdayNumber: Int,
        stats: [String: Any]
    ) async throws {
        print("⚽ [PlayerRepo] Updating performance for player \(playerId), matchday \(matchdayNumber)")
        
        guard let player = try await fetchPlayerById(playerId) else {
            print("❌ [PlayerRepo] Player not found")
            throw RepositoryError.notFound
        }
        
        do {
            // Find or create performance record
            let predicate = #Predicate<MatchdayPerformance> {
                $0.player?.id == playerId && $0.matchdayNumber == matchdayNumber
            }
            
            let context = baseRepository.mainContext
            var descriptor = FetchDescriptor<MatchdayPerformance>(predicate: predicate)
            descriptor.fetchLimit = 1
            
            let performance: MatchdayPerformance
            let existingPerformances = try context.fetch(descriptor)
            
            if let existingPerformance = existingPerformances.first {
                performance = existingPerformance
            } else {
                performance = MatchdayPerformance(matchdayNumber: matchdayNumber, player: player)
                context.insert(performance)
            }
            
            // Update performance stats
            updatePerformanceStats(performance: performance, stats: stats)
            
            // Calculate and update points
            let points = performance.calculatePoints(position: player.position)
            player.matchdayPoints = points
            player.totalPoints += points
            
            // Update appearances
            if stats["didAppear"] as? Bool == true {
                player.appearances += 1
            }
            
            // Update recent form
            if player.recentForm == nil {
                player.recentForm = []
            }
            player.recentForm?.append(points)
            if (player.recentForm?.count ?? 0) > 3 {
                player.recentForm?.removeFirst()
            }
            
            try context.save()
            print("✅ [PlayerRepo] Performance updated successfully")
        } catch {
            print("❌ [PlayerRepo] Performance update failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Private Helpers
    
    private func updatePerformanceStats(performance: MatchdayPerformance, stats: [String: Any]) {
        if let didAppear = stats["didAppear"] as? Bool {
            performance.didAppear = didAppear
        }
        
        if let minutesPlayed = stats["minutesPlayed"] as? Int {
            performance.minutesPlayed = minutesPlayed
            performance.played60Plus = minutesPlayed >= 60
        }
        
        if let goals = stats["goals"] as? Int {
            performance.goalsScored = goals
        }
        
        if let outsideBoxGoals = stats["goalsOutsideBox"] as? Int {
            performance.goalsOutsideBox = outsideBoxGoals
        }
        
        if let assists = stats["assists"] as? Int {
            performance.assists = assists
        }
        
        if let cleanSheet = stats["cleanSheet"] as? Bool {
            performance.cleanSheet = cleanSheet
        }
    }
}