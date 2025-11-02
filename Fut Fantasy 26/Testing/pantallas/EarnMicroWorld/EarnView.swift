//
//  EarnViwe.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 02/11/25.
//

import SwiftUI
import SwiftData

struct EarnView: View {
    
    @Query private var squads: [Squad]
    
    var squad: Squad? {
        squads.first
    }
    
    var body: some View {
        ZStack {
            Color(.mainBg)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                  
                    if let squad = squad {
                        Earnheader(squad: squad)
                    }

                    VStack(spacing: 18) {
                        // Card 1 - Blue Ocean
                        EarnCard(
                            question: "How many World Cups have been held in Mexico?",
                            points: 1000,
                            backgroundColor: .wpBlueOcean,
                            accentColor: .wpMint,
                            foregroundIcon: AnyView(IconQuestionmark())
                        )
                        
                        EarnCard(
                            title:"Predictions",
                            question: "Who will win the next match?",
                            points: 8000,
                            backgroundColor: .wpPurpleDeep,
                            accentColor: .wpGreenLime,
                            backgroundIconColor: .wpPurpleLilac,
                            foregroundIcon:   AnyView(
                                Image("Throphy")
                                    .resizable()
                                    .scaledToFit()
                            ),
                            foregroundIconScale: 0.8,
                            foregroundIconRenderingMode: .masked
                        )
                        
                        EarnCard(
                            title:"RECREATE THE POSE",
                            question: "Recreate Mbappé's crossed-arms pose",
                            points: 1000,
                            backgroundColor: .wpRedBright,
                            accentColor: .wpGreenLime,
                            foregroundIcon: AnyView(
                                Image("LaCabra")
                                    .resizable()
                                    .scaledToFit()
                            ),
                            foregroundIconScale: 1.5,
                            foregroundIconRenderingMode: .masked
                        )
                        
                        EarnCard(
                            title:"location",
                            question: "Go paste some stickers on the Estadio Arkon",
                            points: 1500,
                            backgroundColor: .wpGreenMalachite,
                            accentColor: .wpBlueOcean,
                            backgroundIconColor: .wpGreenYellow,
                            foregroundIcon: AnyView(
                                Image("PinPoint")
                                    .resizable()
                                    .scaledToFit()
                                
                            ),
                            foregroundIconScale: 0.76,
                            foregroundIconRenderingMode: .masked
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

private func Earnheader(squad: Squad) -> some View {
    HStack {
        VStack(alignment: .leading, spacing: 4) {
            Text("Earn more Coins")
                .font(.system(size: 28, weight: .regular))
                .fontWidth(.condensed)
                .foregroundStyle(.white)
            Text("Complete challenges!")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white)
                .fontWidth(.condensed)
            
        }
        
        Spacer()
        
        VStack(alignment: .trailing, spacing: 4) {
            Text("Budget")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white)
            
            HStack(spacing: 3) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.white)
                
                Text(squad.displayBudgetNoDecimals)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }
    .padding(.horizontal, 26)
    .padding(.top,12)
}



#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container: ModelContainer
    
    do {
        container = try ModelContainer(
            for: Player.self, Squad.self,
            configurations: config
        )
    } catch {
        fatalError("Failed to create preview container")
    }
    
    let context = container.mainContext
    WorldCupDataSeeder.seedDataIfNeeded(context: context)
    
    let squad = Squad(teamName: "Preview Team", ownerName: "Preview")
    context.insert(squad)
    
    let fetchDescriptor = FetchDescriptor<Player>(
        sortBy: [SortDescriptor(\.totalPoints, order: .reverse)]
    )
    
    if let allPlayers = try? context.fetch(fetchDescriptor) {
        squad.players = Array(allPlayers.prefix(15))
    }
    
    try? context.save()
    
    return EarnView()
        .modelContainer(container)
}
