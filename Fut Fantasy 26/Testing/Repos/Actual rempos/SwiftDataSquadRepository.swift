//
//  SwiftDataSquadRepository.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import SwiftData

@MainActor
final class SwiftDataSquadRepository: SquadRepository {
    private let modelContext: ModelContext
    private let playerRepository: PlayerRepository
    
    init(modelContext: ModelContext, playerRepository: PlayerRepository) {
        self.modelContext = modelContext
        self.playerRepository = playerRepository
    }
    
    // MARK: - Helper to fetch squad
    
    private func fetchSquad(by id: UUID) async throws -> Squad? {
        let predicate = #Predicate<Squad> { $0.id == id }
        var descriptor = FetchDescriptor<Squad>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
    
    private func fetchPlayer(by id: Int) async throws -> Player? {
        let predicate = #Predicate<Player> { $0.id == id }
        var descriptor = FetchDescriptor<Player>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
    
    // MARK: - Helper to get position row index
    
    private func positionRowIndex(for position: PlayerPosition) -> Int {
        switch position {
        case .goalkeeper: return 0
        case .defender: return 1
        case .midfielder: return 2
        case .forward: return 3
        }
    }
    
    // MARK: - Write Operations
    
    func createSquad(teamName: String) async throws -> Squad {
        print("👥 [SquadRepo] Creating new squad: \(teamName)")
        
        let squad = Squad(teamName: teamName)
        modelContext.insert(squad)
        
        do {
            try modelContext.save()
            print("✅ [SquadRepo] Squad created successfully")
            return squad
        } catch {
            print("❌ [SquadRepo] Create failed: \(error)")
            throw RepositoryError.saveFailed(underlyingError: error)
        }
    }
    
    func updateSquad(_ squad: Squad) async throws {
        print("👥 [SquadRepo] Updating squad")
        
        do {
            try modelContext.save()
            print("✅ [SquadRepo] Squad updated successfully")
        } catch {
            print("❌ [SquadRepo] Update failed: \(error)")
            throw RepositoryError.updateFailed(underlyingError: error)
        }
    }
    
    func addPlayerToSquad(playerId: Int, squadId: UUID) async throws {
        print("👥 [SquadRepo] Adding player \(playerId) to squad \(squadId)")
        
        guard let squad = try await fetchSquad(by: squadId) else {
            print("❌ [SquadRepo] Squad not found")
            throw RepositoryError.notFound
        }
        
        guard let player = try await fetchPlayer(by: playerId) else {
            print("❌ [SquadRepo] Player not found")
            throw RepositoryError.notFound
        }
        
        // Check position limit
        guard squad.canAddPlayer(position: player.position) else {
            print("❌ [SquadRepo] Position limit reached for \(player.position.rawValue)")
            throw RepositoryError.invalidData
        }
        
        // Check budget
        guard player.price <= squad.currentBudget else {
            print("❌ [SquadRepo] Insufficient budget")
            throw RepositoryError.invalidData
        }
        
        // Check nation limit
        let currentStage: TournamentStage = .groupStage
        guard squad.canAddPlayerFromNation(player.nation, stage: currentStage) else {
            print("❌ [SquadRepo] Nation limit reached for \(player.nation.rawValue)")
            throw RepositoryError.invalidData
        }
        
        // Add player to all players list
        if squad.players == nil {
            squad.players = []
        }
        squad.players?.append(player)
        
        // **NEW LOGIC**: Add to 2D structure
        let totalStarting = squad.startingXIIDs.flatMap { $0 }.count
        
        if totalStarting < 11 {
            // Add to starting XI in appropriate position row
            let rowIndex = positionRowIndex(for: player.position)
            let positionCount = squad.startingXIIDs[rowIndex].count
            
            // Check position limits for starting XI
            let canAddToStarting: Bool
            switch player.position {
            case .goalkeeper: canAddToStarting = positionCount < 1
            case .defender: canAddToStarting = positionCount < 5
            case .midfielder: canAddToStarting = positionCount < 5
            case .forward: canAddToStarting = positionCount < 3
            }
            
            if canAddToStarting {
                squad.startingXIIDs[rowIndex].append(player.id)
                print("   ➕ Added to starting XI row \(rowIndex)")
            } else {
                squad.benchIDs.append(player.id)
                print("   ➕ Added to bench (position limit)")
            }
        } else {
            // Add to bench if starting XI is full
            squad.benchIDs.append(player.id)
            print("   ➕ Added to bench (starting XI full)")
        }
        
        do {
            try modelContext.save()
            print("✅ [SquadRepo] Player added successfully")
        } catch {
            print("❌ [SquadRepo] Update failed: \(error)")
            throw RepositoryError.updateFailed(underlyingError: error)
        }
    }
    
    func removePlayerFromSquad(playerId: Int, squadId: UUID) async throws {
        print("👥 [SquadRepo] Removing player \(playerId) from squad")
        
        guard let squad = try await fetchSquad(by: squadId) else {
            print("❌ [SquadRepo] Squad not found")
            throw RepositoryError.notFound
        }
        
        squad.players?.removeAll { $0.id == playerId }
        
        for i in 0..<squad.startingXIIDs.count {
            squad.startingXIIDs[i].removeAll { $0 == playerId }
        }
        
        squad.benchIDs.removeAll { $0 == playerId }
        
        if squad.captain?.id == playerId {
            squad.captain = nil
        }
        if squad.viceCaptain?.id == playerId {
            squad.viceCaptain = nil
        }
        
        do {
            try modelContext.save()
            print("✅ [SquadRepo] Player removed successfully")
        } catch {
            print("❌ [SquadRepo] Update failed: \(error)")
            throw RepositoryError.updateFailed(underlyingError: error)
        }
    }
    
    func setSquadStartingXI(squadId: UUID, startingXI: [Int]) async throws {
        print("👥 [SquadRepo] Setting starting XI for squad")
        
        guard let squad = try await fetchSquad(by: squadId) else {
            print("❌ [SquadRepo] Squad not found")
            throw RepositoryError.notFound
        }
        
        var players: [Player] = []
        
        for playerId in startingXI {
            if let player = try await fetchPlayer(by: playerId) {
                players.append(player)
            }
        }
        
        guard players.count == 11 else {
            print("❌ [SquadRepo] Invalid starting XI count: \(players.count)")
            throw RepositoryError.invalidData
        }
        
        let gkCount = players.filter { $0.position == .goalkeeper }.count
        let defCount = players.filter { $0.position == .defender }.count
        let midCount = players.filter { $0.position == .midfielder }.count
        let fwdCount = players.filter { $0.position == .forward }.count
        
        guard gkCount == 1 && defCount >= 3 && midCount >= 2 && fwdCount >= 1 else {
            print("❌ [SquadRepo] Invalid formation")
            throw RepositoryError.invalidData
        }
        
        squad.startingXIIDs = [
            players.filter { $0.position == .goalkeeper }.map { $0.id },
            players.filter { $0.position == .defender }.map { $0.id },
            players.filter { $0.position == .midfielder }.map { $0.id },
            players.filter { $0.position == .forward }.map { $0.id }
        ]
        
        if let allPlayers = squad.players {
            let startingIDs = Set(startingXI)
            squad.benchIDs = allPlayers.filter { !startingIDs.contains($0.id) }.map { $0.id }
        }
        
        do {
            try modelContext.save()
            print("✅ [SquadRepo] Starting XI set successfully")
        } catch {
            print("❌ [SquadRepo] Update failed: \(error)")
            throw RepositoryError.updateFailed(underlyingError: error)
        }
    }
    
    func setCaptain(playerId: Int, squadId: UUID) async throws {
        print("👥 [SquadRepo] Setting captain playerId: \(playerId)")
        
        guard let squad = try await fetchSquad(by: squadId) else {
            print("❌ [SquadRepo] Squad not found")
            throw RepositoryError.notFound
        }
        
        guard let player = try await fetchPlayer(by: playerId) else {
            print("❌ [SquadRepo] Player not found")
            throw RepositoryError.notFound
        }
        
        guard squad.players?.contains(where: { $0.id == playerId }) == true else {
            print("❌ [SquadRepo] Captain not in squad")
            throw RepositoryError.invalidData
        }
        
        if squad.viceCaptain?.id == playerId {
            squad.viceCaptain = nil
        }
        
        squad.captain = player
        
        do {
            try modelContext.save()
            print("✅ [SquadRepo] Captain set successfully")
        } catch {
            print("❌ [SquadRepo] Update failed: \(error)")
            throw RepositoryError.updateFailed(underlyingError: error)
        }
    }
    
    func setViceCaptain(playerId: Int, squadId: UUID) async throws {
        print("👥 [SquadRepo] Setting vice captain playerId: \(playerId)")
        
        guard let squad = try await fetchSquad(by: squadId) else {
            print("❌ [SquadRepo] Squad not found")
            throw RepositoryError.notFound
        }
        
        guard let player = try await fetchPlayer(by: playerId) else {
            print("❌ [SquadRepo] Player not found")
            throw RepositoryError.notFound
        }
        
        guard squad.players?.contains(where: { $0.id == playerId }) == true else {
            print("❌ [SquadRepo] Vice captain not in squad")
            throw RepositoryError.invalidData
        }
        
        guard squad.captain?.id != playerId else {
            print("❌ [SquadRepo] Player is already captain")
            throw RepositoryError.invalidData
        }
        
        squad.viceCaptain = player
        
        do {
            try modelContext.save()
            print("✅ [SquadRepo] Vice captain set successfully")
        } catch {
            print("❌ [SquadRepo] Update failed: \(error)")
            throw RepositoryError.updateFailed(underlyingError: error)
        }
    }

    func swapPlayers(slot1: PlayerSlot, slot2: PlayerSlot, squadId: UUID) async throws {
        print("👥 [SquadRepo] Swapping players in squad \(squadId)")

        guard let squad = try await fetchSquad(by: squadId) else {
            print("❌ [SquadRepo] Squad not found for swap")
            throw RepositoryError.notFound
        }
        
        let player1: Player
        switch slot1 {
        case .starting(let p): player1 = p
        case .bench(let p): player1 = p
        }

        let player2: Player
        switch slot2 {
        case .starting(let p): player2 = p
        case .bench(let p): player2 = p
        }

        switch (slot1, slot2) {
        case (.starting, .starting):
            let row1 = positionRowIndex(for: player1.position)
            let row2 = positionRowIndex(for: player2.position)
            
            guard row1 == row2 else {
                print("❌ [SquadRepo] Cannot swap players from different positions")
                return
            }
            
            guard let index1 = squad.startingXIIDs[row1].firstIndex(of: player1.id),
                  let index2 = squad.startingXIIDs[row1].firstIndex(of: player2.id) else {
                print("❌ [SquadRepo] Could not find player indices in row")
                return
            }
            
            print("   🔄 BEFORE SWAP (row \(row1)): \(squad.startingXIIDs[row1])")
            squad.startingXIIDs[row1].swapAt(index1, index2)
            print("   🔄 AFTER SWAP (row \(row1)): \(squad.startingXIIDs[row1])")
            print("   ✅ Swapped starters: \(player1.name) <-> \(player2.name)")

        case (.starting, .bench):
            let row = positionRowIndex(for: player1.position)
            
            guard let startingIndex = squad.startingXIIDs[row].firstIndex(of: player1.id),
                  let benchIndex = squad.benchIDs.firstIndex(of: player2.id) else {
                print("❌ [SquadRepo] Could not find player indices")
                return
            }
            
            squad.startingXIIDs[row][startingIndex] = player2.id
            squad.benchIDs[benchIndex] = player1.id
            print("   ✅ Swapped starter/bench: \(player1.name) <-> \(player2.name)")

        case (.bench, .starting):
            let row = positionRowIndex(for: player2.position)
            
            guard let benchIndex = squad.benchIDs.firstIndex(of: player1.id),
                  let startingIndex = squad.startingXIIDs[row].firstIndex(of: player2.id) else {
                print("❌ [SquadRepo] Could not find player indices")
                return
            }
            
            squad.benchIDs[benchIndex] = player2.id
            squad.startingXIIDs[row][startingIndex] = player1.id
            print("   ✅ Swapped bench/starter: \(player1.name) <-> \(player2.name)")
        
        case (.bench, .bench):
            print("   ⚠️ Bench-to-bench swaps not allowed")
            return
        }
        
        do {
            try modelContext.save()
            print("✅ [SquadRepo] Player swap successful and saved")
        } catch {
            print("❌ [SquadRepo] Player swap save failed: \(error)")
            throw RepositoryError.saveFailed(underlyingError: error)
        }
    }
}
