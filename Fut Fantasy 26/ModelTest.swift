//
//  ModelTest.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

import Foundation
import SwiftData

/*

//MARK: - PLAYER
@Model
final class Player {

    @Attribute(.unique) var id: Int
    
    //Personal info
    var name: String
    var firstName: String
    var lastName: String
    var position: PlayerPosition
    var nation: String // posiblemente termine usando enum
    var nationCode: String //posiblemente termine usando enum
    var shirtNumber: Int
    
    // Financial
    var price: Double // en millones jsjs
    var isPriceChangingEnabled: Bool // vemos
    
    
    // Season Stats
    var totalPoints: Int
    var matchdayPoints: Int // pueden ser puntos del mismo dia o del pasado
    var goalsScored: Int
    var goalsOutsideBox: Int
    var assists: Int
    var ballsRecovered: Int
    var cleanSheets: Int
    var goalsConceded: Int
    var saves: Int
    var penaltiesWon: Int
    var penaltiesConceded: Int
    var penaltiesSaved: Int
    var penaltiesMissed: Int
    var yellowCards: Int
    var redCards: Int
    var ownGoals: Int
    var minutesPlayed: Int
    var playerOfTheMatchAwards: Int
    
    
    // World Cup Specific
    var appearances: Int // Number of matches played
    
    
    // Performance Metrics
    var pointsPerPrice: Double // Pts per £/€ (va terminar siendo una funcion)
    var pointsPerMatchday: Double // Avg pts per MD (de nuevo va terminar siendo controlado por un manager)
    var selectedByPercent: Double // % of managers who own (e.g., 32.0 for 32%)  (datos que seran futura implementacion
    
    
    // Tournament Info
    var group: String? // e.g., "Group A", "Group B" (for group stage) //se convierte en enums
    var nextOpponent: String? // tkm enums aqui se usa el enum de equipos o no lo se chat vale la pena usar un enum para esto o llenarlo con un string
    var nextMatchDate: Date?
    
    
    // Recent Form (last 3 tournament matches)
    var recentForm: [Int]? // Array of points from last 3 games
    
    // Images - UI Avatars (free, no auth needed)
    var imageURL: String
    var nationFlagURL: String
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Squad.players)
    var squads: [Squad]?
    
    @Relationship(deleteRule: .cascade)
    var matchdayPerformances: [MatchdayPerformance]?
    
    
    init(
        id: Int,
        name: String,
        firstName: String,
        lastName: String,
        position: PlayerPosition,
        nation: String, //enum
        nationCode: String, //enum
        shirtNumber: Int = Int.random(in: 1...23),
        price: Double,
        group: String? = nil //enum
    ) {
        self.id = id
        self.name = name
        self.firstName = firstName
        self.lastName = lastName
        self.position = position
        self.nation = nation //enum
        self.nationCode = nationCode //se convierte a enum
        self.shirtNumber = shirtNumber
        self.price = price
        self.group = group
        self.isPriceChangingEnabled = false // Usually no price changes in World Cup
        
        // Initialize all stats to 0
        self.totalPoints = 0
        self.matchdayPoints = 0
        self.goalsScored = 0
        self.goalsOutsideBox = 0
        self.assists = 0
        self.ballsRecovered = 0
        self.cleanSheets = 0
        self.goalsConceded = 0
        self.saves = 0
        self.penaltiesWon = 0
        self.penaltiesConceded = 0
        self.penaltiesSaved = 0
        self.penaltiesMissed = 0
        self.yellowCards = 0
        self.redCards = 0
        self.ownGoals = 0
        self.minutesPlayed = 0
        self.playerOfTheMatchAwards = 0
        self.appearances = 0
        
        self.pointsPerPrice = 0.0
        self.pointsPerMatchday = 0.0
        self.selectedByPercent = 0.0
        
        
        // Generate image URLs
        self.imageURL = ""
        self.nationFlagURL = Self.generateNationFlagURL(nationCode: nationCode)
    }
    
    // MARK: - Image URL Generators
    
    static func generateNationFlagURL(nationCode: String) -> String {
        // Use flagcdn.com for country flags (free)
        let code = nationCode.lowercased()
        return "https://flagcdn.com/w160/\(code).png"
    }
    
    
    
    // MARK: - Computed Properties
    
    var displayPrice: String {
        "£\(String(format: "%.1f", price))m"
    }
    
    var positionAbbreviation: String {
        position.rawValue
    }
    
}

// MARK: - Player Position Enum

enum PlayerPosition: String, Codable, CaseIterable {
    case goalkeeper = "GK"
    case defender = "DEF"
    case midfielder = "MID"
    case forward = "FWD"
    
    var fullName: String {
        switch self {
        case .goalkeeper: return "Goalkeeper"
        case .defender: return "Defender"
        case .midfielder: return "Midfielder"
        case .forward: return "Forward"
        }
    }
    
    var squadLimit: Int {
        switch self {
        case .goalkeeper: return 2
        case .defender: return 5
        case .midfielder: return 5
        case .forward: return 3
        }
    }
    
    var minInStartingXI: Int {
        switch self {
        case .goalkeeper: return 1
        case .defender: return 3
        case .midfielder: return 2
        case .forward: return 1
        }
    }
    
    // Scoring rules by position (World Cup typically follows similar rules)
    func pointsForGoal(outsideBox: Bool = false) -> Int {
        let basePoints: Int
        switch self {
        case .goalkeeper, .defender: basePoints = 6
        case .midfielder: basePoints = 5
        case .forward: basePoints = 4
        }
        return basePoints + (outsideBox ? 1 : 0)
    }
    
    func pointsForCleanSheet(minutesPlayed: Int) -> Int {
        guard minutesPlayed >= 60 else { return 0 }
        switch self {
        case .goalkeeper, .defender: return 4
        case .midfielder: return 1
        case .forward: return 0
        }
    }
}

// MARK: - Squad Model (Manager's Team)

@Model
final class Squad {
    @Attribute(.unique) var id: UUID
    var teamName: String
    var ownerName: String
    
    // Budget (World Cup typically £100m and doesn't change)
    var initialBudget: Double // £100m
    var currentBudget: Double // Remaining budget //
    var squadValue: Double // Total value of all 15 players //esto necesita ser una propiedad computada
    
    // Transfer Management (World Cup has different rules)
    var freeTransfersRemaining: Int
    var totalTransfersMade: Int
    var pointsDeductedFromTransfers: Int // Typically 4 points per extra transfer
    var hasUnlimitedTransfers: Bool // Some stages have unlimited
    
    // Points
    var totalPoints: Int
    var matchdayPoints: Int
    
    
    
    // Relationships
    @Relationship(deleteRule: .nullify)
    var players: [Player]? // All 15 players in squad
    
    @Relationship(deleteRule: .nullify)
    var startingXI: [Player]? // 11 starting players
    
    @Relationship(deleteRule: .nullify)
    var bench: [Player]? // 4 bench players (ordered by priority)
    
    @Relationship(deleteRule: .nullify)
    var captain: Player?
    
    @Relationship(deleteRule: .nullify)
    var viceCaptain: Player? // Becomes captain if captain doesn't play
    
    @Relationship(deleteRule: .cascade)
    var transfers: [Transfer]?
    
    @Relationship(deleteRule: .cascade)
    var matchdaySquads: [MatchdaySquad]? // Snapshot of squad each matchday
    
    
    init(
        teamName: String,
        ownerName: String = "Manager",
        initialBudget: Double = 100.0,
        createdOnMatchday: Int = 1
    ) {
        self.id = UUID()
        self.teamName = teamName
        self.ownerName = ownerName
        self.initialBudget = initialBudget
        self.currentBudget = initialBudget
        self.squadValue = 0.0
        self.freeTransfersRemaining = 1
        self.totalTransfersMade = 0
        self.pointsDeductedFromTransfers = 0
        self.hasUnlimitedTransfers = false
        self.totalPoints = 0
        self.matchdayPoints = 0
        
    }
    
    // MARK: - Helper Methods
    
    func playerCount(for position: PlayerPosition) -> Int {
        players?.filter { $0.position == position }.count ?? 0
    }
    
    func startingPlayerCount(for position: PlayerPosition) -> Int {
        startingXI?.filter { $0.position == position }.count ?? 0
    }
    
    func canAddPlayer(position: PlayerPosition) -> Bool {
        playerCount(for: position) < position.squadLimit
    }
    
    func playersFromNation(_ nation: String) -> Int {
        players?.filter { $0.nation == nation }.count ?? 0
    }
    
    func canAddPlayerFromNation(_ nation: String, stage: TournamentStage) -> Bool {
        playersFromNation(nation) < stage.maxPlayersPerNation
    }
    
    var isFullSquad: Bool {
        (players?.count ?? 0) == 15
    }
    
    var isValidStartingXI: Bool {
        guard startingXI?.count == 11 else { return false }
        
        let gkCount = startingPlayerCount(for: .goalkeeper)
        let defCount = startingPlayerCount(for: .defender)
        let midCount = startingPlayerCount(for: .midfielder)
        let fwdCount = startingPlayerCount(for: .forward)
        
        return gkCount == 1 && defCount >= 3 && midCount >= 2 && fwdCount >= 1
    }
    
    func calculateSquadValue() {
        self.squadValue = players?.reduce(0.0) { $0 + $1.price } ?? 0.0
        self.currentBudget = initialBudget - squadValue
    }
}

// MARK: - Tournament Stage Enum (World Cup Specific)

enum TournamentStage: String, Codable, CaseIterable {
    case groupStage = "Group Stage"
    case roundOf16 = "Round of 16"
    case quarterFinals = "Quarter-finals"
    case semiFinals = "Semi-finals"
    case thirdPlace = "Third Place Playoff"
    case final = "Final"
    
    var maxPlayersPerNation: Int {
        switch self {
        case .groupStage: return 3
        case .roundOf16: return 4
        case .quarterFinals: return 5
        case .semiFinals, .thirdPlace: return 6
        case .final: return 8
        }
    }
    
    var freeTransfersAllowed: Int {
        switch self {
        case .groupStage: return 1 // Per matchday
        case .roundOf16: return 2
        case .quarterFinals: return 2
        case .semiFinals: return 1
        case .thirdPlace, .final: return 0 // Usually locked
        }
    }
    
    var hasUnlimitedTransfers: Bool {
        // Typically unlimited before knockout stages
        false // Set per matchday
    }
    
    var matchNumber: Int {
        switch self {
        case .groupStage: return 48 // 16 groups × 3 matches
        case .roundOf16: return 8
        case .quarterFinals: return 4
        case .semiFinals: return 2
        case .thirdPlace: return 1
        case .final: return 1
        }
    }
}

// MARK: - Matchday Model (World Cup Version)

@Model
final class Matchday {
    @Attribute(.unique) var number: Int
    var name: String
    var stage: TournamentStage
    var deadline: Date
    var isActive: Bool
    var isFinished: Bool
    
    // World Cup specific
    var groupStageRound: Int?
    
    // Transfer rules for this matchday
    var hasUnlimitedTransfers: Bool
    var freeTransfersAllowed: Int
    
    
    // Relationships
    @Relationship(deleteRule: .cascade)
    var fixtures: [Fixture]?
    
    @Relationship(deleteRule: .cascade)
    var performances: [MatchdayPerformance]?
    
    init(
        number: Int,
        stage: TournamentStage,
        deadline: Date,
        groupStageRound: Int? = nil,
        hasUnlimitedTransfers: Bool = false,
        freeTransfersAllowed: Int = 1,
        allMatchesSimultaneous: Bool = false
    ) {
        self.number = number
        self.stage = stage
        self.groupStageRound = groupStageRound
        
        // Generate name based on stage
        if stage == .groupStage, let round = groupStageRound {
            self.name = "Matchday \(number) (Group Stage - Round \(round))"
        } else {
            self.name = "Matchday \(number) (\(stage.rawValue))"
        }
        
        self.deadline = deadline
        self.isActive = false
        self.isFinished = false
        self.hasUnlimitedTransfers = hasUnlimitedTransfers
        self.freeTransfersAllowed = freeTransfersAllowed
    }
}

// MARK: - Matchday Performance (same as CL but simplified)

@Model
final class MatchdayPerformance {
    @Attribute(.unique) var id: UUID
    var matchdayNumber: Int
    var points: Int
    
    // Appearance
    var didAppear: Bool
    var minutesPlayed: Int
    var played60Plus: Bool
    
    // Scoring
    var goalsScored: Int
    var goalsOutsideBox: Int
    var assists: Int
    var ballsRecovered: Int
    
    // Defensive
    var cleanSheet: Bool
    var goalsConceded: Int
    var saves: Int
    
    // Discipline
    var yellowCards: Int
    var redCards: Int
    var ownGoals: Int
    
    // Special
    var penaltiesWon: Int
    var penaltiesConceded: Int
    var penaltiesSaved: Int
    var penaltiesMissed: Int
    var playerOfTheMatch: Bool
    
    // Captain/Vice-Captain bonus
    var wasCaptain: Bool
    var wasViceCaptain: Bool
    var captainBonus: Int // Extra points (could be 2x or 3x with Triple Captain)
    var captainMultiplier: Int // 2 for normal, 3 for Triple Captain
    
    
    // Relationships
    @Relationship(deleteRule: .nullify)
    var player: Player?
    
    @Relationship(deleteRule: .nullify)
    var matchday: Matchday?
    
    init(matchdayNumber: Int, player: Player?) {
        self.id = UUID()
        self.matchdayNumber = matchdayNumber
        self.player = player
        self.points = 0
        self.didAppear = false
        self.minutesPlayed = 0
        self.played60Plus = false
        self.goalsScored = 0
        self.goalsOutsideBox = 0
        self.assists = 0
        self.ballsRecovered = 0
        self.cleanSheet = false
        self.goalsConceded = 0
        self.saves = 0
        self.yellowCards = 0
        self.redCards = 0
        self.ownGoals = 0
        self.penaltiesWon = 0
        self.penaltiesConceded = 0
        self.penaltiesSaved = 0
        self.penaltiesMissed = 0
        self.playerOfTheMatch = false
        self.wasCaptain = false
        self.wasViceCaptain = false
        self.captainBonus = 0
        self.captainMultiplier = 1
    }
    
    // MARK: - Calculate Points
    
    func calculatePoints(position: PlayerPosition) -> Int {
        var total = 0
        
        // Appearance points
        if didAppear { total += 1 }
        if played60Plus { total += 1 }
        
        // Goals
        total += goalsScored * position.pointsForGoal()
        total += goalsOutsideBox
        
        // Assists
        total += assists * 3
        
        // Balls recovered (every 3)
        total += (ballsRecovered / 3) * 1
        
        // Clean sheet
        if cleanSheet {
            total += position.pointsForCleanSheet(minutesPlayed: minutesPlayed)
        }
        
        // Goals conceded (GK and DEF only)
        if position == .goalkeeper || position == .defender {
            total += (goalsConceded / 2) * -1
        }
        
        // Saves (GK only)
        if position == .goalkeeper {
            total += (saves / 3) * 1
        }
        
        // Penalties
        total += penaltiesWon * 2
        total += penaltiesConceded * -1
        total += penaltiesSaved * 5
        total += penaltiesMissed * -2
        
        // Discipline
        total += yellowCards * -1
        total += redCards * -3
        total += ownGoals * -2
        
        // Player of the Match
        if playerOfTheMatch { total += 3 }
        
        // Store calculated points
        self.points = total
        
        // Captain bonus (2x normal, 3x with Triple Captain chip)
        if wasCaptain {
            self.captainBonus = total * (captainMultiplier - 1)
            return total * captainMultiplier
        }
        
        // Vice-captain only gets bonus if captain didn't play
        if wasViceCaptain {
            self.captainBonus = total * (captainMultiplier - 1)
            return total * captainMultiplier
        }
        
        return total
    }
}

// MARK: - Matchday Squad

@Model
final class MatchdaySquad {
    @Attribute(.unique) var id: UUID
    var matchdayNumber: Int
    var squadSnapshot: [Int]
    var startingXISnapshot: [Int]
    var benchSnapshot: [Int]
    var captainID: Int
    var viceCaptainID: Int
    var formation: String
    
    // Relationships
    @Relationship(deleteRule: .nullify)
    var squad: Squad?
    
    init(matchdayNumber: Int, squad: Squad, formation: String = "4-4-2") {
        self.id = UUID()
        self.matchdayNumber = matchdayNumber
        self.squadSnapshot = squad.players?.map { $0.id } ?? []
        self.startingXISnapshot = squad.startingXI?.map { $0.id } ?? []
        self.benchSnapshot = squad.bench?.map { $0.id } ?? []
        self.captainID = squad.captain?.id ?? 0
        self.viceCaptainID = squad.viceCaptain?.id ?? 0
        self.formation = formation
        self.squad = squad
    }
}

// MARK: - Transfer Model

@Model
final class Transfer {
    @Attribute(.unique) var id: UUID
    var matchdayNumber: Int
    var isFreeTransfer: Bool
    var pointsDeducted: Int // 4 if not free
    var timestamp: Date
    
    
    // Relationships
    @Relationship(deleteRule: .nullify)
    var playerIn: Player?
    
    @Relationship(deleteRule: .nullify)
    var playerOut: Player?
    
    @Relationship(deleteRule: .nullify)
    var squad: Squad?
    
    init(
        matchdayNumber: Int,
        playerIn: Player?,
        playerOut: Player?,
        isFreeTransfer: Bool,
        wasWildcardActive: Bool = false,
        wasFreeHitActive: Bool = false
    ) {
        self.id = UUID()
        self.matchdayNumber = matchdayNumber
        self.playerIn = playerIn
        self.playerOut = playerOut
        self.isFreeTransfer = isFreeTransfer
        self.pointsDeducted = isFreeTransfer ? 0 : 4
        self.timestamp = Date()
    }
}

// MARK: - League Model

//i will literly not have custom made legues its just one general

// MARK: - Fixture Model (World Cup)

//if this is an induviual match pls clarify
@Model
final class Fixture {
    @Attribute(.unique) var id: Int
    var matchdayNumber: Int
    var homeNation: String //enum
    var awayNation: String //enum
    var homeNationCode: String // e.g., "BRA" //enum
    var awayNationCode: String // e.g., "ARG" //enum
    var kickoffTime: Date
    var isFinished: Bool
    var homeScore: Int?
    var awayScore: Int?
    var hadExtraTime: Bool
    var hadPenaltyShootout: Bool
    var penaltyWinner: String? // Nation that won on penalties
    
    // Group stage info
    var group: String? // e.g., "Group A"
    var venue: String? // Stadium name
    var city: String? // Host city
    
    // Knockout stage info
    var knockoutStage: TournamentStage?
    var matchLabel: String? // e.g., "QF1", "SF1", "FINAL"
    
    // Relationships
    @Relationship(deleteRule: .nullify)
    var matchday: Matchday?
    
    init(
        id: Int,
        matchdayNumber: Int,
        homeNation: String,
        awayNation: String,
        homeNationCode: String,
        awayNationCode: String,
        kickoffTime: Date,
        group: String? = nil,
        knockoutStage: TournamentStage? = nil,
        venue: String? = nil,
        city: String? = nil
    ) {
        self.id = id
        self.matchdayNumber = matchdayNumber
        self.homeNation = homeNation
        self.awayNation = awayNation
        self.homeNationCode = homeNationCode
        self.awayNationCode = awayNationCode
        self.kickoffTime = kickoffTime
        self.group = group
        self.knockoutStage = knockoutStage
        self.venue = venue
        self.city = city
        self.isFinished = false
        self.hadExtraTime = false
        self.hadPenaltyShootout = false
    }
    
    var displayScore: String {
        if let home = homeScore, let away = awayScore {
            var score = "\(home) - \(away)"
            if hadPenaltyShootout, let winner = penaltyWinner {
                score += " (\(winner) won on pens)"
            } else if hadExtraTime {
                score += " (a.e.t.)"
            }
            return score
        }
        return "vs"
    }
    
    var homeFlagURL: String {
        "https://flagcdn.com/w160/\(homeNationCode.lowercased()).png"
    }
    
    var awayFlagURL: String {
        "https://flagcdn.com/w160/\(awayNationCode.lowercased()).png"
    }
}

// MARK: - Helper Extensions

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension Date {
    func addDays(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    var isInPast: Bool {
        self < Date()
    }
}

*/
