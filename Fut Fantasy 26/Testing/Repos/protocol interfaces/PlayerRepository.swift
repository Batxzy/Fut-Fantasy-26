import Foundation
import SwiftData

protocol PlayerRepository {
    func addPlayer(_ player: Player) async throws
    func updatePlayer(_ player: Player) async throws
    func deletePlayer(_ player: Player) async throws
    func updatePlayerPerformance(
        playerId: Int,
        matchdayNumber: Int,
        stats: [String: Any]
    ) async throws
}

enum PlayerSortType {
    case points
    case price
    case value
    case form
}
