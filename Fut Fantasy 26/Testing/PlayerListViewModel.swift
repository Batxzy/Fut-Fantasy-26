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
class PlayerListViewModel {
    // Dependencies
    private let playerRepository: PlayerRepository
    
    // State
    var players: [Player] = []
    var isLoading = false
    var error: Error?
    var currentPage = 0
    var hasMorePages = true
    
    // Filters
    var selectedPosition: PlayerPosition?
    var selectedNation: Nation?
    var maxPrice: Double?
    var searchQuery = ""
    var sortType: PlayerRepository.SortType = .points
    
    // Constants
    private let pageSize = 20
    
    init(playerRepository: PlayerRepository) {
        self.playerRepository = playerRepository
        
        Task {
            await loadPlayers()
        }
    }
    
    @MainActor
    func loadPlayers() async {
        isLoading = true
        currentPage = 0
        
        do {
            players = try playerRepository.fetchPlayersForSquadBuilding(
                position: selectedPosition,
                nation: selectedNation,
                priceUnder: maxPrice,
                sortType: sortType,
                limit: pageSize,
                offset: 0
            )
            
            hasMorePages = players.count == pageSize
        } catch {
            self.error = error
            print("Error loading players: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func loadMorePlayers() async {
        guard hasMorePages, !isLoading else { return }
        
        isLoading = true
        currentPage += 1
        
        do {
            let nextPlayers = try playerRepository.fetchPlayersForSquadBuilding(
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
            self.error = error
            print("Error loading more players: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func search() async {
        guard !searchQuery.isEmpty else {
            await loadPlayers()
            return
        }
        
        isLoading = true
        
        do {
            players = try playerRepository.searchPlayers(query: searchQuery)
            hasMorePages = false // No pagination for search
        } catch {
            self.error = error
            print("Error searching players: \(error)")
        }
        
        isLoading = false
    }
    
    func applyFilters(
        position: PlayerPosition?,
        nation: Nation?,
        maxPrice: Double?,
        sortType: PlayerRepository.SortType
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