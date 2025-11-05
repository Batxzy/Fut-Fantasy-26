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
    @Query private var predictions: [Prediction]
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTeam: String = ""
    
    var existingPrediction: Prediction? {
        predictions.first { $0.fixtureId == fixture.id }
    }
    
    var body: some View {
        let teams = [fixture.homeNation.rawValue, fixture.awayNation.rawValue, "Tie"]
        
        VStack(spacing: 0) {
            Text("Make your predictions")
                .font(.system(size: 16, weight: .medium))
                .fontWidth(.compressed)
                .foregroundColor(.white)
                .kerning(1.4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .background(Color.wpBlueOcean)
            
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
                        .kerning(1)
                    
                    Menu {
                        ForEach(teams, id: \.self) { team in
                            Button(team) {
                                selectedTeam = team
                                savePrediction(team)
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedTeam.isEmpty ? "Select" : selectedTeam)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.black)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.black)
                        }
                        .padding(.horizontal, 7)
                        .frame(width: 102, height: 26, alignment: .trailing)
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
        .onAppear {
            if let saved = existingPrediction {
                selectedTeam = saved.selectedResult
            }
        }
    }
    
    private func savePrediction(_ result: String) {
        let fixtureId = fixture.id
        print("🔍 Saving prediction for fixture \(fixtureId): \(result)")
        print("🔍 Existing prediction: \(existingPrediction != nil)")
        
        if let existing = existingPrediction {
            print("✏️ Updating existing prediction")
            existing.selectedResult = result
            existing.submittedAt = Date()
        } else {
            print("➕ Creating new prediction")
            let prediction = Prediction(fixtureId: fixtureId, selectedResult: result)
            modelContext.insert(prediction)
            print("➕ Inserted into context: \(modelContext.insertedModelsArray.contains(where: { $0 is Prediction }))")
        }
        
        do {
            try modelContext.save()
            print("✅ Save successful")
            
            // Force refresh the context
            modelContext.processPendingChanges()
            
            // Query all predictions
            let allDescriptor = FetchDescriptor<Prediction>()
            let allPredictions = try? modelContext.fetch(allDescriptor)
            print("📊 Total predictions in database: \(allPredictions?.count ?? 0)")
            
            // Query for this specific fixture
            let descriptor = FetchDescriptor<Prediction>(predicate: #Predicate { $0.fixtureId == fixtureId })
            let saved = try? modelContext.fetch(descriptor)
            print("📊 Predictions for fixture \(fixtureId): \(saved?.count ?? 0)")
            if let saved = saved {
                for pred in saved {
                    print("   - Result: \(pred.selectedResult), At: \(pred.submittedAt)")
                }
            }
        } catch {
            print("❌ Save failed: \(error)")
        }
    }
}

    #Preview {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(
            for: Player.self, Squad.self, Fixture.self, Prediction.self,  // Added Prediction.self
            configurations: config
        )
        
        let context = container.mainContext
        WorldCupDataSeeder.seedDataIfNeeded(context: context)
        WorldCupDataSeeder.seedFixtures(context: context)
        
        let squad = Squad(teamName: "Preview Team", ownerName: "Preview")
        context.insert(squad)
        
        let fetchDescriptor = FetchDescriptor<Player>(
            sortBy: [SortDescriptor(\.totalPoints, order: .reverse)]
        )
        
        if let allPlayers = try? context.fetch(fetchDescriptor) {
            squad.players = Array(allPlayers.prefix(15))
        }
        
        try? context.save()
        
        return
            MatchPredictionView().modelContainer(container)
    }
