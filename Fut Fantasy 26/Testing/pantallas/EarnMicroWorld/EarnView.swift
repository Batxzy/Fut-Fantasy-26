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
                    Text("Earn")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                    
                    // Question Cards
                    VStack(spacing: 12) {
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
                            points: 500,
                            backgroundColor: .wpPurpleDeep,
                            accentColor: .wpGreenLime,
                            backgroundIconColor: .wpMint,
                            foregroundIcon: AnyView(IconTrophy()),
                            foregroundIconScale: 0.65
                        )
                        
                        // Card 3 - Green
                        EarnCard(
                            question: "Who scored the fastest goal in World Cup history?",
                            points: 750,
                            backgroundColor: .wpGreenMalachite,
                            accentColor: .wpMint,
                            backgroundIconColor: .wpRedBright,
                            foregroundIcon: AnyView(IconBall()),
                            foregroundIconScale: 0.7
                        )
                        
                        // Card 4 - Red/Orange
                        EarnCard(
                            question: "What year was the first World Cup held?",
                            points: 1500,
                            backgroundColor: .wpRedBright,
                            accentColor: .white,
                            backgroundIconColor: .wpGreenLime,
                            foregroundIcon: AnyView(IconCalendar()),
                            foregroundIconScale: 0.68
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

// MARK: - Placeholder Icon Structs


struct IconTrophy: View {
    var body: some View {
        // TODO: Add trophy icon shape
        Image(systemName: "trophy.fill")
            .font(.system(size: 40))
    }
}

struct IconBall: View {
    var body: some View {
        // TODO: Add ball icon shape
        Image(systemName: "soccerball")
            .font(.system(size: 40))
    }
}

struct IconCalendar: View {
    var body: some View {
        // TODO: Add calendar icon shape
        Image(systemName: "calendar")
            .font(.system(size: 40))
    }
}



#Preview {
    EarnView()
}
