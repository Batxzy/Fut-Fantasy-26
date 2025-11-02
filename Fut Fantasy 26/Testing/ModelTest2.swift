//
//  ModelTest2.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//

import Foundation
import SwiftData

// MARK: - PLAYER

@Model
final class Player: Hashable {
    @Attribute(.unique) var id: Int
    
    // Personal info
    var name: String
    var firstName: String
    var lastName: String
    var position: PlayerPosition
    var nation: Nation
    var shirtNumber: Int
    
    // Financial
    var price: Double // in millions
    
    // Season Stats (Total across tournament)
    var totalPoints: Int
    var matchdayPoints: Int // Current/last matchday points
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
    var appearances: Int // Number of matches played
    
    // Tournament Info
    var group: WorldCupGroup? // Group stage only
    var nextOpponent: Nation? // Next nation name
    var nextMatchDate: Date?
    
    // Recent Form (last 3 matches)
    var recentForm: [Int]? // [5, 8, 12] = points from last 3 games
    
    // Images
    var imageURL: String
    
    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Squad.players)
    var squads: [Squad]?
    
    @Relationship(deleteRule: .cascade, inverse: \MatchdayPerformance.player)
    var matchdayPerformances: [MatchdayPerformance]?
    
    init(
        id: Int,
        name: String,
        firstName: String,
        lastName: String,
        position: PlayerPosition,
        nation: Nation,
        shirtNumber: Int,
        price: Double,
        group: WorldCupGroup? = nil
    ) {
        self.id = id
        self.name = name
        self.firstName = firstName
        self.lastName = lastName
        self.position = position
        self.nation = nation
        self.shirtNumber = shirtNumber
        self.price = price
        self.group = group
        
        // Initialize stats
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
        
        // Generate image URL
        self.imageURL = Self.generatePlayerImageURL(name: name, id: id)
    }
    
    // MARK: - Image Generator
    
    static func generatePlayerImageURL(name: String, id: Int) -> String {
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Player"
        return "https://ui-avatars.com/api/?name=\(encodedName)&size=200&background=random&bold=true&format=png"
    }
    
    // MARK: - Computed Properties
    
    var displayPrice: String {
        "£\(String(format: "%.1f", price))m"
    }
    
    var positionAbbreviation: String {
        position.rawValue
    }
    
    var nationFlagURL: String {
        nation.flagURL
    }
    
    var nationCode: String {
        nation.code
    }
    
    var nationName: String {
        nation.rawValue
    }
    
    // Points per price (value metric)
    var pointsPerPrice: Double {
        price > 0 ? Double(totalPoints) / price : 0.0
    }
    
    // Points per matchday (form metric)
    var pointsPerMatchday: Double {
        guard let performances = matchdayPerformances, !performances.isEmpty else { return 0.0 }
        return Double(totalPoints) / Double(performances.count)
    }
    
    // Selected by percentage (calculated from global squads)
    var selectedByPercent: Double {
        // This will be calculated by counting how many squads have this player
        // You'd query this when needed, not store it
        return 0.0 // Placeholder - calculate when displaying
    }
}

// MARK: - Nation Enum (UNCHANGED)

enum Nation: String, Codable, CaseIterable {
    // Group A
    case qatar = "Qatar"
    case ecuador = "Ecuador"
    case senegal = "Senegal"
    case netherlands = "Netherlands"
    
    // Group B
    case england = "England"
    case iran = "Iran"
    case usa = "USA"
    case wales = "Wales"
    
    // Group C
    case argentina = "Argentina"
    case saudiArabia = "Saudi Arabia"
    case mexico = "Mexico"
    case poland = "Poland"
    
    // Group D
    case france = "France"
    case australia = "Australia"
    case denmark = "Denmark"
    case tunisia = "Tunisia"
    
    // Group E
    case spain = "Spain"
    case costaRica = "Costa Rica"
    case germany = "Germany"
    case japan = "Japan"
    
    // Group F
    case belgium = "Belgium"
    case canada = "Canada"
    case morocco = "Morocco"
    case croatia = "Croatia"
    
