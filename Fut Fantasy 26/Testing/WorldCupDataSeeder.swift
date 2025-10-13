//
//  WorldCupDataSeeder.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import SwiftData

@MainActor
class WorldCupDataSeeder {
    
    // MARK: - Main Seed Function
    
    static func seedDataIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Player>()
        guard (try? context.fetch(descriptor))?.isEmpty ?? true else {
            return
        }
        
        print("🌱 Seeding initial World Cup data...")
        seedMatchdays(context: context)
        seedPlayers(context: context)
        seedFixtures(context: context)
        
        do {
            try context.save()
            print("✅ Initial data seeding complete.")
        } catch {
            print("❌ Failed to save initial seed data: \(error)")
        }
    }
    
    // MARK: - Helper to Fetch User Squad
    
    private static func fetchUserSquad(context: ModelContext) throws -> Squad? {
        let descriptor = FetchDescriptor<Squad>()
        let squads = try context.fetch(descriptor)
        return squads.first
    }
    
    // MARK: - Squad Seeding (HARDCODED FIX)
    
    @MainActor
    static func seedSquadIfNeeded(
        squadRepository: SquadRepository,
        playerRepository: PlayerRepository,
        context: ModelContext
    ) async {
        print("👥 [Seeder] Checking squad status...")
        
        do {
            let playerCount = try context.fetchCount(FetchDescriptor<Player>())
            guard playerCount > 0 else {
                print("⚠️ [Seeder] No players found in database. Cannot seed squad.")
                return
            }
            
            // ✅ Fetch squad directly from context
            var squad = try fetchUserSquad(context: context)
            
            if let existingSquad = squad, (existingSquad.players?.count ?? 0) == 15 {
                print("✅ Squad is already full with 15 players. No action needed.")
                return
            }
            
            print("⚠️ Squad is incomplete or missing. Creating new squad.")
            
            // Delete old squad if exists
            if let existingSquad = squad {
                context.delete(existingSquad)
                try context.save()
                print("✅ Old squad deleted")
            }
            
            // Create new squad
            squad = try await squadRepository.createSquad(teamName: "My Team")
            print("✅ New empty squad created.")
            
            // --- HARDCODED PLAYER SELECTION ---
            print("👥 [Seeder] Assembling a hardcoded default squad...")
            
            let defaultSquadPlayerIDs: [Int] = [
                1, 12,  // GK
                2, 13, 24, 35, 40,  // DEF
                6, 16, 28, 37, 41,  // MID
                31, 38, 43  // FWD
            ]
            
            let predicate = #Predicate<Player> { defaultSquadPlayerIDs.contains($0.id) }
            let descriptor = FetchDescriptor<Player>(predicate: predicate)
            let playersForSquad = try context.fetch(descriptor)
            
            guard playersForSquad.count == 15 else {
                print("❌ Failed to fetch the 15 hardcoded players. Check IDs. Found \(playersForSquad.count)")
                return
            }
            
            print("✅ Fetched 15 specific players. Adding to squad...")
            for player in playersForSquad {
                try await squadRepository.addPlayerToSquad(playerId: player.id, squadId: squad!.id)
            }
            
            // ✅ Refresh squad from context
            squad = try fetchUserSquad(context: context)
            
            guard let allPlayers = squad?.players else {
                print("❌ Squad players are nil after adding them.")
                return
            }
            
            let sortedPlayers = allPlayers.sorted { $0.id < $1.id }
            
            let gks = sortedPlayers.filter { $0.position == PlayerPosition.goalkeeper }
            let defs = sortedPlayers.filter { $0.position == PlayerPosition.defender }
            let mids = sortedPlayers.filter { $0.position == PlayerPosition.midfielder }
            let fwds = sortedPlayers.filter { $0.position == PlayerPosition.forward }
            
            let startingXI = Array(gks.prefix(1)) + Array(defs.prefix(4)) + Array(mids.prefix(4)) + Array(fwds.prefix(2))
            
            guard startingXI.count == 11 else {
                print("❌ Could not form a starting XI of 11. Players found: GK(\(gks.count)), D(\(defs.count)), M(\(mids.count)), F(\(fwds.count))")
                return
            }
            
            print("✅ [Seeder] Setting starting XI...")
            try await squadRepository.setSquadStartingXI(squadId: squad!.id, startingXI: startingXI.map { $0.id })
            print("✅ [Seeder] Starting XI set")
            
            if let captain = startingXI.first(where: { $0.name == "K. Mbappé" }),
               let viceCaptain = startingXI.first(where: { $0.name == "H. Kane" }) {
                try await squadRepository.setCaptain(playerId: captain.id, squadId: squad!.id)
                try await squadRepository.setViceCaptain(playerId: viceCaptain.id, squadId: squad!.id)
                print("✅ [Seeder] Captain and vice-captain set")
            }
            
            // ✅ Final refresh
            squad = try fetchUserSquad(context: context)
            
            print("\n🎉 [Seeder] Squad setup complete!")
            print("   - Players: \(squad?.players?.count ?? 0)/15")
            print("   - Budget: \(squad?.displayBudget ?? "N/A")\n")
            
        } catch {
            print("❌ [Seeder] ERROR during squad seeding: \(error)")
        }
    }
    
    // MARK: - Matchdays
    
    static func seedMatchdays(context: ModelContext) {
        let matchdays: [(number: Int, stage: TournamentStage, deadline: String, round: Int?, unlimited: Bool, freeTransfers: Int)] = [
            (1, .groupStage, "2026-06-11 15:00", 1, true, 999),
            (2, .groupStage, "2026-06-12 15:00", 1, false, 1),
            (3, .groupStage, "2026-06-16 15:00", 2, false, 1),
            (4, .groupStage, "2026-06-17 15:00", 2, false, 1),
            (5, .groupStage, "2026-06-21 15:00", 3, false, 1),
            (6, .groupStage, "2026-06-22 15:00", 3, false, 1),
            (7, .roundOf16, "2026-06-27 15:00", nil, true, 999),
            (8, .roundOf16, "2026-06-28 15:00", nil, false, 2),
            (9, .quarterFinals, "2026-07-04 15:00", nil, false, 2),
            (10, .semiFinals, "2026-07-08 15:00", nil, false, 1),
            (11, .thirdPlace, "2026-07-12 15:00", nil, false, 0),
            (12, .final, "2026-07-13 15:00", nil, false, 0)
        ]
        
        for md in matchdays {
            let matchday = Matchday(
                number: md.number,
                stage: md.stage,
                deadline: parseDate(md.deadline),
                groupStageRound: md.round,
                hasUnlimitedTransfers: md.unlimited,
                freeTransfersAllowed: md.freeTransfers
            )
            context.insert(matchday)
        }
    }
    
    // MARK: - Players
    
    static func seedPlayers(context: ModelContext) {
        let playerData: [(name: String, firstName: String, lastName: String, pos: PlayerPosition, nation: Nation, shirt: Int, price: Double)] = [
            // Argentina
            ("E. Martínez", "Emiliano", "Martínez", .goalkeeper, .argentina, 23, 5.5),
            ("C. Romero", "Cristian", "Romero", .defender, .argentina, 13, 5.0),
            ("N. Otamendi", "Nicolás", "Otamendi", .defender, .argentina, 19, 4.5),
            ("L. Martínez", "Lisandro", "Martínez", .defender, .argentina, 25, 5.0),
            ("R. De Paul", "Rodrigo", "De Paul", .midfielder, .argentina, 7, 6.0),
            ("E. Fernández", "Enzo", "Fernández", .midfielder, .argentina, 24, 6.5),
            ("A. Mac Allister", "Alexis", "Mac Allister", .midfielder, .argentina, 20, 6.5),
            ("Á. Di María", "Ángel", "Di María", .midfielder, .argentina, 11, 7.5),
            ("L. Messi", "Lionel", "Messi", .forward, .argentina, 10, 11.5),
            ("J. Álvarez", "Julián", "Álvarez", .forward, .argentina, 9, 8.5),
            ("L. Martínez", "Lautaro", "Martínez", .forward, .argentina, 22, 8.0),
            // Brazil
            ("Alisson", "Alisson", "Becker", .goalkeeper, .brazil, 1, 5.5),
            ("Marquinhos", "Marcos", "Aoás Corrêa", .defender, .brazil, 4, 5.5),
            ("Éder Militão", "Éder", "Militão", .defender, .brazil, 3, 5.0),
            ("Danilo", "Danilo", "Luiz", .defender, .brazil, 2, 4.5),
            ("Casemiro", "Carlos", "Casemiro", .midfielder, .brazil, 5, 6.5),
            ("Lucas Paquetá", "Lucas", "Paquetá", .midfielder, .brazil, 8, 6.0),
            ("Bruno Guimarães", "Bruno", "Guimarães", .midfielder, .brazil, 18, 6.0),
            ("Raphinha", "Raphael", "Dias Belloli", .midfielder, .brazil, 11, 7.0),
            ("Vinícius Jr.", "Vinícius", "Júnior", .forward, .brazil, 7, 10.5),
            ("Neymar Jr.", "Neymar", "da Silva Santos", .forward, .brazil, 10, 11.0),
            ("Richarlison", "Richarlison", "de Andrade", .forward, .brazil, 9, 8.0),
            // England
            ("J. Pickford", "Jordan", "Pickford", .goalkeeper, .england, 1, 5.0),
            ("K. Walker", "Kyle", "Walker", .defender, .england, 2, 5.5),
            ("J. Stones", "John", "Stones", .defender, .england, 5, 5.5),
            ("H. Maguire", "Harry", "Maguire", .defender, .england, 6, 4.5),
            ("D. Rice", "Declan", "Rice", .midfielder, .england, 4, 6.5),
            ("J. Bellingham", "Jude", "Bellingham", .midfielder, .england, 22, 8.5),
            ("P. Foden", "Phil", "Foden", .midfielder, .england, 11, 8.0),
            ("B. Saka", "Bukayo", "Saka", .midfielder, .england, 7, 8.0),
            ("H. Kane", "Harry", "Kane", .forward, .england, 9, 11.0),
            ("R. Sterling", "Raheem", "Sterling", .forward, .england, 10, 7.5),
            ("M. Rashford", "Marcus", "Rashford", .forward, .england, 19, 7.5),
            // France
            ("M. Maignan", "Mike", "Maignan", .goalkeeper, .france, 16, 5.0),
            ("T. Hernández", "Theo", "Hernández", .defender, .france, 22, 5.5),
            ("A. Tchouaméni", "Aurélien", "Tchouaméni", .midfielder, .france, 8, 7.0),
            ("A. Griezmann", "Antoine", "Griezmann", .midfielder, .france, 7, 9.0),
            ("K. Mbappé", "Kylian", "Mbappé", .forward, .france, 10, 12.0),
            // Germany
            ("M. Neuer", "Manuel", "Neuer", .goalkeeper, .germany, 1, 5.0),
            ("A. Rüdiger", "Antonio", "Rüdiger", .defender, .germany, 2, 5.0),
            ("J. Kimmich", "Joshua", "Kimmich", .midfielder, .germany, 6, 7.5),
            ("İ. Gündoğan", "İlkay", "Gündoğan", .midfielder, .germany, 21, 7.0),
            ("K. Havertz", "Kai", "Havertz", .forward, .germany, 7, 8.0),
        ]
        
        var playerId = 1
        for player in playerData {
            let newPlayer = Player(
                id: playerId,
                name: player.name,
                firstName: player.firstName,
                lastName: player.lastName,
                position: player.pos,
                nation: player.nation,
                shirtNumber: player.shirt,
                price: player.price,
                group: player.nation.group
            )
            context.insert(newPlayer)
            playerId += 1
        }
    }
    
    // MARK: - Fixtures
    
    static func seedFixtures(context: ModelContext) {
        let fixtures: [(id: Int, md: Int, home: Nation, away: Nation, kickoff: String, group: WorldCupGroup?, stage: TournamentStage?)] = [
            (1, 1, .qatar, .ecuador, "2026-06-11 16:00", .a, nil),
            (2, 1, .senegal, .netherlands, "2026-06-11 19:00", .a, nil),
            (3, 2, .england, .iran, "2026-06-12 13:00", .b, nil),
            (4, 2, .usa, .wales, "2026-06-12 19:00", .b, nil),
        ]
        
        for fixture in fixtures {
            let newFixture = Fixture(
                id: fixture.id,
                matchdayNumber: fixture.md,
                homeNation: fixture.home,
                awayNation: fixture.away,
                kickoffTime: parseDate(fixture.kickoff),
                group: fixture.group,
                knockoutStage: fixture.stage,
                venue: nil,
                city: nil
            )
            context.insert(newFixture)
        }
    }
    
    // MARK: - Helper
    
    static func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: dateString) ?? Date()
    }
}
