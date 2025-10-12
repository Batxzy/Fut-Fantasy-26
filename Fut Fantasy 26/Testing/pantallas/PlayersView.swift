//
//  PlayersView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import SwiftUI
import SwiftData

struct PlayersView: View {
    let playerRepository: PlayerRepository
    
    @State private var players: [Player] = []
    @State private var isLoading = false
    @State private var showingFilters = false
    
    var body: some View {
        NavigationStack {
            playerList
                .navigationTitle("Players")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingFilters = true
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                        }
                    }
                }
                .sheet(isPresented: $showingFilters) {
                    // In a real app, PlayerFiltersView would bind to filters
                    // and call a method on this view to reload data.
                    PlayerFiltersView()
                }
                .task {
                    // Initial load
                    if players.isEmpty {
                        await loadPlayers()
                    }
                }
        }
    }
    
    private var playerList: some View {
        List(players, id: \.id) { player in
            NavigationLink {
                PlayerDetailView(player: player)
            } label: {
                PlayerRowView(player: player)
            }
        }
        .overlay {
            if isLoading {
                ProgressView("Loading...")
            } else if players.isEmpty {
                ContentUnavailableView("No Players", systemImage: "person.3.fill")
            }
        }
        .refreshable {
            await loadPlayers()
        }
    }
    
    private func loadPlayers() async {
        isLoading = true
        do {
            players = try await Task {
                try playerRepository.fetchTopPlayers(limit: 100)
            }.value
        } catch {
            print("Failed to fetch players: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Component Views
// This detailed PlayerRowView should be the only one in your project.
struct PlayerRowView: View {
    let player: Player
    
    var body: some View {
        HStack(spacing: 12) {
            // Player image
            AsyncImage(url: player.imageURL.isEmpty ? nil : URL(string: player.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.2))
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            // Player info
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    // Nation flag
                    AsyncImage(url: player.nationFlagURL.isEmpty ? nil : URL(string: player.nationFlagURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(width: 20, height: 12)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    
                    // Position
                    Text(player.position.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background {
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                        }
                }
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(player.totalPoints)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(player.displayPrice)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}


// MARK: - Placeholder Views for Preview
struct PlayerDetailView: View {
    let player: Player
    
    var body: some View {
        Text("Details for \(player.name)")
            .navigationTitle(player.name)
    }
}

struct PlayerFiltersView: View {
    var body: some View {
        Text("Player Filters")
    }
}

// MARK: - Preview
#Preview {
    // 1. Create the in-memory container from SwiftDataManager
    let container = SwiftDataManager.shared.previewContainer
    
    // 2. Create a context and seed the data
    let context = ModelContext(container)
    WorldCupDataSeeder.seedDataIfNeeded(context: context)
    
    // 3. Create the repository using the seeded container
    let contextProvider = ModelContextProvider(container: container)
    let playerRepository = PlayerRepository(contextProvider: contextProvider)
    
    // 4. Return the view, which will now fetch the seeded data
    return PlayersView(playerRepository: playerRepository)
        .modelContainer(container) // Attach the container to the view hierarchy
}