    // Group G
    case brazil = "Brazil"
    case serbia = "Serbia"
    case switzerland = "Switzerland"
    case cameroon = "Cameroon"
    
    // Group H
    case portugal = "Portugal"
    case ghana = "Ghana"
    case uruguay = "Uruguay"
    case southKorea = "South Korea"
    
    var code: String {
        switch self {
        case .qatar: return "qa"
        case .ecuador: return "ec"
        case .senegal: return "sn"
        case .netherlands: return "nl"
        case .england: return "gb-eng"
        case .iran: return "ir"
        case .usa: return "us"
        case .wales: return "gb-wls"
        case .argentina: return "ar"
        case .saudiArabia: return "sa"
        case .mexico: return "mx"
        case .poland: return "pl"
        case .france: return "fr"
        case .australia: return "au"
        case .denmark: return "dk"
        case .tunisia: return "tn"
        case .spain: return "es"
        case .costaRica: return "cr"
        case .germany: return "de"
        case .japan: return "jp"
        case .belgium: return "be"
        case .canada: return "ca"
        case .morocco: return "ma"
        case .croatia: return "hr"
        case .brazil: return "br"
        case .serbia: return "rs"
        case .switzerland: return "ch"
        case .cameroon: return "cm"
        case .portugal: return "pt"
        case .ghana: return "gh"
        case .uruguay: return "uy"
        case .southKorea: return "kr"
        }
    }
    
    var flagURL: String {
        "https://flagcdn.com/w160/\(code).png"
    }
    
    var group: WorldCupGroup? {
        switch self {
        case .qatar, .ecuador, .senegal, .netherlands: return .a
        case .england, .iran, .usa, .wales: return .b
        case .argentina, .saudiArabia, .mexico, .poland: return .c
        case .france, .australia, .denmark, .tunisia: return .d
        case .spain, .costaRica, .germany, .japan: return .e
        case .belgium, .canada, .morocco, .croatia: return .f
        case .brazil, .serbia, .switzerland, .cameroon: return .g
        case .portugal, .ghana, .uruguay, .southKorea: return .h
        }
    }
}

// MARK: - WorldCupGroup Enum (UNCHANGED)

enum WorldCupGroup: String, Codable, CaseIterable {
    case a = "Group A"
    case b = "Group B"
    case c = "Group C"
    case d = "Group D"
    case e = "Group E"
    case f = "Group F"
    case g = "Group G"
    case h = "Group H"
    
    var nations: [Nation] {
        Nation.allCases.filter { $0.group == self }
    }
}

// MARK: - Player Position Enum (UNCHANGED)

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
    
    // Scoring rules by position
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

// MARK: - Squad Model (Manager's Team) - **UPDATED WITH 2D STRUCTURE**

@Model
final class Squad {
    @Attribute(.unique) var id: UUID
    var teamName: String
    var ownerName: String
    
    // Budget
    var initialBudget: Double // £100m
    
    // Transfer Management
    var freeTransfersRemaining: Int
    var totalTransfersMade: Int
    var pointsDeductedFromTransfers: Int // 4 points per extra transfer
    var hasUnlimitedTransfers: Bool // Certain stages
    
    // Points
    var totalPoints: Int
    var matchdayPoints: Int
    
    // **KEY CHANGE**: Store player IDs in 2D structure by position
    // [goalkeepers, defenders, midfielders, forwards]
    var startingXIIDs: [[Int]]
    var benchIDs: [Int]
    
    // Relationships
    @Relationship(deleteRule: .nullify)
    var players: [Player]? // All 15 players
    
    @Relationship(deleteRule: .nullify)
    var captain: Player?
    
    @Relationship(deleteRule: .nullify)
    var viceCaptain: Player?
    
    @Relationship(deleteRule: .cascade, inverse: \Transfer.squad)
    var transfers: [Transfer]?
    
    @Relationship(deleteRule: .cascade, inverse: \MatchdaySquad.squad)
    var matchdaySquads: [MatchdaySquad]? // Snapshots per matchday
    
