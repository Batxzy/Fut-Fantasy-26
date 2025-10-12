//
//  SquadViewModel.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


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
    // Dependencies
    private let squadRepository: SquadRepository
    private let playerRepository: PlayerRepository
    
    // State
    var squad: Squad?
    var isLoading = false
    var errorMessage: String?
    
    init(squadRepository: SquadRepository, playerRepository: PlayerRepository) {
        self.squadRepository = squadRepository
        self.playerRepository = playerRepository
    }
    
    func loadSquad() async {
        isLoading = true
        errorMessage = nil
        
        do {
            squad = try await squadRepository.fetchUserSquad()
            print("✅ [ViewModel] Squad loaded: \(squad?.players?.count ?? 0) players, Budget: \(squad?.displayBudget ?? "N/A")")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading squad: \(error)")
        }
        
        isLoading = false
    }
    
    func swapStartingPlayers(from: Int, to: Int) async {
        guard let squad = squad,
              var startingXI = squad.startingXI,
              from < startingXI.count,
              to < startingXI.count else { return }
        
        startingXI.swapAt(from, to)
        
        do {
            try await squadRepository.setSquadStartingXI(
                squadId: squad.id,
                startingXI: startingXI.map { $0.id }
            )
            await loadSquad()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func makeSubstitution(benchPlayer: Player, startingPlayer: Player) async {
        guard let squad = squad else { return }
        
        var startingXI = squad.startingXI ?? []
        var bench = squad.bench ?? []
        
        // Swap players
        if let startingIndex = startingXI.firstIndex(where: { $0.id == startingPlayer.id }),
           let benchIndex = bench.firstIndex(where: { $0.id == benchPlayer.id }) {
            startingXI[startingIndex] = benchPlayer
            bench[benchIndex] = startingPlayer
            
            do {
                try await squadRepository.setSquadStartingXI(
                    squadId: squad.id,
                    startingXI: startingXI.map { $0.id }
                )
                await loadSquad()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func transferPlayer(out oldPlayer: Player, in newPlayer: Player) async {
        guard let squad = squad else { return }
        
        do {
            print("🔄 [ViewModel] Starting transfer: \(oldPlayer.name) → \(newPlayer.name)")
            
            // Remove old player
            try await squadRepository.removePlayerFromSquad(playerId: oldPlayer.id, squadId: squad.id)
            print("✅ [ViewModel] Old player removed")
            
            // Add new player
            try await squadRepository.addPlayerToSquad(playerId: newPlayer.id, squadId: squad.id)
            print("✅ [ViewModel] New player added")
            
            // Reload squad to reflect changes
            await loadSquad()
            print("✅ [ViewModel] Squad reloaded")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [ViewModel] Transfer failed: \(error)")
        }
    }
}
