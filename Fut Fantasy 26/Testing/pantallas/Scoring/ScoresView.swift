//
//  ScoresView.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 01/11/25.
//

import SwiftUI
import SwiftData

struct ScoresView: View {
    @State private var selectedTab: Tab = .matches
    
    @Query private var matchdays: [Matchday]
    @Query private var fixtures: [Fixture]
    
    enum Tab: String, CaseIterable {
        case matches = "Matches"
        case standings = "Standings"
    }
    
    var dates: [Date] {
        matchdays.map { $0.deadline }.sorted()
    }
    
    var body: some View {
        ZStack {
            Color(.mainBg)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Picker("View", selection: $selectedTab) {
                        ForEach(Tab.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .frame(height: 60)
                
                switch selectedTab {
                case .matches:
                    MatchesView(dates: dates, fixtures: fixtures)
                case .standings:
                    StandingsView()
                }
            }
        }
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Matchday.self, Fixture.self, TeamStandings.self,
        configurations: config
    )
    
    let context = container.mainContext
    WorldCupDataSeeder.seedMatchdays(context: context)
    WorldCupDataSeeder.seedFixtures(context: context)
    WorldCupDataSeeder.seedStandings(context: context)
    
    return ScoresView()
        .modelContainer(container)
}