    init(
        teamName: String,
        ownerName: String = "Manager",
        initialBudget: Double = 1000.0
    ) {
        self.id = UUID()
        self.teamName = teamName
        self.ownerName = ownerName
        self.initialBudget = initialBudget
        self.freeTransfersRemaining = 5
        self.totalTransfersMade = 0
        self.pointsDeductedFromTransfers = 0
        self.hasUnlimitedTransfers = false
        self.totalPoints = 0
        self.matchdayPoints = 0
        
        // **NEW**: Initialize 2D array: [GK, DEF, MID, FWD]
        self.startingXIIDs = [[], [], [], []]
        self.benchIDs = []
    }
    
    // MARK: - Computed Properties (BACKWARDS COMPATIBLE)
    
    var startingXI: [Player]? {
        get {
            guard let allPlayers = players else { return nil }
            let playerDict = Dictionary(uniqueKeysWithValues: allPlayers.map { ($0.id, $0) })
            
            var result: [Player] = []
            for positionGroup in startingXIIDs {
                for playerId in positionGroup {
                    if let player = playerDict[playerId] {
                        result.append(player)
                    }
                }
            }
            return result.isEmpty ? nil : result
        }
        set {
            // Convert flat array back to 2D structure
            guard let newValue = newValue else {
                startingXIIDs = [[], [], [], []]
                return
            }
            
            startingXIIDs = [
                newValue.filter { $0.position == .goalkeeper }.map { $0.id },
                newValue.filter { $0.position == .defender }.map { $0.id },
                newValue.filter { $0.position == .midfielder }.map { $0.id },
                newValue.filter { $0.position == .forward }.map { $0.id }
            ]
        }
    }
    
    var bench: [Player]? {
        get {
            guard let allPlayers = players else { return nil }
            let playerDict = Dictionary(uniqueKeysWithValues: allPlayers.map { ($0.id, $0) })
            
            let result = benchIDs.compactMap { playerDict[$0] }
            return result.isEmpty ? nil : result
        }
        set {
            benchIDs = newValue?.map { $0.id } ?? []
        }
    }
    
    var squadValue: Double {
        players?.reduce(0.0) { $0 + $1.price } ?? 0.0
    }
    
    var currentBudget: Double {
        initialBudget - squadValue
    }
    
    var isFullSquad: Bool {
        (players?.count ?? 0) == 15
    }
    
    var isValidStartingXI: Bool {
        let gkCount = startingXIIDs[0].count
        let defCount = startingXIIDs[1].count
        let midCount = startingXIIDs[2].count
        let fwdCount = startingXIIDs[3].count
        
        return gkCount == 1 && defCount >= 3 && midCount >= 2 && fwdCount >= 1
    }
    
    // MARK: - Helper Methods
    
    func playerCount(for position: PlayerPosition) -> Int {
        players?.filter { $0.position == position }.count ?? 0
    }
    
    func startingPlayerCount(for position: PlayerPosition) -> Int {
        switch position {
        case .goalkeeper: return startingXIIDs[0].count
        case .defender: return startingXIIDs[1].count
        case .midfielder: return startingXIIDs[2].count
        case .forward: return startingXIIDs[3].count
        }
    }
    
    func canAddPlayer(position: PlayerPosition) -> Bool {
        playerCount(for: position) < position.squadLimit
    }
    
    func playersFromNation(_ nation: Nation) -> Int {
        players?.filter { $0.nation == nation }.count ?? 0
    }
    
    func canAddPlayerFromNation(_ nation: Nation, stage: TournamentStage) -> Bool {
        playersFromNation(nation) < stage.maxPlayersPerNation
    }
}

extension Squad {
    // MARK: - Display Formatters
    
    var displayBudget: String {
        String(format: "%.1fM", currentBudget)
    }
    
    var displayTotalValue: String {
        String(format: "%.1fM", squadValue)
    }
    
