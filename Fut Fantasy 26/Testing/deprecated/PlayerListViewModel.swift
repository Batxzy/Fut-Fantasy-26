//
//  PlayerListViewModel.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import SwiftData

/*

@Observable
@MainActor
final class PlayerViewModel {
    var errorMessage: String?
    var isLoading = false
    
    private let repository: PlayerRepository
    
    init(repository: PlayerRepository) {
        self.repository = repository
    }
    
    // MARK: - Write Operations Only
    
    func updatePlayer(_ player: Player) async {
        errorMessage = nil
        
        do {
            try await repository.updatePlayer(player)
            print("✅ [PlayerVM] Player updated")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [PlayerVM] Failed to update player: \(error)")
        }
    }
    
    func updatePlayerPerformance(playerId: Int, matchdayNumber: Int, stats: [String: Any]) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await repository.updatePlayerPerformance(
                playerId: playerId,
                matchdayNumber: matchdayNumber,
                stats: stats
            )
            print("✅ [PlayerVM] Performance updated")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [PlayerVM] Failed to update performance: \(error)")
        }
        
        isLoading = false
    }
}
*/
