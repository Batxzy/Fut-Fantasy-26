//
//  PlayerRowView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 13/10/25.
//


import SwiftUI
import SwiftData

import SwiftUI
import SwiftData

struct PlayerRowView: View {
    let player: Player
    
    var body: some View {
        HStack(spacing: 12) {
            
            Image(player.imageURL)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .padding(.top,3)
            .frame(width: 45, height: 45)
            .background(.white)
            .clipShape(Circle())
            
            
            Rectangle()
                .foregroundStyle(Color.wpAqua)
                .frame(width: 2, height: 38)
            
            // Player info
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(player.name)
                        .font(Font.custom("SF Compact", size: 18))
                        .lineLimit(1)
                        .minimumScaleFactor(0.95)
                    
                    HStack(spacing: 2) {
                        Image(systemName: "star.circle.fill")
                            .foregroundStyle(Color.wpAqua)
                        
                        Text(String(format: "%.1fM", player.price))
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
}

extension PlayerPosition {
    var displayColor: Color {
        switch self {
        case .goalkeeper:
            return .wpGreen
        case .defender:
            return .wpBlue
        case .midfielder:
            return .wpPurple
        case .forward:
            return .wpred
        }
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container: ModelContainer
    
    do {
        container = try ModelContainer(
            for: Player.self,
            configurations: config
        )
    } catch {
        fatalError("Failed to create preview container")
    }
    
    let context = container.mainContext
    WorldCupDataSeeder.seedDataIfNeeded(context: context)
    
    return List {
        PlayerRowView(player: MockData.messi)
        PlayerRowView(player: MockData.mbappe)
        PlayerRowView(player: MockData.kane)
    }
    .modelContainer(container)
}
