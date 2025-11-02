//
//  StandingsView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 01/11/25.
//

import SwiftUI
import SwiftData

struct StandingsView: View {
    @Query(sort: \TeamStandings.position) private var standings: [TeamStandings]
    
    var body: some View {
        ZStack {
            Color(.mainBg)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    HStack(spacing: 0) {
                        Text("Pos")
                            .frame(width: 50)
                        Text("Nation")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("PTS")
                            .frame(width: 50)
                        Text("GD")
                            .frame(width: 50)
                        Text("PTS")
                            .frame(width: 50)
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.wpPurpleDeep.opacity(0.8))
                    )
                    .padding(.horizontal, 16)
                    
                    VStack(spacing: 2) {
                        ForEach(Array(standings.enumerated()), id: \.element.id) { index, standing in
                            StandingRow(standing: standing, showBackground: index % 2 == 0)
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(red: 0.3, green: 0.32, blue: 0.31).opacity(0.29))
                            .padding(.horizontal, 16)
                    )
                }
                .padding(.vertical, 16)
            }
        }
    }
}

struct StandingRow: View {
    let standing: TeamStandings
    let showBackground: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            Text("\(standing.position)")
                .frame(width: 50)
            
            Text(standing.nation.rawValue)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("\(standing.played)")
                .frame(width: 50)
            
            Text("\(standing.goalDifference)")
                .frame(width: 50)
            
            Text("\(standing.points)")
                .frame(width: 50)
        }
        .font(.system(size: 14))
        .foregroundColor(.white)
        .frame(height: 36)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(showBackground ? Color.wpPurpleLilac.opacity(0.2) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    showBackground ? LinearGradient(
                        colors: [
                            Color(red: 0.33, green: 0.33, blue: 0.33),
                            Color(red: 0.47, green: 0.33, blue: 0.97),
                        ],
                        startPoint: UnitPoint(x: 0.55, y: 0.84),
                        endPoint: UnitPoint(x: 0.5, y: -0.05)
                    ) : LinearGradient(
                        colors: [Color.clear, Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 16)
    }
}

// Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: TeamStandings.self,
        configurations: config
    )
    
    let context = container.mainContext
    WorldCupDataSeeder.seedStandings(context: context)
    
    return StandingsView()
        .modelContainer(container)
}
