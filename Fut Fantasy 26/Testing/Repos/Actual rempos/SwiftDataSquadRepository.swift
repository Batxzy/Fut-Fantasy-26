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
        
        // Add player
        if squad.players == nil {
            squad.players = []
        }
        squad.players?.append(player)
        
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
        squad.startingXI?.removeAll { $0.id == playerId }
        squad.bench?.removeAll { $0.id == playerId }
        
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
        
        squad.startingXI = players
        
        if let allPlayers = squad.players {
            squad.bench = allPlayers.filter { player in
                !startingXI.contains(player.id)
            }
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
}
