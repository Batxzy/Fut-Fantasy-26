//
//  SquadViewModel.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import Observation

@Observable
@MainActor
final class SquadViewModel {
    var errorMessage: String?
    var isLoading = false
    
    private let squadRepository: SquadRepository
    private let playerRepository: PlayerRepository
    
    init(squadRepository: SquadRepository, playerRepository: PlayerRepository) {
        self.squadRepository = squadRepository
        self.playerRepository = playerRepository
    }
    
    // MARK: - Write Operations Only
    
    func addPlayerToSquad(_ player: Player, squadId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await squadRepository.addPlayerToSquad(playerId: player.id, squadId: squadId)
            print("✅ [SquadVM] Player added to squad")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [SquadVM] Failed to add player: \(error)")
        }
        
        isLoading = false
    }
    
    func removePlayerFromSquad(_ player: Player, squadId: UUID) async {
        errorMessage = nil
        
        do {
            try await squadRepository.removePlayerFromSquad(playerId: player.id, squadId: squadId)
            print("✅ [SquadVM] Player removed from squad")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [SquadVM] Failed to remove player: \(error)")
        }
    }
    
    func setCaptain(_ player: Player, squadId: UUID) async {
        errorMessage = nil
        
        do {
            try await squadRepository.setCaptain(playerId: player.id, squadId: squadId)
            print("✅ [SquadVM] Captain set")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [SquadVM] Failed to set captain: \(error)")
        }
    }
    
    func setViceCaptain(_ player: Player, squadId: UUID) async {
        errorMessage = nil
        
        do {
            try await squadRepository.setViceCaptain(playerId: player.id, squadId: squadId)
            print("✅ [SquadVM] Vice-captain set")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [SquadVM] Failed to set vice-captain: \(error)")
        }
    }
    
    func swapStartingPlayers(from: Int, to: Int, squadId: UUID, startingXI: [Player]) async {
        errorMessage = nil
        
        var newStartingXI = startingXI
        newStartingXI.swapAt(from, to)
        
        do {
            try await squadRepository.setSquadStartingXI(
                squadId: squadId,
                startingXI: newStartingXI.map { $0.id }
            )
            print("✅ [SquadVM] Players swapped")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [SquadVM] Failed to swap players: \(error)")
        }
    }
    
    func makeSubstitution(benchPlayer: Player, startingPlayer: Player, squadId: UUID, startingXI: [Player]) async {
        errorMessage = nil
        
        var newStartingXI = startingXI
        if let index = newStartingXI.firstIndex(where: { $0.id == startingPlayer.id }) {
            newStartingXI[index] = benchPlayer
        }
        
        do {
            try await squadRepository.setSquadStartingXI(
                squadId: squadId,
                startingXI: newStartingXI.map { $0.id }
            )
            print("✅ [SquadVM] Substitution made")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [SquadVM] Failed to make substitution: \(error)")
        }
    }
}
