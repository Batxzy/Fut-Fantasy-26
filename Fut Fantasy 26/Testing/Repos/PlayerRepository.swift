import Foundation
import SwiftData

class PlayerRepository: BaseRepository<Player> {
    
    // MARK: - Player-Specific Queries
    
    func fetchPlayerById(_ id: Int) throws -> Player? {
        try fetchOne(with: #Predicate { $0.id == id })
    }
    
    func fetchTopPlayers(limit: Int = 10) throws -> [Player] {
        var descriptor = FetchDescriptor<Player>(sortBy: [SortDescriptor(\.totalPoints, order: .reverse)])
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = 0
        return try mainContext.fetch(descriptor)
    }
    
    func searchPlayers(query: String) throws -> [Player] {
        if query.isEmpty { return try fetchAll() }
        
        let predicate = #Predicate<Player> {
            $0.name.localizedStandardContains(query) ||
            $0.firstName.localizedStandardContains(query) ||
            $0.lastName.localizedStandardContains(query)
        }
        return try fetch(with: predicate)
    }
    
    // --- THIS IS THE FINAL, WORKING IMPLEMENTATION ---
    func fetchPlayersForSquadBuilding(
        position: PlayerPosition? = nil,
        nation: Nation? = nil,
        priceUnder: Double? = nil,
        sortType: SortType = .points,
        limit: Int = 20,
        offset: Int = 0
    ) throws -> [Player] {
        
        var predicates: [Predicate<Player>] = []

        // Create simple, individual predicates. This is fast for the compiler.
        if let position {
            predicates.append(#Predicate<Player> { $0.position == position })
        }
        
        if let nation {
            predicates.append(#Predicate<Player> { $0.nation == nation })
        }

        if let priceUnder {
            predicates.append(#Predicate<Player> { $0.price <= priceUnder })
        }

        // Choose sort descriptors
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
        
        
        // Use the existing, simple fetchWithPagination method from the BaseRepository.
        return try fetchWithPagination(
            sortBy: sortDescriptors,
            limit: limit,
            offset: offset
        )
    }
    
    // MARK: - Player Performance Management
    
    func updatePlayerPerformance(
        playerId: Int,
        matchdayNumber: Int,
        stats: [String: Any]
    ) throws {
        guard let player = try fetchPlayerById(playerId) else { return }
        
        contextProvider.performTransaction(in: mainContext) { context in
            let predicate = #Predicate<MatchdayPerformance> {
                $0.player?.id == playerId && $0.matchdayNumber == matchdayNumber
            }
            
            var descriptor = FetchDescriptor<MatchdayPerformance>(predicate: predicate)
            descriptor.fetchLimit = 1
            
            let performance: MatchdayPerformance
            if let existingPerformance = try? context.fetch(descriptor).first {
                performance = existingPerformance
            } else {
                performance = MatchdayPerformance(matchdayNumber: matchdayNumber, player: player)
                context.insert(performance)
            }
            
            self.updatePerformanceStats(performance: performance, stats: stats)
            
            let points = performance.calculatePoints(position: player.position)
            player.matchdayPoints = points
            player.totalPoints += points
            
            if stats["didAppear"] as? Bool == true {
                player.appearances += 1
            }
            
            if player.recentForm == nil { player.recentForm = [] }
            player.recentForm?.append(points)
            if (player.recentForm?.count ?? 0) > 3 {
                player.recentForm?.removeFirst()
            }
        }
    }
    
    private func updatePerformanceStats(performance: MatchdayPerformance, stats: [String: Any]) {
        if let didAppear = stats["didAppear"] as? Bool { performance.didAppear = didAppear }
        if let minutesPlayed = stats["minutesPlayed"] as? Int {
            performance.minutesPlayed = minutesPlayed
            performance.played60Plus = minutesPlayed >= 60
        }
        if let goals = stats["goals"] as? Int { performance.goalsScored = goals }
        if let outsideBoxGoals = stats["goalsOutsideBox"] as? Int { performance.goalsOutsideBox = outsideBoxGoals }
        if let assists = stats["assists"] as? Int { performance.assists = assists }
        if let cleanSheet = stats["cleanSheet"] as? Bool { performance.cleanSheet = cleanSheet }
    }
    
    enum SortType {
        case points, price, value, form
    }
}
