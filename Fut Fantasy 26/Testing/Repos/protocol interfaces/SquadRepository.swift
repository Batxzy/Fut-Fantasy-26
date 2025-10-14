//
//  SquadRepository.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation

protocol SquadRepository {
    func createSquad(teamName: String) async throws -> Squad
    func updateSquad(_ squad: Squad) async throws
    func addPlayerToSquad(playerId: Int, squadId: UUID) async throws
    func removePlayerFromSquad(playerId: Int, squadId: UUID) async throws
    func setSquadStartingXI(squadId: UUID, startingXI: [Int]) async throws
    func setCaptain(playerId: Int, squadId: UUID) async throws
    func setViceCaptain(playerId: Int, squadId: UUID) async throws
    func swapPlayers(slot1: PlayerSlot, slot2: PlayerSlot, squadId: UUID) async throws
}
