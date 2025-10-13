//
//  PlayerRowView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 13/10/25.
//


import SwiftUI

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