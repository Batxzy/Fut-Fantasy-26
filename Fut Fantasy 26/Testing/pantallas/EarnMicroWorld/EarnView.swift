//
//  EarnViwe.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 02/11/25.
//

import SwiftUI

struct EarnView: View {
    var body: some View {
        ZStack {
            Color(.mainBg)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    Earnheader(squad: <#T##Squad#>)
                    
                    // Question Cards
                    VStack(spacing: 18) {
                        // Card 1 - Blue Ocean
                        EarnCard(
                            question: "How many World Cups have been held in Mexico?",
                            points: 1000,
                            backgroundColor: .wpBlueOcean,
                            accentColor: .wpMint,
                            foregroundIcon: AnyView(IconQuestionmark())
                        )
                        
                        // Card 2 - Purple
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
                        
                        // Card 3 - Green
                        EarnCard(
                            
                            title:"RECREATE THE POSE",
                            question: "Who scored the fastest goal in World Cup history?",
                            points: 750,
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
                        
                        // Card 4 - Red/Orange
                        EarnCard(
                            title:"location",
                            question: "What year was the first World Cup held?",
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
            Text("Players")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white)
            Text("\(squad.players?.count ?? 0)/15")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
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
    .padding(.horizontal, 24)
    .padding(.bottom, 2)
    .padding(.top,12)
}



#Preview {
    EarnView()
}
