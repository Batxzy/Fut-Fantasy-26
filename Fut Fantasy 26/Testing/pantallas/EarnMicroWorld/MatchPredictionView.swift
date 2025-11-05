//
//  AvailableMatchesView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 04/11/25.
//


import SwiftUI
import SwiftData

struct MatchPredictionView: View {
    @Query(FetchDescriptor<Squad>()) private var squads: [Squad]
    @Query(FetchDescriptor<Fixture>()) private var fixtures: [Fixture]
    
    var squad: Squad? {
        squads.first
    }
    
    // Get upcoming fixtures
    var upcomingFixtures: [Fixture] {
        fixtures.filter { $0.kickoffTime > Date() }
            .sorted { $0.kickoffTime < $1.kickoffTime }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        ZStack {
                Color(.mainBg)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        if let squad = squad, let firstFixture = upcomingFixtures.first {
                            AvailableMatchesHeader(
                                squad: squad,
                                date: firstFixture.kickoffTime,
                                stage: getStageDisplay(for: firstFixture)
                            )
                        }
                        
                        VStack(spacing: 18) {
                            ForEach(upcomingFixtures, id: \.id) { fixture in
                                PredictionsCard(fixture: fixture)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
        
    }
    
    // Helper function to get stage display name
    private func getStageDisplay(for fixture: Fixture) -> String {
        if let group = fixture.group {
            return group.rawValue.uppercased()
        } else if let stage = fixture.knockoutStage {
            switch stage {
            case .roundOf16:
                return "Round of 16"
            case .quarterFinals:
                return "Quarter Finals"
            case .semiFinals:
                return "Semi Finals"
            case .thirdPlace:
                return "Third Place"
            case .final:
                return "Final"
            default:
                return "Group Stage"
            }
        }
        return "Group Stage"
    }
}

// MARK: - Available Matches Header
private func AvailableMatchesHeader(squad: Squad, date: Date, stage: String) -> some View {
    HStack (alignment: .top){
        VStack(alignment: .leading, spacing: 4) {
            Text("Available matches")
                .font(.system(size: 28, weight: .regular))
                .fontWidth(.condensed)
                .foregroundStyle(.white)
            
            Text(date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().year()))
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))
                .fontWidth(.condensed)
            
            Text(stage)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(.white.opacity(0.7))
                .fontWidth(.condensed)
        }
        
        Spacer()
            HStack(spacing: 3) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color.white)
                Text(squad.displayBudgetNoDecimals)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }
        
    }
    .padding(.horizontal, 26)
    .padding(.top, 12)
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Player.self, Squad.self, Fixture.self,
        configurations: config
    )
    
    let context = container.mainContext
    WorldCupDataSeeder.seedDataIfNeeded(context: context)
    WorldCupDataSeeder.seedFixtures(context: context)
    
    let squad = Squad(teamName: "Preview Team", ownerName: "Preview")
    context.insert(squad)
    
    let fetchDescriptor = FetchDescriptor<Player>(
        sortBy: [SortDescriptor(\.totalPoints, order: .reverse)]
    )
    
    if let allPlayers = try? context.fetch(fetchDescriptor) {
        squad.players = Array(allPlayers.prefix(15))
    }
    
    try? context.save()
    
    return MatchPredictionView()
        .modelContainer(container)
}
