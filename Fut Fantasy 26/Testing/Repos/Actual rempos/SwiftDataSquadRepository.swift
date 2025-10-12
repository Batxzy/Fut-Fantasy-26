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
    private let baseRepository: BaseRepository<Squad>
    private let contextProvider: ModelContextProvider
    
    init(contextProvider: ModelContextProvider) {
        self.contextProvider = contextProvider
        self.baseRepository = BaseRepository<Squad>(contextProvider: contextProvider)
    }
    
    // MARK: - Squad Queries
    
    func fetchUserSquad() async throws -> Squad {
        print("👥 [SquadRepo] Fetching user squad...")
        
        do {
            let squads = try await baseRepository.fetchAll()
            
            if let squad = squads.first {
                print("✅ [SquadRepo] Found existing squad: \(squad.teamName)")
                return squad
            }
            
            // Create default squad if none exists
            print("⚠️ [SquadRepo] No squad found, creating default squad")
            let newSquad = Squad(teamName: "My Team")
            try await baseRepository.insert(newSquad)
            print("✅ [SquadRepo] Default squad created")
            return newSquad
        } catch {
            print("❌ [SquadRepo] Fetch failed: \(error)")
            throw error
        }
    }
    
    func fetchSquadById(_ id: UUID) async throws -> Squad? {
        print("👥 [SquadRepo] Fetching squad with ID: \(id)")
        
        let predicate = #Predicate<Squad> { $0.id == id }
        
        do {
            let squad = try await baseRepository.fetchOne(with: predicate)
            if squad != nil {
                print("✅ [SquadRepo] Found squad")
            } else {
                print("⚠️ [SquadRepo] Squad not found")
            }
            return squad
        } catch {
            print("❌ [SquadRepo] Fetch failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Squad Management
    
    func addPlayerToSquad(playerId: Int, squadId: UUID) async throws {
        print("👥 [SquadRepo] Adding player \(playerId) to squad \(squadId)")
        
        guard let squad = try await fetchSquadById(squadId) else {
            print("❌ [SquadRepo] Squad not found")
            throw RepositoryError.notFound
        }
        
        // Get player using PlayerRepository
        let playerRepo = SwiftDataPlayerRepository(contextProvider: contextProvider)
        guard let player = try await playerRepo.fetchPlayerById(playerId) else {
            print("❌ [SquadRepo] Player not found")
            throw RepositoryError.notFound
        }
        
        // Check position limit
        guard squad.canAddPlayer(position: player.position) else {
            print("❌ [SquadRepo] Position limit reached")
            throw RepositoryError.invalidData
        }
        
        // Check budget
        guard player.price <= squad.currentBudget else {
            print("❌ [SquadRepo] Insufficient budget")
            throw RepositoryError.invalidData
        }
        
        // Check nation limit (using group stage as default)
        let currentStage: TournamentStage = .groupStage
        guard squad.canAddPlayerFromNation(player.nation, stage: currentStage) else {
            print("❌ [SquadRepo] Nation limit reached")
            throw RepositoryError.invalidData
        }
        
        // Add player
        if squad.players == nil {
            squad.players = [player]
        } else {
            squad.players?.append(player)
        }
        
        do {
            try await baseRepository.update(squad)
            print("✅ [SquadRepo] Player added successfully")
        } catch {
            print("❌ [SquadRepo] Update failed: \(error)")
            throw error
        }
    }
    
    func removePlayerFromSquad(playerId: Int, squadId: UUID) async throws {
        print("👥 [SquadRepo] Removing player \(playerId) from squad")
        
        guard let squad = try await fetchSquadById(squadId) else {
            print("❌ [SquadRepo] Squad not found")
            throw RepositoryError.notFound
        }
        
        squad.players?.removeAll { $0.id == playerId }
        
        // Also remove from starting XI and bench if present
        squad.startingXI?.removeAll { $0.id == playerId }
        squad.bench?.removeAll { $0.id == playerId }
        
        // Clear captain/vice if they were removed
        if squad.captain?.id == playerId {
            squad.captain = nil
        }
        if squad.viceCaptain?.id == playerId {
            squad.viceCaptain = nil
        }
        
        do {
            try await baseRepository.update(squad)
            print("✅ [SquadRepo] Player removed successfully")
        } catch {
            print("❌ [SquadRepo] Update failed: \(error)")
            throw error
        }
    }
    
    func setSquadStartingXI(squadId: UUID, startingXI: [Int]) async throws {
        print("👥 [SquadRepo] Setting starting XI for squad")
        
        guard let squad = try await fetchSquadById(squadId) else {
            print("❌ [SquadRepo] Squad not found")
            throw RepositoryError.notFound
        }
        
        let playerRepo = SwiftDataPlayerRepository(contextProvider: contextProvider)
        var players: [Player] = []
        
        // Get all players from IDs
        for playerId in startingXI {
            if let player = try await playerRepo.fetchPlayerById(playerId) {
                players.append(player)
            }
        }
        
        // Validate starting XI
        guard players.count == 11 else {
            print("❌ [SquadRepo] Invalid starting XI count: \(players.count)")
            throw RepositoryError.invalidData
        }
        
        let gkCount = players.filter { $0.position == .goalkeeper }.count
        let defCount = players.filter { $0.position == .defender }.count
        let midCount = players.filter { $0.position == .midfielder }.count
        let fwdCount = players.filter { $0.position == .forward }.count
        
        guard gkCount == 1 &&
              defCount >= 3 &&
              midCount >= 2 &&
              fwdCount >= 1 else {
            print("❌ [SquadRepo] Invalid formation")
            throw RepositoryError.invalidData
        }
        
        // Update starting XI
        squad.startingXI = players
        
        // Update bench
        if let allPlayers = squad.players {
            squad.bench = allPlayers.filter { player in
                !startingXI.contains(player.id)
            }
        }
        
        do {
            try await baseRepository.update(squad)
            print("✅ [SquadRepo] Starting XI set successfully")
        } catch {
            print("❌ [SquadRepo] Update failed: \(error)")
            throw error
        }
    }
    
    func setCaptain(squadId: UUID, captainId: Int, viceCaptainId: Int) async throws {
        print("👥 [SquadRepo] Setting captain and vice captain")
        
        guard let squad = try await fetchSquadById(squadId) else {
            print("❌ [SquadRepo] Squad not found")
            throw RepositoryError.notFound
        }
        
        let playerRepo = SwiftDataPlayerRepository(contextProvider: contextProvider)
        guard let captain = try await playerRepo.fetchPlayerById(captainId),
              let viceCaptain = try await playerRepo.fetchPlayerById(viceCaptainId) else {
            print("❌ [SquadRepo] Captain or vice captain not found")
            throw RepositoryError.notFound
        }
        
        // Validate captains are in squad
        guard squad.players?.contains(where: { $0.id == captainId }) == true,
              squad.players?.contains(where: { $0.id == viceCaptainId }) == true else {
            print("❌ [SquadRepo] Captain or vice captain not in squad")
            throw RepositoryError.invalidData
        }
        
        squad.captain = captain
        squad.viceCaptain = viceCaptain
        
        do {
            try await baseRepository.update(squad)
            print("✅ [SquadRepo] Captains set successfully")
        } catch {
            print("❌ [SquadRepo] Update failed: \(error)")
            throw error
        }
    }
    
    func createSquad(teamName: String) async throws -> Squad {
        print("👥 [SquadRepo] Creating new squad: \(teamName)")
        
        let squad = Squad(teamName: teamName)
        
        do {
            try await baseRepository.insert(squad)
            print("✅ [SquadRepo] Squad created successfully")
            return squad
        } catch {
            print("❌ [SquadRepo] Create failed: \(error)")
            throw error
        }
    }
    
    func updateSquad(_ squad: Squad) async throws {
        print("👥 [SquadRepo] Updating squad")
        
        do {
            try await baseRepository.update(squad)
            print("✅ [SquadRepo] Squad updated successfully")
        } catch {
            print("❌ [SquadRepo] Update failed: \(error)")
            throw error
        }
    }
}
