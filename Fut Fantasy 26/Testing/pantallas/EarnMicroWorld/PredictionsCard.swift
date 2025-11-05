//
//  PredictionsCard.swift
//  Fut Fantasy 26
//
//  Created by Jose julian Lopez on 04/11/25.
//

import SwiftUI
import SwiftData

struct PredictionsCard: View {
    let fixture: Fixture
    @State private var selectedTeam: String = ""
    
    var body: some View {
        let teams = [fixture.homeNation.rawValue, fixture.awayNation.rawValue]
        
        VStack(spacing: 0) {
            Text("Make your predictions")
                .font(.system(size: 16, weight: .medium))
                .fontWidth(.compressed)
                .foregroundColor(.white)
                .kerning(1.4)
                .frame(maxWidth: .infinity, maxHeight: 36, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 3)
                .background(Color.wpBlue)
            
            HStack(spacing: 19) {
                
                //stack donde se pone el fixture
                HStack(alignment:.center ,spacing: 10) {
    
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
                                Font.system(size: 12)
                                    .weight(.medium)
                            )
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.80)
                            
                    }
                    .frame(width: 60)
                    
                    Text("vs")
                        .fontWidth(.compressed)
                        .kerning(1)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.wpMint)
                    
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
                                Font.system(size: 12)
                                    .weight(.medium)
                            )
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.80)
                    }
                    .frame(width: 60)
                }
                
                
                //linea
                Rectangle()
                    .frame(maxWidth: 2, maxHeight: .infinity)
                    .foregroundStyle(.wpMint)
                
                //picker
                VStack(alignment: .center, spacing: 26) {
                    Text("Who will win?")
                        .fontWidth(.compressed)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    Menu {
                        ForEach(teams, id: \.self) { team in
                            Button(team) {
                                selectedTeam = team
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedTeam.isEmpty ? teams[0] : selectedTeam)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.black)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 7)
                        .frame(width: 102, height: 26,alignment: .trailing)
                        .background(Color.wpMint)
                        .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 19)
            .frame(height: 110)
            .frame(width: 350)
            .background(Color.bgBlue)
        }
        .frame(width: 350)
        .cornerRadius(12)
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Fixture.self,
        configurations: config
    )
    
    let context = container.mainContext
    WorldCupDataSeeder.seedFixtures(context: context)
    
    let fixtures = try! context.fetch(FetchDescriptor<Fixture>())
    
    return PredictionsCard(fixture: fixtures[0])
        .modelContainer(container)
}
