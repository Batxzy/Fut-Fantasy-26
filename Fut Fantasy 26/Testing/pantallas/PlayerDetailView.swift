//
//  PlayerDetailView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 13/10/25.
//
 import SwiftData
 import SwiftUI

struct PlayerDetailView: View {
    let player: Player
    @Bindable var viewModel: PlayerViewModel
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    
    // ✅ @Query to observe squad changes
    @Query private var squads: [Squad]
    
    @State private var showingAddConfirmation = false
    @State private var isProcessing = false
    
    var currentSquad: Squad? {
        squads.first
    }
    
    var isInSquad: Bool {
        currentSquad?.players?.contains(where: { $0.id == player.id }) ?? false
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                playerHeader
                
                // ADD TO SQUAD BUTTON
                actionButton
                    .padding(.horizontal)
                
                // Error message
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
                
                // Stats
                statsSection
                
                // Information
                infoSection
                
                Spacer()
            }
        }
        .navigationTitle("Player Details")
        .navigationBarTitleDisplayMode(.inline)
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
        VStack(spacing: 12) {
            AsyncImage(url: player.imageURL.isEmpty ? nil : URL(string: player.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.2))
            }
            .frame(width: 120, height: 120)
            .clipShape(Circle())
            
            Text(player.name)
                .font(.title)
                .fontWeight(.bold)
            
            HStack(spacing: 12) {
                AsyncImage(url: player.nationFlagURL.isEmpty ? nil : URL(string: player.nationFlagURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 32, height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
                Text(player.nation.rawValue)
                    .font(.subheadline)
                
                Text("•")
                
                Text(player.position.rawValue)
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)
        }
        .padding()
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
                    if isProcessing {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Label("Add to Squad", systemImage: "plus.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled(isProcessing)
            }
        } else {
            ProgressView()
        }
    }
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            HStack {
                StatBox(title: "Total Points", value: "\(player.totalPoints)")
                StatBox(title: "Price", value: player.displayPrice)
            }
            
            HStack {
                StatBox(title: "Form", value: "\(player.matchdayPoints)")
                StatBox(title: "Appearances", value: "\(player.appearances)")
            }
        }
        .padding(.horizontal)
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
    
    // MARK: - Actions
    
    private func addPlayerToSquad() async {
        guard let squad = currentSquad else { return }
        
        isProcessing = true
        
        // Create a SquadViewModel instance to handle the write
        let squadViewModel = SquadViewModel(
            squadRepository: squadRepository,
            playerRepository: playerRepository
        )
        
        await squadViewModel.addPlayerToSquad(player, squadId: squad.id)
        
        if let error = squadViewModel.errorMessage {
            viewModel.errorMessage = error
        }
        
        isProcessing = false
    }
}