    var displaySpentBudget: String {
        let spent = initialBudget - currentBudget
        return String(format: "%.1fM", spent)
    }
    
    var displayBudgetNoDecimals: String {
            return String(format: "%.0fM", currentBudget)
        }
    
    // MARK: - Squad Status
    
    var freeSlots: Int {
        max(0, 15 - (players?.count ?? 0))
    }
    
    var isFull: Bool {
        (players?.count ?? 0) >= 15
    }
    
    var benchCount: Int {
        benchIDs.count
    }
    
    var startingXICount: Int {
        startingXIIDs.flatMap { $0 }.count
    }
    
    
    // MARK: - Position Analysis
    
    func squadPlayerCount(for position: PlayerPosition) -> Int {
        players?.filter { $0.position == position }.count ?? 0
    }
    
    func canAddPlayer(for position: PlayerPosition) -> Bool {
        squadPlayerCount(for: position) < position.squadLimit
    }
    
    func remainingSlots(for position: PlayerPosition) -> Int {
        max(0, position.squadLimit - squadPlayerCount(for: position))
    }
    
    // MARK: - Nation Rules
    
    var representedNations: [Nation] {
        let allNations = players?.map { $0.nation } ?? []
        return Array(Set(allNations)).sorted { $0.rawValue < $1.rawValue }
    }
    
    var nationCount: Int {
        representedNations.count
    }
    
    // MARK: - Formation Validation
    
    var isValidXI: Bool {
        guard let starting = startingXI, starting.count == 11 else { return false }
        
        let gk = starting.filter { $0.position == .goalkeeper }.count
        let def = starting.filter { $0.position == .defender }.count
        let mid = starting.filter { $0.position == .midfielder }.count
        let fwd = starting.filter { $0.position == .forward }.count
        
        return gk == 1 && def >= 3 && mid >= 2 && fwd >= 1
    }
    
    var formationString: String {
        guard let starting = startingXI, starting.count == 11 else { return "Invalid" }
        
        let def = starting.filter { $0.position == .defender }.count
        let mid = starting.filter { $0.position == .midfielder }.count
        let fwd = starting.filter { $0.position == .forward }.count
        
        return "\(def)-\(mid)-\(fwd)"
    }
    
    // MARK: - Captain Status
    
    var hasCaptain: Bool {
        captain != nil
    }
    
    var hasViceCaptain: Bool {
        viceCaptain != nil
    }
    
    var hasBothCaptains: Bool {
        hasCaptain && hasViceCaptain
    }
    
    // MARK: - Transfer Status
    
    var canMakeFreeTransfer: Bool {
        hasUnlimitedTransfers || freeTransfersRemaining > 0
    }
    
    var nextTransferCost: Int {
        canMakeFreeTransfer ? 0 : 4
    }
    
    var transferStatusText: String {
        if hasUnlimitedTransfers {
            return "Unlimited Transfers"
        } else if freeTransfersRemaining > 0 {
            return "\(freeTransfersRemaining) Free Transfer\(freeTransfersRemaining == 1 ? "" : "s")"
        } else {
            return "No Free Transfers (-4 pts per transfer)"
        }
    }
    
    // MARK: - Points Analysis
    
    var averagePoints: Double {
        guard let players = players, !players.isEmpty else { return 0.0 }
        let total = players.reduce(0) { $0 + $1.totalPoints }
        return Double(total) / Double(players.count)
    }
    
    var netPoints: Int {
        totalPoints - pointsDeductedFromTransfers
    }
    
    var displayNetPoints: String {
        if pointsDeductedFromTransfers > 0 {
            return "\(netPoints) (\(totalPoints) - \(pointsDeductedFromTransfers))"
        }
        return "\(totalPoints)"
    }
    
    // MARK: - Squad Completion Status
    
    var completionPercentage: Int {
        var score = 0
        let maxScore = 5
        
        if isFull { score += 1 }
        if isValidXI { score += 1 }
        if benchCount == 4 { score += 1 }
        if hasBothCaptains { score += 1 }
        if currentBudget >= 0 { score += 1 }
        
        return (score * 100) / maxScore
    }
    
