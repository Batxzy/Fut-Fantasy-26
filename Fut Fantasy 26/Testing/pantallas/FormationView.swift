//
//  FormationView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

import SwiftUI
import SwiftData

struct FormationView: View {
    let startingXI: [Player]
    let captain: Player?
    let viceCaptain: Player?
    let isDragMode: Bool
    let onPlayerTap: (Player) -> Void
    let onPlayerMove: (Int, Int) -> Void
    let playerRepository: PlayerRepository
    let squadRepository: SquadRepository
    
    @State private var draggedPlayer: Player?
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Pitch background
                pitchBackground
                
                if startingXI.isEmpty {
                    // Empty state
                    emptyPitchState
                } else {
                    VStack(spacing: 0) {
                        // Goalkeeper (1)
                        formationLine(
                            players: goalkeepers,
                            position: .goalkeeper,
                            geometry: geometry,
                            lineHeight: geometry.size.height * 0.15
                        )
                        
                        Spacer()
                        
                        // Defenders (4)
                        formationLine(
                            players: defenders,
                            position: .defender,
                            geometry: geometry,
                            lineHeight: geometry.size.height * 0.20
                        )
                        
                        Spacer()
                        
                        // Midfielders (3)
                        formationLine(
                            players: midfielders,
                            position: .midfielder,
                            geometry: geometry,
                            lineHeight: geometry.size.height * 0.20
                        )
                        
                        Spacer()
                        
                        // Forwards (3)
                        formationLine(
                            players: forwards,
                            position: .forward,
                            geometry: geometry,
                            lineHeight: geometry.size.height * 0.20
                        )
                        
                        Spacer().frame(height: 20)
                    }
                    .padding(.vertical, 20)
                }
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
                    Color.green.opacity(0.3),
                    Color.green.opacity(0.4),
                    Color.green.opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Pitch lines
            VStack(spacing: 0) {
                // Top box (Goalkeeper area)
                Rectangle()
                    .stroke(.white.opacity(0.4), lineWidth: 2)
                    .frame(height: 50)
                    .padding(.horizontal, 60)
                    .padding(.top, 10)
                
                Spacer()
                
                // Center circle
                Circle()
                    .stroke(.white.opacity(0.4), lineWidth: 2)
                    .frame(width: 80, height: 80)
                
                // Middle line
                Rectangle()
                    .fill(.white.opacity(0.4))
                    .frame(height: 2)
                    .offset(y: -40)
                
                Spacer()
                
                // Bottom box
                Rectangle()
                    .stroke(.white.opacity(0.4), lineWidth: 2)
                    .frame(height: 50)
                    .padding(.horizontal, 60)
                    .padding(.bottom, 10)
            }
            
            // Corner circles
            VStack {
                HStack {
                    cornerArc
                    Spacer()
                    cornerArc.rotation3DEffect(.degrees(90), axis: (x: 0, y: 1, z: 0))
                }
                Spacer()
                HStack {
                    cornerArc.rotation3DEffect(.degrees(-90), axis: (x: 1, y: 0, z: 0))
                    Spacer()
                    cornerArc.rotation3DEffect(.degrees(180), axis: (x: 1, y: 1, z: 0))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var cornerArc: some View {
        Circle()
            .trim(from: 0, to: 0.25)
            .stroke(.white.opacity(0.4), lineWidth: 2)
            .frame(width: 30, height: 30)
    }
    
    private var emptyPitchState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sportscourt")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.3))
            
            Text("No Starting XI Selected")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))
            
