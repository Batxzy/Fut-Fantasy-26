//
//  Matches view.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 01/11/25.
//

import SwiftUI
import SwiftData

struct MatchesView: View {
    @State private var selectedDate: Date?
    let dates: [Date]
    let fixtures: [Fixture]
    
    var groupedFixtures: [(Date, [Fixture])] {
        let grouped = Dictionary(grouping: fixtures) { fixture in
            Calendar.current.startOfDay(for: fixture.kickoffTime)
        }
        return grouped.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            DateCapsuleSelector(
                dates: dates,
                selectedDate: Binding(
                    get: { selectedDate },
                    set: { selectedDate = $0 }
                )
            )
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        ForEach(groupedFixtures, id: \.0) { date, dayFixtures in
                            MatchesPerDayCard(
                                date: date,
                                fixtures: dayFixtures
                            )
                            .id(date)
                            .padding(.horizontal, 28)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: selectedDate) { oldValue, newValue in
                    if let newValue = newValue {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(Calendar.current.startOfDay(for: newValue), anchor: .top)
                        }
                    }
                }
            }
        }
    }
}

struct DateCapsuleSelector: View {
    let dates: [Date]
    @Binding var selectedDate: Date?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(dates, id: \.self) { date in
                    DateCapsule(
                        date: date,
                        isSelected: selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!)
                    )
                    .onTapGesture {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal, 28)
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


//MARK: - Match card
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
            .frame(width: 100)
            
            Spacer()
            
            Text(fixture.displayScore)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            VStack(alignment: .center, spacing: 8) {
                AsyncImage(url: URL(string: fixture.awayFlagURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 30, height: 30)
                .clipShape(Circle())
                
                Text(fixture.awayNation.rawValue)
                    .font(
                        Font.system(size: 16)
                            .weight(.bold)
                    )
                    .foregroundColor(.white)
            }
            .frame(width:100)
        }
        .padding(.horizontal, 12)
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

//MARK: -MatchesPerDayCard


struct MatchesPerDayCard: View {
    let date: Date
    let fixtures: [Fixture]
    
    var formattedDate: String {
        date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().year())
    }
    
    var tournamentInfo: String {
        if let firstFixture = fixtures.first {
            if let group = firstFixture.group {
                return "Group \(group.rawValue.uppercased())"
            } else if let stage = firstFixture.knockoutStage {
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
        }
        return "Group Stage"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.white).opacity(0.8)
                
                Text(tournamentInfo)
                    .font(.system(size: 10 , weight: .light))
                    .foregroundColor(.white).opacity(0.8)
            }
                    
            VStack(spacing: 12) {
                ForEach(fixtures, id: \.id) { fixture in
                    MatchCard(fixture: fixture)
                }
            }
        }
    }
}

//MARK: - Preview Matches view
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



//MARK: - Preview Matches view**
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
    let dates = matchdays.map { $0.deadline }.sorted()
    
    return MatchesView(dates: dates, fixtures: fixtures)
        .modelContainer(container)
}
