import Foundation
import SwiftData

protocol PlayerRepository {
    func fetchPlayerById(_ id: Int) async throws -> Player?
    func fetchTopPlayers(limit: Int) async throws -> [Player]
    func searchPlayers(query: String) async throws -> [Player]
    func fetchPlayersForSquadBuilding(
        position: PlayerPosition?,
        nation: Nation?,
        priceUnder: Double?,
        sortType: PlayerSortType,
        limit: Int,
        offset: Int
    ) async throws -> [Player]
    func updatePlayerPerformance(
        playerId: Int,
        matchdayNumber: Int,
        stats: [String: Any]
    ) async throws
    func addPlayer(_ player: Player) async throws
    func updatePlayer(_ player: Player) async throws
    func deletePlayer(_ player: Player) async throws
}

enum PlayerSortType {
    case points
    case price
    case value
    case form
}
