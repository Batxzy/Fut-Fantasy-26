//
//  SquadRepository.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import SwiftData

class SquadRepository: BaseRepository<Squad> {
    
    // MARK: - Squad Queries
    
    func fetchUserSquad() throws -> Squad? {
        // In a real app, you would use auth to get the user's squad ID
        // For now, just get the first squad or create one if none exists
        let squads = try fetchAll()
        if let squad = squads.first {
            return squad
        }
        
        // Create default squad if none exists
        let newSquad = Squad(teamName: "My Team")
        insert(newSquad)
        return newSquad
    }
    
    func fetchSquadById(_ id: UUID) throws -> Squad? {
        try fetchOne(with: #Predicate { $0.id == id })
    }
    
    // MARK: - Squad Management
    
    func addPlayerToSquad(playerId: Int, squadId: UUID) throws -> Bool {
        guard let squad = try fetchSquadById(squadId) else {
            return false
        }
        
        let playerRepo = PlayerRepository(contextProvider: contextProvider)
        guard let player = try playerRepo.fetchPlayerById(playerId) else {
            return false
        }
        
        // Check position limit
        guard squad.canAddPlayer(position: player.position) else {
            return false
        }
        
        // Check budget
        guard player.price <= squad.currentBudget else {
            return false
        }
        
        // Check nation limit if in tournament stage
        // (would need to get current tournament stage)
        let currentStage: TournamentStage = .groupStage // Replace with actual stage
        guard squad.canAddPlayerFromNation(player.nation, stage: currentStage) else {
            return false
        }
        
        // Add player
        contextProvider.performTransaction(in: mainContext) { _ in
            if squad.players == nil {
                squad.players = [player]
            } else {
                squad.players?.append(player)
            }
        }
        
        return true
    }
    
    func setSquadStartingXI(squadId: UUID, startingXI: [Int]) throws -> Bool {
        guard let squad = try fetchSquadById(squadId) else {
            return false
        }
        
        let playerRepo = PlayerRepository(contextProvider: contextProvider)
        var players: [Player] = []
        
        // Get all players from IDs
        for playerId in startingXI {
            if let player = try playerRepo.fetchPlayerById(playerId) {
                players.append(player)
            }
        }
        
        // Validate starting XI
        guard players.count == 11 else { return false }
        
        let gkCount = players.filter { $0.position == .goalkeeper }.count
        let defCount = players.filter { $0.position == .defender }.count
        let midCount = players.filter { $0.position == .midfielder }.count
        let fwdCount = players.filter { $0.position == .forward }.count
        
        guard gkCount == 1 &&
              defCount >= 3 &&
              midCount >= 2 &&
              fwdCount >= 1 else {
            return false
        }
        
        // Update starting XI
        contextProvider.performTransaction(in: mainContext) { _ in
            squad.startingXI = players
            
            // Update bench - all players not in starting XI
            if let allPlayers = squad.players {
                squad.bench = allPlayers.filter { player in
                    !startingXI.contains(player.id)
                }
            }
        }
        
        return true
    }
    
    func setCaptain(squadId: UUID, captainId: Int, viceCaptainId: Int) throws -> Bool {
        guard let squad = try fetchSquadById(squadId) else {
            return false
        }
        
        let playerRepo = PlayerRepository(contextProvider: contextProvider)
        guard let captain = try playerRepo.fetchPlayerById(captainId),
              let viceCaptain = try playerRepo.fetchPlayerById(viceCaptainId) else {
            return false
        }
        
        // Validate captain and vice captain are in squad
        guard squad.players?.contains(where: { $0.id == captainId }) == true,
              squad.players?.contains(where: { $0.id == viceCaptainId }) == true else {
            return false
        }
        
        // Update captains
        contextProvider.performTransaction(in: mainContext) { _ in
            squad.captain = captain
            squad.viceCaptain = viceCaptain
        }
        
        return true
    }
}