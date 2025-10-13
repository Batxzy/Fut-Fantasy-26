//
//  MockData.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 13/10/25.
//


import Foundation

// A utility for creating mock data for previews and testing.
struct MockData {
    
    // MARK: - Players
    
    static let alisson = Player(id: 1, name: "Alisson", firstName: "Alisson", lastName: "Becker", position: .goalkeeper, nation: .brazil, shirtNumber: 1, price: 6.0, group: .g)
    static let vanDijk = Player(id: 2, name: "Van Dijk", firstName: "Virgil", lastName: "van Dijk", position: .defender, nation: .netherlands, shirtNumber: 4, price: 6.5, group: .a)
    static let rudiger = Player(id: 3, name: "Rüdiger", firstName: "Antonio", lastName: "Rüdiger", position: .defender, nation: .germany, shirtNumber: 2, price: 6.0, group: .e)
    static let hakimi = Player(id: 4, name: "Hakimi", firstName: "Achraf", lastName: "Hakimi", position: .defender, nation: .morocco, shirtNumber: 2, price: 7.0, group: .f)
    static let trippier = Player(id: 5, name: "Trippier", firstName: "Kieran", lastName: "Trippier", position: .defender, nation: .england, shirtNumber: 12, price: 5.5, group: .b)
    
    static let deBruyne = Player(id: 6, name: "De Bruyne", firstName: "Kevin", lastName: "De Bruyne", position: .midfielder, nation: .belgium, shirtNumber: 7, price: 10.5, group: .f)
    static let modric = Player(id: 7, name: "Modrić", firstName: "Luka", lastName: "Modrić", position: .midfielder, nation: .croatia, shirtNumber: 10, price: 8.5, group: .f)
    static let musiala = Player(id: 8, name: "Musiala", firstName: "Jamal", lastName: "Musiala", position: .midfielder, nation: .germany, shirtNumber: 14, price: 9.0, group: .e)
    static let saka = Player(id: 9, name: "Saka", firstName: "Bukayo", lastName: "Saka", position: .midfielder, nation: .england, shirtNumber: 17, price: 8.5, group: .b)
    
    static let mbappe = Player(id: 10, name: "Mbappé", firstName: "Kylian", lastName: "Mbappé", position: .forward, nation: .france, shirtNumber: 10, price: 12.0, group: .d)
    static let messi = Player(id: 11, name: "Messi", firstName: "Lionel", lastName: "Messi", position: .forward, nation: .argentina, shirtNumber: 10, price: 11.0, group: .c)
    
    // Bench Players
    static let neuer = Player(id: 12, name: "Neuer", firstName: "Manuel", lastName: "Neuer", position: .goalkeeper, nation: .germany, shirtNumber: 1, price: 5.5, group: .e)
    static let davies = Player(id: 13, name: "Davies", firstName: "Alphonso", lastName: "Davies", position: .defender, nation: .canada, shirtNumber: 19, price: 5.0, group: .f)
    static let valverde = Player(id: 14, name: "Valverde", firstName: "Federico", lastName: "Valverde", position: .midfielder, nation: .uruguay, shirtNumber: 15, price: 7.5, group: .h)
    static let kane = Player(id: 15, name: "Kane", firstName: "Harry", lastName: "Kane", position: .forward, nation: .england, shirtNumber: 9, price: 11.5, group: .b)
    
    // MARK: - Squad Composition
    
    static let startingXI: [Player] = [
        alisson,
        vanDijk, rudiger, hakimi, trippier,
        deBruyne, modric, musiala, saka,
        mbappe, messi
    ]
    
    static let bench: [Player] = [
        neuer, davies, valverde, kane
    ]
    
    static let allPlayers: [Player] = startingXI + bench
    
    static var squad: Squad {
        let squad = Squad(teamName: "Galácticos FC", initialBudget: 100.0)
        
        squad.players = allPlayers
        squad.startingXI = startingXI
        squad.bench = bench
        
        // Set captain and vice-captain
        squad.captain = mbappe
        squad.viceCaptain = deBruyne
        
        // Set some points for realism
        squad.totalPoints = 478
        squad.matchdayPoints = 62
        
        return squad
    }
    
    // MARK: - Fixtures
    
    static let fixture1 = Fixture(id: 1, matchdayNumber: 1, homeNation: .england, awayNation: .iran, kickoffTime: Date().addDays(-1), group: .b)
    static let fixture2 = Fixture(id: 2, matchdayNumber: 1, homeNation: .argentina, awayNation: .saudiArabia, kickoffTime: Date(), group: .c)
    static let fixture3 = Fixture(id: 3, matchdayNumber: 1, homeNation: .france, awayNation: .australia, kickoffTime: Date().addDays(1), group: .d)
    
    static var finishedFixture: Fixture {
        let fixture = Fixture(id: 4, matchdayNumber: 1, homeNation: .germany, awayNation: .japan, kickoffTime: Date().addDays(-2), group: .e)
        fixture.isFinished = true
        fixture.homeScore = 1
        fixture.awayScore = 2
        return fixture
    }
    
    static let allFixtures = [fixture1, fixture2, fixture3, finishedFixture]
    
    // MARK: - Matchday
    
    static var currentMatchday: Matchday {
        Matchday(number: 1, stage: .groupStage, deadline: Date().addDays(2), groupStageRound: 1)
    }
}