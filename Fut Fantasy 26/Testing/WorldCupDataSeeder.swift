//
//  WorldCupDataSeeder.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 12/10/25.
//


import Foundation
import SwiftData



import Foundation
import SwiftData

@MainActor
class WorldCupDataSeeder {
    
    // MARK: - Main Seed Function
    
    static func seedDataIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Player>()
        let existingPlayers = try? context.fetch(descriptor)
        
        if existingPlayers?.isEmpty == false {
            print("✅ Data already seeded")
            return
        }
        
        print("🌱 Seeding World Cup data...")
        
        seedMatchdays(context: context)
        seedPlayers(context: context)
        seedFixtures(context: context)
        
        do {
            try context.save()
            print("✅ Initial seeding complete, saved to database")
        } catch {
            print("❌ Failed to save initial seed data: \(error)")
        }
        
        print("✅ Seeding complete!")
    }
    
    // MARK: - Squad Seeding
    
    static func seedSquadIfNeeded(
        squadRepository: SquadRepository,
        context: ModelContext
    ) async {
        print("👥 [Seeder] Checking if squad needs seeding...")
        
        do {
            let squad = try await squadRepository.fetchUserSquad()
            
            if (squad.players?.count ?? 0) > 0 {
                print("✅ Squad already has \(squad.players?.count ?? 0) players")
                return
            }
            
            print("👥 [Seeder] Squad is empty, starting to add 15 players...")
            
            let playerDescriptor = FetchDescriptor<Player>(
                sortBy: [SortDescriptor(\.id)]
            )
            let allPlayers = try context.fetch(playerDescriptor)
            
            guard !allPlayers.isEmpty else {
                print("❌ No players found in database to add to squad")
                return
            }
            
            print("👥 [Seeder] Found \(allPlayers.count) total players in database")
            
            let goalkeepers = Array(allPlayers.filter { $0.position == .goalkeeper }.prefix(2))
            let defenders = Array(allPlayers.filter { $0.position == .defender }.prefix(5))
            let midfielders = Array(allPlayers.filter { $0.position == .midfielder }.prefix(5))
            let forwards = Array(allPlayers.filter { $0.position == .forward }.prefix(3))
            
            let selectedPlayers = goalkeepers + defenders + midfielders + forwards
            
            print("👥 [Seeder] Selected \(selectedPlayers.count) players:")
            print("   - Goalkeepers: \(goalkeepers.count)")
            print("   - Defenders: \(defenders.count)")
            print("   - Midfielders: \(midfielders.count)")
            print("   - Forwards: \(forwards.count)")
            
            guard selectedPlayers.count == 15 else {
                print("❌ Not enough players to form a full squad (need 15, got \(selectedPlayers.count))")
                return
            }
            
            var addedCount = 0
            for player in selectedPlayers {
                do {
                    try await squadRepository.addPlayerToSquad(playerId: player.id, squadId: squad.id)
                    addedCount += 1
                    print("   ✅ [\(addedCount)/15] Added: \(player.name) (\(player.position.rawValue)) - £\(String(format: "%.1f", player.price))M")
                } catch {
                    print("   ❌ Failed to add \(player.name): \(error.localizedDescription)")
                }
            }
            
            print("👥 [Seeder] Successfully added \(addedCount)/15 players to squad")
            
            if addedCount >= 11 {
                print("👥 [Seeder] Setting up starting XI in 4-3-3 formation...")
                
                let startingGK = Array(goalkeepers.prefix(1))
                let startingDEF = Array(defenders.prefix(4))
                let startingMID = Array(midfielders.prefix(3))
                let startingFWD = Array(forwards.prefix(3))
                
                let startingXI = startingGK + startingDEF + startingMID + startingFWD
                
                guard startingXI.count == 11 else {
                    print("❌ Cannot form starting XI, need 11 players but have \(startingXI.count)")
                    return
                }
                
                let startingXIIds = startingXI.map { $0.id }
                
                try await squadRepository.setSquadStartingXI(squadId: squad.id, startingXI: startingXIIds)
                print("✅ [Seeder] Set starting XI (4-3-3 formation)")
                
                if startingXI.count >= 2 {
                    let captain = startingXI[0]
                    let viceCaptain = startingXI[1]
                    
                    try await squadRepository.setCaptain(
                        squadId: squad.id,
                        captainId: captain.id,
                        viceCaptainId: viceCaptain.id
                    )
                    print("✅ [Seeder] Set captain: \(captain.name), vice-captain: \(viceCaptain.name)")
                }
            }
            
            let finalSquad = try await squadRepository.fetchUserSquad()
            print("")
            print("🎉 [Seeder] Squad Setup Complete!")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print("   Squad Name: \(finalSquad.teamName)")
            print("   Total Players: \(finalSquad.players?.count ?? 0)/15")
            print("   Starting XI: \(finalSquad.startingXI?.count ?? 0)/11")
            print("   Bench: \(finalSquad.bench?.count ?? 0)/4")
            print("   Budget Remaining: \(finalSquad.displayBudget)")
            print("   Team Value: \(finalSquad.displayTotalValue)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
        } catch {
            print("❌ [Seeder] Failed to seed squad: \(error)")
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
        
        print("✅ Seeded \(matchdays.count) matchdays")
    }
    
    // MARK: - Players
    
    static func seedPlayers(context: ModelContext) {
        let playerData: [(name: String, firstName: String, lastName: String, pos: PlayerPosition, nation: Nation, shirt: Int, price: Double)] = [
            // 🇦🇷 ARGENTINA
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
            
            // 🇧🇷 BRAZIL
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
            
            // 🏴󠁧󠁢󠁥󠁮󠁧󠁿 ENGLAND
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
            
            // 🇫🇷 FRANCE
            ("H. Lloris", "Hugo", "Lloris", .goalkeeper, .france, 1, 5.0),
            ("R. Varane", "Raphaël", "Varane", .defender, .france, 4, 5.5),
            ("W. Saliba", "William", "Saliba", .defender, .france, 17, 5.0),
            ("T. Hernández", "Theo", "Hernández", .defender, .france, 22, 5.5),
            ("A. Tchouaméni", "Aurélien", "Tchouaméni", .midfielder, .france, 8, 6.0),
            ("A. Griezmann", "Antoine", "Griezmann", .midfielder, .france, 7, 8.5),
            ("O. Dembélé", "Ousmane", "Dembélé", .midfielder, .france, 11, 7.5),
            ("K. Mbappé", "Kylian", "Mbappé", .forward, .france, 10, 12.0),
            ("M. Thuram", "Marcus", "Thuram", .forward, .france, 15, 7.0),
            ("R. Kolo Muani", "Randal", "Kolo Muani", .forward, .france, 12, 7.0),
            
            // 🇩🇪 GERMANY
            ("M. ter Stegen", "Marc-André", "ter Stegen", .goalkeeper, .germany, 1, 5.0),
            ("A. Rüdiger", "Antonio", "Rüdiger", .defender, .germany, 2, 5.0),
            ("N. Süle", "Niklas", "Süle", .defender, .germany, 15, 4.5),
            ("J. Kimmich", "Joshua", "Kimmich", .midfielder, .germany, 6, 7.0),
            ("İ. Gündoğan", "İlkay", "Gündoğan", .midfielder, .germany, 21, 6.5),
            ("J. Musiala", "Jamal", "Musiala", .midfielder, .germany, 14, 8.0),
            ("L. Sané", "Leroy", "Sané", .midfielder, .germany, 19, 7.5),
            ("K. Havertz", "Kai", "Havertz", .forward, .germany, 7, 8.0),
            ("S. Gnabry", "Serge", "Gnabry", .forward, .germany, 8, 7.0),
            
            // 🇪🇸 SPAIN
            ("Unai Simón", "Unai", "Simón", .goalkeeper, .spain, 23, 5.0),
            ("Dani Carvajal", "Daniel", "Carvajal", .defender, .spain, 2, 5.0),
            ("Aymeric Laporte", "Aymeric", "Laporte", .defender, .spain, 14, 5.0),
            ("Rodri", "Rodrigo", "Hernández", .midfielder, .spain, 16, 7.0),
            ("Pedri", "Pedro", "González", .midfielder, .spain, 8, 7.5),
            ("Gavi", "Pablo", "Páez Gavira", .midfielder, .spain, 9, 7.0),
            ("Álvaro Morata", "Álvaro", "Morata", .forward, .spain, 7, 7.5),
            ("Ferran Torres", "Ferran", "Torres", .forward, .spain, 11, 7.0),
            
            // 🇵🇹 PORTUGAL
            ("Diogo Costa", "Diogo", "Costa", .goalkeeper, .portugal, 22, 5.0),
            ("Rúben Dias", "Rúben", "Dias", .defender, .portugal, 4, 5.5),
            ("João Cancelo", "João", "Cancelo", .defender, .portugal, 20, 5.5),
            ("Bruno Fernandes", "Bruno", "Fernandes", .midfielder, .portugal, 8, 8.0),
            ("Bernardo Silva", "Bernardo", "Silva", .midfielder, .portugal, 10, 8.5),
            ("C. Ronaldo", "Cristiano", "Ronaldo", .forward, .portugal, 7, 10.0),
            ("João Félix", "João", "Félix", .forward, .portugal, 11, 7.5),
            
            // 🇧🇪 BELGIUM
            ("T. Courtois", "Thibaut", "Courtois", .goalkeeper, .belgium, 1, 5.5),
            ("K. De Bruyne", "Kevin", "De Bruyne", .midfielder, .belgium, 7, 10.0),
            ("R. Lukaku", "Romelu", "Lukaku", .forward, .belgium, 9, 8.5),
            
            // 🇳🇱 NETHERLANDS
            ("A. Noppert", "Andries", "Noppert", .goalkeeper, .netherlands, 23, 4.5),
            ("V. van Dijk", "Virgil", "van Dijk", .defender, .netherlands, 4, 5.5),
            ("F. de Jong", "Frenkie", "de Jong", .midfielder, .netherlands, 21, 7.0),
            ("C. Gakpo", "Cody", "Gakpo", .forward, .netherlands, 8, 8.0),
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
        
        print("✅ Seeded \(playerData.count) players")
    }
    
    // MARK: - Fixtures
    
    static func seedFixtures(context: ModelContext) {
        let fixtures: [(id: Int, md: Int, home: Nation, away: Nation, kickoff: String, group: WorldCupGroup?, stage: TournamentStage?)] = [
            (1, 1, .qatar, .ecuador, "2026-06-11 16:00", .a, nil),
            (2, 1, .senegal, .netherlands, "2026-06-11 19:00", .a, nil),
            (3, 2, .england, .iran, "2026-06-12 13:00", .b, nil),
            (4, 2, .usa, .wales, "2026-06-12 19:00", .b, nil),
            (5, 2, .argentina, .saudiArabia, "2026-06-12 10:00", .c, nil),
            (6, 2, .mexico, .poland, "2026-06-12 16:00", .c, nil),
            (7, 2, .france, .australia, "2026-06-13 19:00", .d, nil),
            (8, 2, .denmark, .tunisia, "2026-06-13 13:00", .d, nil),
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
        
        print("✅ Seeded \(fixtures.count) fixtures")
    }
    
    // MARK: - Helper
    
    static func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: dateString) ?? Date()
    }
}
