//
//  PlayerListViewModel.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class PlayerListViewModel {
    // Dependencies
    private let playerRepository: PlayerRepository
    
    // State
    var players: [Player] = []
    var isLoading = false
    var errorMessage: String?
    var currentPage = 0
    var hasMorePages = true
    
    // Filters
    var selectedPosition: PlayerPosition?
    var selectedNation: Nation?
    var maxPrice: Double?
    var searchQuery = ""
    var sortType: PlayerSortType = .points
    
    // Constants
    private let pageSize = 20
    
    init(playerRepository: PlayerRepository) {
        self.playerRepository = playerRepository
    }
    
    func loadPlayers() async {
        isLoading = true
        errorMessage = nil
        currentPage = 0
        
        do {
            players = try await playerRepository.fetchPlayersForSquadBuilding(
                position: selectedPosition,
                nation: selectedNation,
                priceUnder: maxPrice,
                sortType: sortType,
                limit: pageSize,
                offset: 0
            )
            
            hasMorePages = players.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading players: \(error)")
        }
        
        isLoading = false
    }
    
    func loadMorePlayers() async {
        guard hasMorePages, !isLoading else { return }
        
        isLoading = true
        currentPage += 1
        
        do {
            let nextPlayers = try await playerRepository.fetchPlayersForSquadBuilding(
                position: selectedPosition,
                nation: selectedNation,
                priceUnder: maxPrice,
                sortType: sortType,
                limit: pageSize,
                offset: currentPage * pageSize
            )
            
            players.append(contentsOf: nextPlayers)
            hasMorePages = nextPlayers.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading more players: \(error)")
        }
        
        isLoading = false
    }
    
    func search() async {
        guard !searchQuery.isEmpty else {
            await loadPlayers()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            players = try await playerRepository.searchPlayers(query: searchQuery)
            hasMorePages = false // No pagination for search
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error searching players: \(error)")
        }
        
        isLoading = false
    }
    
    func applyFilters(
        position: PlayerPosition?,
        nation: Nation?,
        maxPrice: Double?,
        sortType: PlayerSortType
    ) {
        self.selectedPosition = position
        self.selectedNation = nation
        self.maxPrice = maxPrice
        self.sortType = sortType
        
        Task {
            await loadPlayers()
        }
    }
}
