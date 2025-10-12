//
//  FormationView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


//
//  FormationView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

import SwiftUI

struct FormationView: View {
    let startingXI: [Player]
    let captain: Player?
    let viceCaptain: Player?
    let isDragMode: Bool
    let onPlayerTap: (Player) -> Void
    let onPlayerMove: (Int, Int) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Pitch background
                pitchBackground
                
                VStack(spacing: 0) {
                    // Goalkeeper
                    formationLine(
                        players: goalkeepers,
                        geometry: geometry,
                        lineHeight: geometry.size.height * 0.15
                    )
                    
                    Spacer()
                    
                    // Defenders (4)
                    formationLine(
                        players: defenders,
                        geometry: geometry,
                        lineHeight: geometry.size.height * 0.25
                    )
                    
                    Spacer()
                    
                    // Midfielders (3)
                    formationLine(
                        players: midfielders,
                        geometry: geometry,
                        lineHeight: geometry.size.height * 0.25
                    )
                    
                    Spacer()
                    
                    // Forwards (3)
                    formationLine(
                        players: forwards,
                        geometry: geometry,
                        lineHeight: geometry.size.height * 0.25
                    )
                }
                .padding(.vertical, 20)
            }
        }
        .aspectRatio(0.7, contentMode: .fit)
    }
    
    private var pitchBackground: some View {
        ZStack {
            // Grass texture
            LinearGradient(
                colors: [
                    Color.green.opacity(0.3),
                    Color.green.opacity(0.4),
                    Color.green.opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Pitch lines
            VStack {
                // Top box
                Rectangle()
                    .stroke(.white.opacity(0.3), lineWidth: 2)
                    .frame(height: 60)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Middle line
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(height: 2)
                
                Spacer()
                
                // Bottom box
                Rectangle()
                    .stroke(.white.opacity(0.3), lineWidth: 2)
                    .frame(height: 60)
                    .padding(.horizontal, 40)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func formationLine(players: [Player], geometry: GeometryProxy, lineHeight: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                Spacer()
                
                PitchPlayerCard(
                    player: player,
                    isCaptain: captain?.id == player.id,
                    isViceCaptain: viceCaptain?.id == player.id,
                    isDragMode: isDragMode
                )
                .onTapGesture {
                    if !isDragMode {
                        onPlayerTap(player)
                    }
                }
                
                Spacer()
            }
        }
        .frame(height: lineHeight)
    }
    
    // Computed properties for positions
    private var goalkeepers: [Player] {
        startingXI.filter { $0.position == .goalkeeper }
    }
    
    private var defenders: [Player] {
        startingXI.filter { $0.position == .defender }
    }
    
    private var midfielders: [Player] {
        startingXI.filter { $0.position == .midfielder }
    }
    
    private var forwards: [Player] {
        startingXI.filter { $0.position == .forward }
    }
}

struct PitchPlayerCard: View {
    let player: Player
    let isCaptain: Bool
    let isViceCaptain: Bool
    let isDragMode: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                // Player shirt/image
                Circle()
                    .fill(.regularMaterial)
                    .frame(width: 50, height: 50)
                    .overlay {
                        AsyncImage(url: URL(string: player.imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Text(player.name.prefix(1))
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                    }
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(positionColor, lineWidth: 2)
                    }
                
                // Captain badge
                if isCaptain {
                    Text("C")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(.blue))
                        .offset(x: 4, y: -4)
                } else if isViceCaptain {
                    Text("V")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(.purple))
                        .offset(x: 4, y: -4)
                }
            }
            
            // Player name
            Text(player.name)
                .font(.caption2)
                .fontWeight(.semibold)
                .lineLimit(1)
                .frame(width: 60)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(.regularMaterial)
                )
            
            // Points
            Text("\(player.totalPoints)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .opacity(isDragMode ? 0.8 : 1.0)
        .scaleEffect(isDragMode ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: isDragMode)
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