            Text("Add 11 players to your squad and set your starting lineup")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func formationLine(players: [Player], position: PlayerPosition, geometry: GeometryProxy, lineHeight: CGFloat) -> some View {
        HStack(spacing: 0) {
            if players.isEmpty {
                Spacer()
                EmptyPlayerSlot()
                Spacer()
            } else {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    Spacer()
                    
                    if isDragMode {
                        PitchPlayerCard(
                            player: player,
                            isCaptain: captain?.id == player.id,
                            isViceCaptain: viceCaptain?.id == player.id,
                            isDragMode: isDragMode
                        )
                        .opacity(draggedPlayer?.id == player.id ? 0.4 : 1.0)
                        .onDrag {
                            self.draggedPlayer = player
                            return NSItemProvider(object: "\(player.id)" as NSString)
                        }
                        .onDrop(of: ["public.text"], isTargeted: nil) { providers in
                            guard let sourcePlayerId = providers.first else { return false }
                            
                            var sourceIndex: Int = -1
                            var destinationIndex: Int = -1
                            
                            // Find source player's position in starting XI
                            for (i, p) in startingXI.enumerated() {
                                if p.id == draggedPlayer?.id {
                                    sourceIndex = i
                                }
                                if p.id == player.id {
                                    destinationIndex = i
                                }
                            }
                            
                            if sourceIndex != -1 && destinationIndex != -1 {
                                // Only allow swapping players of the same position
                                if startingXI[sourceIndex].position == startingXI[destinationIndex].position {
                                    onPlayerMove(sourceIndex, destinationIndex)
                                    draggedPlayer = nil
                                    return true
                                }
                            }
                            return false
                        }
                    } else {
                        NavigationLink(destination: PlayerDetailView(player: player, playerRepository: playerRepository, squadRepository: squadRepository)) {
                            PitchPlayerCard(
                                player: player,
                                isCaptain: captain?.id == player.id,
                                isViceCaptain: viceCaptain?.id == player.id,
                                isDragMode: isDragMode
                            )
                        }
                        .buttonStyle(.plain)
                        .onTapGesture {
                            if !isDragMode {
                                onPlayerTap(player)
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .frame(height: lineHeight)
    }
    
    // Computed properties for positions
    private var goalkeepers: [Player] {
        startingXI.filter { $0.position == .goalkeeper }
    }
    
    private var defenders: [Player] {
        let defs = startingXI.filter { $0.position == .defender }
        return Array(defs.prefix(4)) // Ensure max 4
    }
    
    private var midfielders: [Player] {
        let mids = startingXI.filter { $0.position == .midfielder }
        return Array(mids.prefix(3)) // Ensure max 3
    }
    
    private var forwards: [Player] {
        let fwds = startingXI.filter { $0.position == .forward }
        return Array(fwds.prefix(3)) // Ensure max 3
    }
}

// MARK: - Player Card Component

struct PitchPlayerCard: View {
    let player: Player
    let isCaptain: Bool
    let isViceCaptain: Bool
    let isDragMode: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                // Player card with flag and initials
                ZStack {
                    // Background circle with position color
                    Circle()
                        .fill(positionColor.opacity(0.9))
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    // White inner circle
                    Circle()
                        .fill(.white)
                        .frame(width: 56, height: 56)
                    
                    VStack(spacing: 2) {
                        // Country flag
                        AsyncImage(url: URL(string: player.nationFlagURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 32, height: 20)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .overlay {
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                        }
                        
                        // Player initials
                        Text(playerInitials)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.primary)
                    }
                }
                
                // Captain badge
                if isCaptain {
                    Text("C")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(.blue))
                        .overlay {
                            Circle().stroke(.white, lineWidth: 1.5)
                        }
                        .offset(x: 6, y: -6)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                } else if isViceCaptain {
                    Text("V")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(.purple))
                        .overlay {
                            Circle().stroke(.white, lineWidth: 1.5)
                        }
                        .offset(x: 6, y: -6)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
            
            // Player name
            Text(player.lastName.isEmpty ? player.name : player.lastName)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .frame(width: 70)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                )
            
            // Points
            Text("\(player.totalPoints)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(.black.opacity(0.6))
                )
        }
        .opacity(isDragMode ? 0.8 : 1.0)
        .scaleEffect(isDragMode ? 0.95 : 1.0)
        .animation(.spring(response: 0.3), value: isDragMode)
    }
    
    private var playerInitials: String {
        let firstInitial = player.firstName.prefix(1).uppercased()
        let lastInitial = player.lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
    
    private var positionColor: Color {
        switch player.position {
        case .goalkeeper: return Color.yellow
        case .defender: return Color.blue
        case .midfielder: return Color.green
        case .forward: return Color.red
        }
    }
}

// MARK: - Empty Player Slot

struct EmptyPlayerSlot: View {
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Text("Empty")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.1))
                )
        }
    }
}

// MARK: - Preview
#Preview {
    let container = SwiftDataManager.shared.previewContainer
    let contextProvider = ModelContextProvider(container: container)
    let mainContext = contextProvider.mainContext
    
    let playerRepository: PlayerRepository = SwiftDataPlayerRepository(modelContext: mainContext)
    let squadRepository: SquadRepository = SwiftDataSquadRepository(modelContext: mainContext, playerRepository: playerRepository)
    
    return ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea()
        
        VStack {
            // Preview with players
            FormationView(
                startingXI: [], // Empty for now
                captain: nil,
                viceCaptain: nil,
                isDragMode: false,
                onPlayerTap: { _ in },
                onPlayerMove: { _, _ in },
                playerRepository: playerRepository,
                squadRepository: squadRepository
            )
            .padding()
        }
    }
}
