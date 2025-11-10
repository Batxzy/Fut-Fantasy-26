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
    
    var sortedFixtures: [Fixture] {
        fixtures.sorted { $0.id < $1.id }
    }
    
    var groupedFixtures: [(Date, [Fixture])] {
        let grouped = Dictionary(grouping: fixtures) { fixture in
            Calendar.current.startOfDay(for: fixture.kickoffTime)
        }
        return grouped.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }
    
    private func styleForDate(_ date: Date) -> DateCapsuleStyle {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        
        guard let index = dates.firstIndex(where: {
            calendar.startOfDay(for: $0) == targetDay
        }) else {
            return datePickerStyles[0]
        }
        
        return datePickerStyles[index % datePickerStyles.count]
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
                                fixtures: dayFixtures,
                                style: styleForDate(date)
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

// MARK: - Color Style System
struct DateCapsuleStyle {
    let background: Color
    let accent: Color
}

// Predefined color styles
let datePickerStyles: [DateCapsuleStyle] = [
    DateCapsuleStyle(background: .wpBlueOcean, accent: .wpMint),
    DateCapsuleStyle(background: .wpPurpleDeep, accent: .wpGreenYellow),
    DateCapsuleStyle(background: .wpMagenta, accent: .wpGreenLime),
    DateCapsuleStyle(background: .wpRedDark, accent: .wpRedOrange),
    DateCapsuleStyle(background: .wpBlueSky, accent: .wpAqua),
    DateCapsuleStyle(background: .wpPurpleOrchid, accent: .wpMint)
]

struct DateCapsuleSelector: View {
    let dates: [Date]
    @Binding var selectedDate: Date?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(dates.enumerated()), id: \.element) { index, date in
                    DateCapsule(
                        date: date,
                        isSelected: selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!),
                        style: datePickerStyles[index % datePickerStyles.count]
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
    let style: DateCapsuleStyle
    
    var formattedDate: String {
        let weekday = date.formatted(.dateTime.weekday(.abbreviated))
        let monthDay = date.formatted(.dateTime.month(.abbreviated).day())
        return "\(weekday), \(monthDay)"
    }
    
    var body: some View {
        Text(formattedDate)
            .textStyle(.caption, weight: .bold)
            .foregroundStyle(style.accent)
            .padding(.vertical, 4)
            .padding(.horizontal, 20)
            .background(
                Capsule()
                    .fill(isSelected ? style.background : style.background.opacity(0.60))
            )
            .foregroundColor(isSelected ? style.accent : .white)
            .animation(.bouncy(duration: 0.4), value: isSelected)
    }
}

struct MatchCard: View {
    let fixture: Fixture
    let style: DateCapsuleStyle
    
    var body: some View {
        VStack(spacing: 0) {
            // Top accent bar
            Rectangle()
            .fill(style.background.opacity(0.9))
            .overlay(Color.white.opacity(0.3))
            .frame(height: 22)
            
            // Match content
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
                    .overlay {
                        Circle()
                            .stroke(Color.black, lineWidth: 1)
                    }
                    
                    Text(fixture.homeNation.rawValue)
                        .textStyle(.caption, weight: .bold)
                        .foregroundColor(style.accent)
                }
                .frame(width: 100)
                
                Spacer()
                
                Text(fixture.displayScore)
                    .textStyle(.h1, weight: .bold)
                    .foregroundColor(style.accent)
                
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
                    .overlay {
                        Circle()
                            .stroke(Color.black, lineWidth: 1)
                    }
                    
                    Text(fixture.awayNation.rawValue)
                        .textStyle(.caption, weight: .bold)
                        .foregroundColor(style.accent)
                }
                .frame(width:100)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
        }
        .frame(width: 330, height: 108)
        .background(style.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

//**MARK: -MatchesPerDayCard**
struct MatchesPerDayCard: View {
    let date: Date
    let fixtures: [Fixture]
    let style: DateCapsuleStyle
    
    var formattedDate: String {
        date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().year())
    }
    
    var tournamentInfo: String {
        if let firstFixture = fixtures.first {
            if let group = firstFixture.group {
                return group.rawValue.uppercased()
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
                    .textStyle(.caption)
                    .foregroundColor(.white).opacity(0.8)
                
                Text(tournamentInfo)
                    .textStyle(.caption)
                    .foregroundColor(.white).opacity(0.8)
            }
                    
            VStack(spacing: 20) {
                ForEach(fixtures, id: \.id) { fixture in
                    MatchCard(fixture: fixture, style: style)
                }
            }
        }
    }
}

//**MARK: - Preview Matches view**
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
