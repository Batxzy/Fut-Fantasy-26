//
//  PlayerDetailView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 13/10/25.
//
 import SwiftData
 import SwiftUI

// MARK: - Actions



struct PlayerDetailView: View {
    
    let player: Player
    @Bindable var viewModel: PlayerViewModel
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    
    @Query private var squads: [Squad]
    
    @State private var showingAddConfirmation = false
    
    var currentSquad: Squad? {
        squads.first
    }
    
    var isInSquad: Bool {
        currentSquad?.players?.contains(where: { $0.id == player.id }) ?? false
    }
    
    private func addPlayerToSquad() async {
        guard let squad = currentSquad else { return }
                
        do {
            try await squadRepository.addPlayerToSquad(playerId: player.id, squadId: squad.id)
            print("✅ [PlayerDetail] Player added successfully")
        } catch {
            viewModel.errorMessage = error.localizedDescription
            print("❌ [PlayerDetail] Failed to add player: \(error)")
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.mainBg)
                .ignoresSafeArea()
            
            ScrollView {
                ZStack(alignment: .top) {
                    GeometryReader { geometry in
                        let minY = geometry.frame(in: .global).minY
                        let scale = max(1.0, 1.0 + (minY / 500))
                        
                        Image("Vector")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width)
                            .scaleEffect(scale)
                            .offset(y: -minY - 1)
                    }
                    .frame(height: 200)
                    
                    GeometryReader { geometry in
                        let minY = geometry.frame(in: .global).minY
                        
                        VStack(spacing: 0) {
                            LinearGradient(
                                stops: [
                                    Gradient.Stop(color: .mainBg.opacity(0), location: 0.00),
                                    Gradient.Stop(color: .mainBg.opacity(0), location: 0.7),
                                    Gradient.Stop(color: .mainBg, location: 1.00),
                                ],
                                startPoint: UnitPoint(x: 0.5, y: 0),
                                endPoint: UnitPoint(x: 0.5, y: 1)
                            )
                            .frame(height: 200)
                            
                            Color.mainBg
                        }
                        .offset(y: -minY - 1)
                    }
                    .allowsHitTesting(false)
                    
                    VStack(spacing: 20) {
                        Color.clear.frame(height: 140)
                        
                        playerHeader
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(.grayBg.opacity(0.8))
                            .padding(.horizontal, 20)
                        
                        statsSection
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
            
            actionButton
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.hidden, for: .navigationBar)
        
        .alert("Add \(player.name)?", isPresented: $showingAddConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Add", role: .none) {
                Task {
                    await addPlayerToSquad()
                }
            }
        } message: {
            Text("Add \(player.name) to your squad for \(player.displayPrice)?")
        }
    }
    
    // MARK: - View Components
    
    private var playerHeader: some View {
        
        HStack(spacing:10){
            AsyncImage(url: player.imageURL.isEmpty ? nil : URL(string: player.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.2))
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())

            VStack(alignment: .center){
                HStack(spacing: 12){
                    Rectangle()
                        .foregroundStyle(Color.wpAqua)
                        .frame(width: 2, height: 38)
                    
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 5) {
                            Text(player.name)
                                .font(Font.custom("SF Compact", size: 18))
                                .lineLimit(1)
                                .minimumScaleFactor(0.95)
                            
                            HStack(spacing: 3) {
                                Image(systemName: "star.circle.fill")
                                    .foregroundStyle(Color.wpAqua)
                                
                                Text(String(format: "%.0fM", player.price))
                                    .font(Font.custom("SF Compact", size: 15))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack(spacing: 8) {
                            Text(player.position.rawValue)
                                .font(.caption.bold())
                                .foregroundStyle(player.position == .goalkeeper ? .black : .white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background {
                                    Capsule()
                                        .fill(player.position.displayColor)
                                }
                            
                            Text(player.nationName)
                                .font(Font.custom("SF Compact", size: 15))
                                .foregroundColor(.white.opacity(0.68))
                        }
                    }
                }
            }
            .padding(10)
            .padding(.bottom ,5)
            .frame(height: 100, alignment: .bottom)
            
            
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        if let squad = currentSquad {
            if isInSquad {
                Label("In Squad", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.green.opacity(0.2))
                    .foregroundStyle(.green)
                    .cornerRadius(12)
            } else if squad.isFull {
                Label("Squad Full (15/15)", systemImage: "person.3.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.orange.opacity(0.2))
                    .foregroundStyle(.orange)
                    .cornerRadius(12)
            } else if squad.currentBudget < player.price {
                Label("Can't Afford", systemImage: "exclamationmark.triangle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.red.opacity(0.2))
                    .foregroundStyle(.red)
                    .cornerRadius(12)
            } else {
                Button {
                    showingAddConfirmation = true
                } label: {
                    Label("Add to Squad", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
            }
        } else {
            // Replace ProgressView with a "Create Squad" message
            Label("No Squad Available", systemImage: "exclamationmark.triangle")
                .frame(maxWidth: .infinity)
                .padding()
                .background(.gray.opacity(0.2))
                .foregroundStyle(.secondary)
                .cornerRadius(12)
        }
    }
    
    private var statsSection: some View {
        
        VStack(alignment: .leading, spacing: 12){
            
            Text("stats")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                StatRow(label: "Total Points", value: "\(player.totalPoints)")
                Divider()
                StatRow(label: "Matchday Points", value: "\(player.matchdayPoints)")
                Divider()
                StatRow(label: "Price", value: player.displayPriceNoDecimals,)
                Divider()
                StatRow(label: "Appearances", value: "\(player.appearances)")
            }
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
        }
        
        
    }
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Information")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                InfoRow(label: "Full Name", value: "\(player.firstName) \(player.lastName)")
                Divider()
                InfoRow(label: "Shirt Number", value: "#\(player.shirtNumber)")
                Divider()
                InfoRow(label: "Group", value: player.group?.rawValue ?? "N/A")
            }
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
        }
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container: ModelContainer
    
    do {
        container = try ModelContainer(
            for: Player.self, Squad.self,
            configurations: config
        )
    } catch {
        fatalError("Failed to create preview container")
    }
    
    let context = container.mainContext
    WorldCupDataSeeder.seedDataIfNeeded(context: context)
    
    let playerRepo = SwiftDataPlayerRepository(modelContext: context)
    let squadRepo = SwiftDataSquadRepository(modelContext: context, playerRepository: playerRepo)
    
    return NavigationStack {
        PlayerDetailView(
            player: MockData.messi,
            viewModel: PlayerViewModel(repository: playerRepo),
            playerRepository: playerRepo,
            squadRepository: squadRepo
        )
    }
    .modelContainer(container)
}

extension Player {
    var displayPriceNoDecimals: String {
        return String(format: "$%.0fM", price)
    }
}
