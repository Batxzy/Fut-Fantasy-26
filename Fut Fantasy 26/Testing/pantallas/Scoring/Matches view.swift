//
//  Matches view.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 01/11/25.
//

import SwiftUI
import SwiftData

struct MatchesView: View {
    @State private var selectedDate: Date = Date()
    let dates: [Date]
    let fixtures: [Fixture]
    
    var filteredFixtures: [Fixture] {
        fixtures.filter { fixture in
            Calendar.current.isDate(fixture.kickoffTime, inSameDayAs: selectedDate)
        }
    }
    
    var body: some View {
        ZStack{
            Color(.mainBg)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                DateCapsuleSelector(
                    dates: dates,
                    selectedDate: $selectedDate
                )
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(filteredFixtures, id: \.id) { fixture in
                            MatchCard(fixture: fixture)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
       
    }
}


struct DateCapsuleSelector: View {
    let dates: [Date]
    @Binding var selectedDate: Date
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(dates, id: \.self) { date in
                    DateCapsule(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate)
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

struct DateCapsule: View {
    let date: Date
    let isSelected: Bool
    
    var formattedDate: String {
        let weekday = date.formatted(.dateTime.weekday(.abbreviated))
        let monthDay = date.formatted(.dateTime.month(.abbreviated).day())
        return "\(weekday), \(monthDay)"
    }
    
    var body: some View {
        Text(formattedDate)
            .font(.caption)
            .frame(width: 78, height: 18)
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(
                Capsule()
                    .fill(isSelected ? Color.grayMatch.opacity(0.2) : Color.grayMatch.opacity(0.62))
            )
            .foregroundColor(.white)
            .animation(.bouncy(duration: 0.4), value: isSelected)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Matchday.self, Fixture.self,
        configurations: config
    )
    
    let context = container.mainContext
    WorldCupDataSeeder.seedMatchdays(context: context)
    WorldCupDataSeeder.seedFixtures(context: context)
    
    let matchdays = try! context.fetch(FetchDescriptor<Matchday>())
    let fixtures = try! context.fetch(FetchDescriptor<Fixture>())
    let dates = matchdays.map { $0.deadline }
    
    return MatchesView(dates: dates, fixtures: fixtures)
        .modelContainer(container)
}

struct MatchCard: View {
    let fixture: Fixture
    
    var body: some View {
        
        HStack {
            VStack(alignment: .center, spacing: 8) {
                AsyncImage(url: URL(string: fixture.homeFlagURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 30, height: 30)
                .clipShape(Circle())
                
                Text(fixture.homeNation.rawValue)
                    .font(
                        Font.system(size: 16)
                            .weight(.bold)
                    )
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            Text(fixture.displayScore)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            VStack(alignment: .center, spacing: 8) {
                AsyncImage(url: URL(string: fixture.homeFlagURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 30, height: 30)
                .clipShape(Circle())
                
                Text(fixture.homeNation.rawValue)
                    .font(
                        Font.system(size: 16)
                            .weight(.bold)
                    )
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical,28)
        .frame(width: 330, height: 120)
        .background(.clear)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(red: 0.33, green: 0.33, blue: 0.33),
                            Color(red: 0.4, green: 0.9, blue: 0.8)
                        ],
                        startPoint: UnitPoint(x: 0.55, y: 0.84),
                        endPoint: UnitPoint(x: 0.5, y: -0.05)
                    ),
                    lineWidth: 2
                )
        )
    }
}

// MARK: - Standalone Preview for Design Focus
#Preview("Match Card Design") {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack(spacing: 20) {
            MatchCard(fixture: Fixture(
                id: 1,
                matchdayNumber: 1,
                homeNation: .england,
                awayNation: .mexico,
                kickoffTime: Date(),
                group: .c
            ))
            
            MatchCard(fixture: {
                let fixture = Fixture(
                    id: 2,
                    matchdayNumber: 1,
                    homeNation: .brazil,
                    awayNation: .argentina,
                    kickoffTime: Date(),
                    group: .g
                )
                fixture.homeScore = 3
                fixture.awayScore = 0
                fixture.isFinished = true
                return fixture
            }())
        }
    }
}
