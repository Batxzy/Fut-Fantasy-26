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
    let isEditMode: Bool
    
    @Binding var selectedSlot: PlayerSlot?
    let isPlayerTappable: (PlayerSlot) -> Bool
    let onPlayerTap: (PlayerSlot) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                pitchBackground
                
                if startingXI.isEmpty {
                    emptyPitchState
                } else {
                    VStack(spacing: 0) {
                        formationLine(
                            players: goalkeepers,
                            position: .goalkeeper,
                            geometry: geometry,
                            lineHeight: geometry.size.height * 0.15
                        )
                        
                        Spacer()
                        
                        formationLine(
                            players: defenders,
                            position: .defender,
                            geometry: geometry,
                            lineHeight: geometry.size.height * 0.20
                        )
                        
                        Spacer()
                        
                        formationLine(
                            players: midfielders,
                            position: .midfielder,
                            geometry: geometry,
                            lineHeight: geometry.size.height * 0.20
                        )
                        
                        Spacer()
                        
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
    
    // MARK: - Background Components
    
    private var pitchBackground: some View {
        ZStack {
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
            
            pitchLines
            cornerCircles
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var pitchLines: some View {
        VStack(spacing: 0) {
            Rectangle()
                .stroke(.white.opacity(0.4), lineWidth: 2)
                .frame(height: 50)
                .padding(.horizontal, 60)
                .padding(.top, 10)
            
            Spacer()
            
            Circle()
                .stroke(.white.opacity(0.4), lineWidth: 2)
                .frame(width: 80, height: 80)
            
            Rectangle()
                .fill(.white.opacity(0.4))
                .frame(height: 2)
                .offset(y: -40)
            
            Spacer()
            
            Rectangle()
                .stroke(.white.opacity(0.4), lineWidth: 2)
                .frame(height: 50)
                .padding(.horizontal, 60)
                .padding(.bottom, 10)
        }
    }
    
    private var cornerCircles: some View {
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
    
    // MARK: - Formation Line
    
    @ViewBuilder
    private func formationLine(
        players: [Player],
        position: PlayerPosition,
        geometry: GeometryProxy,
        lineHeight: CGFloat
    ) -> some View {
        HStack(spacing: 0) {
            if players.isEmpty {
                Spacer()
                EmptyPlayerSlot()
                Spacer()
            } else {
                ForEach(players) { player in
                    Spacer()
                    playerCard(for: player)
                        // Add ID and transition for animations
                        .id(player.id)
                        .transition(.asymmetric(
                            insertion: .scale.animation(.spring(response: 0.4, dampingFraction: 0.6)),
                            removal: .scale.animation(.spring(response: 0.3, dampingFraction: 0.7))
                        ))
                    Spacer()
                }
            }
        }
        .frame(height: lineHeight)
    }
    
    // MARK: - Player Card Builder
    
    private func playerCard(for player: Player) -> some View {
        let slot = PlayerSlot.starting(player)
        let isSelected = selectedSlot == slot
        let tappable = isPlayerTappable(slot)
        
        return PitchPlayerCard(
            player: player,
            isCaptain: captain?.id == player.id,
            isViceCaptain: viceCaptain?.id == player.id,
            isEditMode: isEditMode,
            isSelected: isSelected,
            isTappable: tappable
        )
        .onTapGesture {
            onPlayerTap(slot)
        }
    }
    
    // MARK: - Position Filters
    // **CRITICAL**: These maintain the order from startingXI array
    
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

// MARK: - Player Card Component

struct PitchPlayerCard: View {
    let player: Player
    let isCaptain: Bool
    let isViceCaptain: Bool
    let isEditMode: Bool
    let isSelected: Bool
    let isTappable: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                playerCircle
                captainBadge
            }
            
            playerName
            playerPoints
        }
        // Apply visual effects based on state
        .opacity(isEditMode && !isTappable ? 0.4 : 1.0)
        .grayscale(isEditMode && !isTappable ? 0.8 : 0)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isTappable)
    }
    
    private var playerCircle: some View {
        ZStack {
            Circle()
                .fill(positionColor.opacity(0.9))
                .frame(width: 60, height: 60)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            Circle()
                .fill(.white)
                .frame(width: 56, height: 56)
            
            VStack(spacing: 2) {
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
                
                Text(playerInitials)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
            }
        }
        .overlay(
            Circle()
                .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 4)
                .frame(width: 68, height: 68)
        )
    }
    
    @ViewBuilder
    private var captainBadge: some View {
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
    
    private var playerName: some View {
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
    }
    
    private var playerPoints: some View {
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

#Preview {
    struct FormationPreview: View {
        @State private var selectedSlot: PlayerSlot?
        
        let startingXI = MockData.startingXI
        let mbappe = MockData.mbappe
        let deBruyne = MockData.deBruyne
        
        var body: some View {
            ZStack {
                Color.gray.opacity(0.2).ignoresSafeArea()
                
                VStack {
                    FormationView(
                        startingXI: startingXI,
                        captain: mbappe,
                        viceCaptain: deBruyne,
                        isEditMode: true,
                        selectedSlot: $selectedSlot,
                        isPlayerTappable: { slot in
                            return true
                        },
                        onPlayerTap: { tappedSlot in
                            if selectedSlot == tappedSlot {
                                selectedSlot = nil
                            } else {
                                selectedSlot = tappedSlot
                            }
                        }
                    )
                    .padding()
                }
            }
        }
    }
    
    return FormationPreview()
}
#Preview {
    // A stateful view to host the preview
    struct FormationPreview: View {
        @State private var selectedSlot: PlayerSlot?
        
        // Dummy data for the preview
        let startingXI = MockData.startingXI
        let mbappe = MockData.mbappe
        let deBruyne = MockData.deBruyne
        
        var body: some View {
            ZStack {
                Color.gray.opacity(0.2).ignoresSafeArea()
                
                VStack {
                    FormationView(
                        startingXI: startingXI,
                        captain: mbappe,
                        viceCaptain: deBruyne,
                        isEditMode: true, // Set to true to see selection states
                        selectedSlot: $selectedSlot,
                        isPlayerTappable: { slot in
                            // Preview logic: allow all taps
                            return true
                        },
                        onPlayerTap: { tappedSlot in
                            // Preview logic: simulate selection
                            if selectedSlot == tappedSlot {
                                selectedSlot = nil
                            } else {
                                selectedSlot = tappedSlot
                            }
                        }
                    )
                    .padding()
                }
            }
        }
    }
    
    // Return the stateful preview wrapper
    return FormationPreview()
}