    var isReadyForMatchday: Bool {
        isFull && isValidXI && benchCount == 4 && hasBothCaptains && currentBudget >= 0
    }
    
    var missingRequirements: [String] {
        var missing: [String] = []
        
        if !isFull {
            missing.append("Need \(15 - (players?.count ?? 0)) more player(s)")
        }
        
        if !isValidXI {
            if startingXICount < 11 {
                missing.append("Need to select \(11 - startingXICount) starter(s)")
            } else {
                missing.append("Invalid formation - check position requirements")
            }
        }
        
        if benchCount < 4 {
            missing.append("Need \(4 - benchCount) bench player(s)")
        }
        
        if !hasCaptain {
            missing.append("Assign a captain")
        }
        
        if !hasViceCaptain {
            missing.append("Assign a vice-captain")
        }
        
        if currentBudget < 0 {
            missing.append("Over budget by £\(String(format: "%.1f", abs(currentBudget)))M")
        }
        
        return missing
    }
}

// MARK: - Tournament Stage Enum

enum TournamentStage: String, Codable, CaseIterable {
    case groupStage = "Group Stage"
    case roundOf16 = "Round of 16"
    case quarterFinals = "Quarter-finals"
    case semiFinals = "Semi-finals"
    case thirdPlace = "Third Place Playoff"
    case final = "Final"
    
    var maxPlayersPerNation: Int {
        switch self {
        case .groupStage: return 30
        case .roundOf16: return 4
        case .quarterFinals: return 5
        case .semiFinals, .thirdPlace: return 6
        case .final: return 8
        }
    }
    
    var freeTransfersAllowed: Int {
        switch self {
        case .groupStage: return 1
        case .roundOf16: return 2
        case .quarterFinals: return 2
        case .semiFinals: return 1
        case .thirdPlace, .final: return 0
        }
    }
    
    var matchCount: Int {
        switch self {
        case .groupStage: return 48
        case .roundOf16: return 8
        case .quarterFinals: return 4
        case .semiFinals: return 2
        case .thirdPlace: return 1
        case .final: return 1
        }
    }
}

// MARK: - Matchday Model

@Model
final class Matchday {
    @Attribute(.unique) var number: Int
    var name: String
    var stage: TournamentStage
    var deadline: Date
    var isActive: Bool
    var isFinished: Bool
    
    var groupStageRound: Int?
    
    var hasUnlimitedTransfers: Bool
    var freeTransfersAllowed: Int
    
    @Relationship(deleteRule: .cascade, inverse: \Fixture.matchday)
    var fixtures: [Fixture]?
    
    @Relationship(deleteRule: .cascade, inverse: \MatchdayPerformance.matchday)
    var performances: [MatchdayPerformance]?
    
