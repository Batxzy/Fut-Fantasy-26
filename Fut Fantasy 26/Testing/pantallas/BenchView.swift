//
//  BenchView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


//
//  BenchView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

import SwiftUI

struct BenchView: View {
    let benchPlayers: [Player]
    let isDragMode: Bool
    let onSubstitution: (Player, Player) -> Void
    
    @State private var selectedBenchPlayer: Player?
    @State private var showingSubstitution = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundStyle(.secondary)
                Text("Bench")
                    .font(.headline)
                
                Spacer()
                
                Text("\(benchPlayers.count)/4")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if benchPlayers.isEmpty {
                ContentUnavailableView(
                    "No Bench Players",
                    systemImage: "person.crop.circle.badge.xmark",
                    description: Text("Add players to your bench")
                )
                .frame(height: 120)
            } else {
                HStack(spacing: 12) {
                    ForEach(benchPlayers, id: \.id) { player in
                        BenchPlayerCard(player: player)
                            .onTapGesture {
                                if isDragMode {
                                    selectedBenchPlayer = player
                                    showingSubstitution = true
                                }
                            }
                    }
                    
                    // Empty slots
                    ForEach(0..<(4 - benchPlayers.count), id: \.self) { _ in
                        EmptyBenchSlot()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        )
        .sheet(isPresented: $showingSubstitution) {
            if let benchPlayer = selectedBenchPlayer {
                SubstitutionSheet(
                    benchPlayer: benchPlayer,
                    onSubstitute: { startingPlayer in
                        onSubstitution(benchPlayer, startingPlayer)
                        showingSubstitution = false
                    }
                )
            }
        }
    }
}

struct BenchPlayerCard: View {
    let player: Player
    
    var body: some View {
        VStack(spacing: 6) {
            AsyncImage(url: URL(string: player.imageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(.quaternary)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(positionColor, lineWidth: 2)
            }
            
            Text(player.name)
                .font(.caption2)
                .lineLimit(1)
                .frame(width: 60)
            
            Text("\(player.totalPoints)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var positionColor: Color {
        switch player.position {
        case .goalkeeper: return .yellow
        case .defender: return .blue
        case .midfielder: return .green
        case .forward: return .red
        }
    }
}

struct EmptyBenchSlot: View {
    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundStyle(.quaternary)
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "plus")
                        .foregroundStyle(.secondary)
                }
            
            Text("Empty")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 60)
        }
        .padding(8)
    }
}

struct SubstitutionSheet: View {
    let benchPlayer: Player
    let onSubstitute: (Player) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var startingPlayers: [Player] = [] // Would come from squad
    
    var body: some View {
        NavigationStack {
            List(startingPlayers.filter { $0.position == benchPlayer.position }, id: \.id) { player in
                Button {
                    onSubstitute(player)
                } label: {
                    HStack {
                        PlayerRowView(player: player)
                        Spacer()
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Substitute \(benchPlayer.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}