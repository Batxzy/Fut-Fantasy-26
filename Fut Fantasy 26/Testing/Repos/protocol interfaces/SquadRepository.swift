//
//  SquadRepository.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation

protocol SquadRepository {
    func fetchUserSquad() async throws -> Squad
    func fetchSquadById(_ id: UUID) async throws -> Squad?
    func addPlayerToSquad(playerId: Int, squadId: UUID) async throws
    func removePlayerFromSquad(playerId: Int, squadId: UUID) async throws
    func setSquadStartingXI(squadId: UUID, startingXI: [Int]) async throws
    func setCaptain(squadId: UUID, captainId: Int, viceCaptainId: Int) async throws
    func createSquad(teamName: String) async throws -> Squad
    func updateSquad(_ squad: Squad) async throws
}