    init(
        number: Int,
        stage: TournamentStage,
        deadline: Date,
        groupStageRound: Int? = nil,
        hasUnlimitedTransfers: Bool = false,
        freeTransfersAllowed: Int = 1
    ) {
        self.number = number
        self.stage = stage
        self.groupStageRound = groupStageRound
        
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

// MARK: - Matchday Performance

@Model
final class MatchdayPerformance {
    @Attribute(.unique) var id: UUID
    var matchdayNumber: Int
    var points: Int
    
    var didAppear: Bool
    var minutesPlayed: Int
    var played60Plus: Bool
    
    var goalsScored: Int
    var goalsOutsideBox: Int
    var assists: Int
    var ballsRecovered: Int
    
    var cleanSheet: Bool
    var goalsConceded: Int
    var saves: Int
    
    var yellowCards: Int
    var redCards: Int
    var ownGoals: Int
    
    var penaltiesWon: Int
    var penaltiesConceded: Int
    var penaltiesSaved: Int
    var penaltiesMissed: Int
    var playerOfTheMatch: Bool
    
    var wasCaptain: Bool
    var wasViceCaptain: Bool
    var captainBonus: Int
    var captainMultiplier: Int
    
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
    
    func calculatePoints(position: PlayerPosition) -> Int {
        var total = 0
        
        if didAppear { total += 1 }
        if played60Plus { total += 1 }
        
        total += goalsScored * position.pointsForGoal()
        total += goalsOutsideBox
        
        total += assists * 3
        
        total += (ballsRecovered / 3)
        
        if cleanSheet {
            total += position.pointsForCleanSheet(minutesPlayed: minutesPlayed)
        }
        
        if position == .goalkeeper || position == .defender {
            total -= (goalsConceded / 2)
        }
        
        if position == .goalkeeper {
            total += (saves / 3)
        }
        
        total += penaltiesWon * 2
        total -= penaltiesConceded
        total += penaltiesSaved * 5
        total -= penaltiesMissed * 2
        
        total -= yellowCards
        total -= redCards * 3
        total -= ownGoals * 2
        
        if playerOfTheMatch { total += 3 }
        
        self.points = total
        
        if wasCaptain || wasViceCaptain {
            self.captainBonus = total * (captainMultiplier - 1)
            return total * captainMultiplier
        }
        
        return total
    }
}

// MARK: - Matchday Squad (Snapshot)

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

//MARK: - Teamstandings
@Model
final class TeamStandings {
    @Attribute(.unique) var id: UUID
    var nation: Nation
    var group: WorldCupGroup?
    
    // Table stats
    var position: Int
    var played: Int
    var wins: Int
    var draws: Int
    var losses: Int
    var goalsFor: Int
    var goalsAgainst: Int
    var points: Int
    
    var goalDifference: Int {
        goalsFor - goalsAgainst
    }
    
    init(
        nation: Nation,
        group: WorldCupGroup?,
        position: Int,
        played: Int,
        wins: Int,
        draws: Int,
        losses: Int,
        goalsFor: Int,
        goalsAgainst: Int
    ) {
        self.id = UUID()
        self.nation = nation
        self.group = group
        self.position = position
        self.played = played
        self.wins = wins
        self.draws = draws
        self.losses = losses
        self.goalsFor = goalsFor
        self.goalsAgainst = goalsAgainst
        self.points = (wins * 3) + draws
    }
}



// MARK: - Transfer Model

@Model
final class Transfer {
    @Attribute(.unique) var id: UUID
    var matchdayNumber: Int
    var isFreeTransfer: Bool
    var pointsDeducted: Int
    var timestamp: Date
    
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
        isFreeTransfer: Bool
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

// MARK: - Fixture Model

@Model
final class Fixture {
    @Attribute(.unique) var id: Int
    var matchdayNumber: Int
    var homeNation: Nation
    var awayNation: Nation
    var kickoffTime: Date
    var isFinished: Bool
    var homeScore: Int?
    var awayScore: Int?
    var hadExtraTime: Bool
    var hadPenaltyShootout: Bool
    var penaltyWinner: Nation?
    
    var group: WorldCupGroup?
    var venue: String?
    var city: String?
    
    var knockoutStage: TournamentStage?
    var matchLabel: String?
    
    @Relationship(deleteRule: .nullify)
    var matchday: Matchday?
    
    init(
        id: Int,
        matchdayNumber: Int,
        homeNation: Nation,
        awayNation: Nation,
        kickoffTime: Date,
        group: WorldCupGroup? = nil,
        knockoutStage: TournamentStage? = nil,
        venue: String? = nil,
        city: String? = nil
    ) {
        self.id = id
        self.matchdayNumber = matchdayNumber
        self.homeNation = homeNation
        self.awayNation = awayNation
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
            var score = "\(home):\(away)"
            if hadPenaltyShootout, let winner = penaltyWinner {
                score += " (\(winner.rawValue) won on pens)"
            } else if hadExtraTime {
                score += " (a.e.t.)"
            }
            return score
        }
        return "vs"
    }
    
    var homeFlagURL: String {
        homeNation.flagURL
    }
    
    var awayFlagURL: String {
        awayNation.flagURL
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
