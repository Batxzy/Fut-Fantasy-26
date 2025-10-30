//
//  PitchPlayerCard.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 28/10/25.
//

import SwiftUI
import SwiftData

// MARK: - Player Card Component

struct PitchPlayerCard: View {
    let player: Player
    let isCaptain: Bool
    let isViceCaptain: Bool
    let isEditMode: Bool
    let isSelected: Bool
    let isTappable: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                playerCircle

                captainBadge
            }
            
            playerName
        }
        .opacity(isEditMode && !isTappable ? 0.4 : 1.0)
        .grayscale(isEditMode && !isTappable ? 0.8 : 0)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: [isSelected,isTappable])
    }
    
    private var playerCircle: some View {
        ZStack {
            
            Circle()
                .fill(.white)
                .frame(width: 65, height: 65)
            
                // imagen del pais
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
    
        }
        .overlay(
            Circle()
                .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 4)
                .frame(width: 60, height: 60)
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
        Text(formattedPlayerName)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.black)
            .lineLimit(1)
            .minimumScaleFactor(0.95)
            .frame(width: 65)
            .frame(maxHeight: 15)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
            )
    }
    
    private var formattedPlayerName: String {
        if player.lastName.isEmpty {
            return player.name
        }
        
        let firstInitial = player.firstName.prefix(1).uppercased()
        return "\(firstInitial). \(player.lastName)"
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
    let position: PlayerPosition
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.grayBg)
                    .frame(width: 60, height: 60)
                
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.5))
            }
            
            Text(position.rawValue)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.black.opacity(0.6))
                .frame(width: 65)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.grayBg)
                )
        }
        .onTapGesture {
            onTap()
        }
    }
}


#Preview {
    let samplePlayer = Player(
        id: 10,
        name: "Messi",
        firstName: "Lionel",
        lastName: "Messi",
        position: .forward,
        nation: .argentina,
        shirtNumber: 10,
        price: 10.5
    )
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Player.self, Squad.self, configurations: config)
    
    container.mainContext.insert(samplePlayer)
    
    return PitchPlayerCard(
        player: samplePlayer,
        isCaptain: false,
        isViceCaptain: true,
        isEditMode: true,
        isSelected: false,
        isTappable: true
    )
    .modelContainer(container)
}

#Preview("Empty Slot") {
    EmptyPlayerSlot(position: .defender, onTap: {})
        .padding(50)
        .background(Color.pitchGreenDark) // So you can see the white elements
}
